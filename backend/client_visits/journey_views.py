import uuid
from datetime import timedelta, timezone as datetime_timezone
from decimal import Decimal, InvalidOperation

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.db import IntegrityError, transaction
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework.authentication import SessionAuthentication
from rest_framework.decorators import (
    api_view, authentication_classes, permission_classes, throttle_classes,
)
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.authentication import JWTAuthentication

from hrms.models import AuditLog, User
from .journey_permissions import MANAGEMENT_ROLES, can_view_journey
from .journey_serializers import (
    JourneyCreateSerializer, JourneyPointSerializer, JourneySerializer,
    JourneyStopSerializer,
)
from .journey_services import haversine_metres, recalculate_journey_summary
from .models import ClientVisitJourney, JourneyLocationPoint


AUTHENTICATION = [JWTAuthentication, SessionAuthentication]


class JourneyLocationThrottle(ScopedRateThrottle):
    scope = 'journey_location'


def _queryset():
    return ClientVisitJourney.objects.select_related(
        'employee', 'assigned_team_lead', 'source_visit',
    ).annotate(
        point_count=Count('location_points', distinct=True),
        low_accuracy_point_count=Count(
            'location_points', filter=Q(location_points__is_low_accuracy=True), distinct=True,
        ),
        stop_count=Count('stops', distinct=True),
    ).order_by('-scheduled_at', '-id')


def _visible_to(user):
    qs = _queryset()
    if user.role in MANAGEMENT_ROLES:
        return qs
    return qs.filter(Q(employee=user) | Q(assigned_team_lead=user))


def _audit(request, action, journey, before=None, after=None):
    forwarded = request.META.get('HTTP_X_FORWARDED_FOR', '')
    AuditLog.objects.create(
        actor_user_id=request.user.user_id,
        actor_role=request.user.role,
        action=action,
        module='client_journey',
        reference_id=str(journey.pk),
        before=before or {},
        after=after or {},
        ip_address=(forwarded.split(',')[0].strip() or request.META.get('REMOTE_ADDR')),
        user_agent=request.META.get('HTTP_USER_AGENT', ''),
    )


def _journey_or_404(request, pk):
    journey = get_object_or_404(_queryset(), pk=pk)
    if not can_view_journey(request.user, journey):
        return None, Response({'detail': 'You are not authorized for this journey.'}, status=403)
    return journey, None


@api_view(['GET', 'POST'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_list_create(request):
    if request.method == 'GET':
        paginator = PageNumberPagination()
        paginator.page_size = min(int(request.query_params.get('page_size', 20)), 100)
        page = paginator.paginate_queryset(_visible_to(request.user), request)
        return paginator.get_paginated_response(JourneySerializer(page, many=True).data)
    serializer = JourneyCreateSerializer(data=request.data, context={'request': request})
    serializer.is_valid(raise_exception=True)
    journey = serializer.save()
    _audit(request, 'created', journey, after={'status': journey.status})
    return Response(JourneySerializer(journey).data, status=201)


@api_view(['GET'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_assignees(request):
    users = User.objects.filter(
        is_active=True,
        role__in=['tl', 'manager'],
    ).order_by('first_name', 'last_name', 'user_id')
    return Response({
        'results': [
            {
                'user_id': user.user_id,
                'name': f'{user.first_name} {user.last_name}'.strip() or user.email,
                'role': user.role,
            }
            for user in users
        ],
    })


@api_view(['GET'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_detail(request, pk):
    journey, error = _journey_or_404(request, pk)
    if error:
        return error
    if journey.employee_id != request.user.id:
        _audit(request, 'authorized_view', journey)
    return Response(JourneySerializer(journey).data)


def _transition(request, pk, target, allowed_actor='employee'):
    with transaction.atomic():
        journey = get_object_or_404(
            ClientVisitJourney.objects.select_for_update().select_related(
                'employee', 'assigned_team_lead',
            ),
            pk=pk,
        )
        if allowed_actor == 'employee' and journey.employee_id != request.user.id:
            return Response({'detail': 'Only the assigned employee can perform this action.'}, status=403)
        if not journey.can_transition_to(target):
            return Response(
                {'detail': f'Invalid journey transition: {journey.status} to {target}.'},
                status=409,
            )
        before = journey.status
        now = timezone.now()
        journey.status = target
        fields = ['status', 'updated_at']
        if target == ClientVisitJourney.Status.IN_PROGRESS and journey.started_at is None:
            journey.started_at = now
            fields.append('started_at')
        elif target == ClientVisitJourney.Status.COMPLETED:
            journey.completed_at = now
            fields.append('completed_at')
        elif target == ClientVisitJourney.Status.CANCELLED:
            reason = str(request.data.get('reason') or '').strip()
            if not reason:
                return Response({'detail': 'A cancellation reason is required.'}, status=400)
            journey.cancelled_at = now
            journey.cancel_reason = reason
            fields.extend(['cancelled_at', 'cancel_reason'])
        try:
            journey.save(update_fields=fields)
        except IntegrityError:
            return Response({'detail': 'The employee already has an active journey.'}, status=409)
        if target in {ClientVisitJourney.Status.COMPLETED, ClientVisitJourney.Status.CANCELLED}:
            recalculate_journey_summary(journey)
        _audit(request, target.lower(), journey, before={'status': before}, after={'status': target})
    return Response(JourneySerializer(_queryset().get(pk=journey.pk)).data)


@api_view(['POST'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_ready(request, pk):
    return _transition(request, pk, ClientVisitJourney.Status.READY)


@api_view(['POST'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_start(request, pk):
    return _transition(request, pk, ClientVisitJourney.Status.IN_PROGRESS)


@api_view(['POST'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_complete(request, pk):
    return _transition(request, pk, ClientVisitJourney.Status.COMPLETED)


@api_view(['POST'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_cancel(request, pk):
    return _transition(request, pk, ClientVisitJourney.Status.CANCELLED)


def _decimal(value, minimum=None, maximum=None):
    try:
        parsed = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError('invalid_number')
    if not parsed.is_finite() or (minimum is not None and parsed < minimum) or (maximum is not None and parsed > maximum):
        raise ValueError('invalid_coordinate')
    return parsed


def _point_values(raw, journey, now, previous):
    client_id = uuid.UUID(str(raw.get('client_generated_id')))
    latitude = _decimal(raw.get('latitude'), Decimal('-90'), Decimal('90'))
    longitude = _decimal(raw.get('longitude'), Decimal('-180'), Decimal('180'))
    accuracy = _decimal(raw.get('accuracy_metres'), Decimal('0'))
    captured = parse_datetime(str(raw.get('captured_at') or ''))
    if captured is None or timezone.is_naive(captured):
        raise ValueError('invalid_timestamp')
    captured = captured.astimezone(datetime_timezone.utc)
    if captured > now + timedelta(minutes=5):
        raise ValueError('future_timestamp')
    sequence = int(raw.get('sequence_number'))
    if sequence < 0:
        raise ValueError('invalid_sequence_number')

    suspicious = False
    suspicion = ''
    if previous and captured > previous.captured_at:
        distance = haversine_metres(previous.latitude, previous.longitude, latitude, longitude)
        speed = distance / (captured - previous.captured_at).total_seconds()
        if speed > settings.CLIENT_JOURNEY_MAX_SPEED_MPS:
            suspicious = True
            suspicion = f'impossible_speed:{speed:.1f}mps'
    return {
        'client_generated_id': client_id,
        'journey': journey,
        'employee': journey.employee,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_metres': accuracy,
        'altitude': _decimal(raw['altitude']) if raw.get('altitude') is not None else None,
        'speed_metres_per_second': _decimal(raw['speed_metres_per_second'], Decimal('0')) if raw.get('speed_metres_per_second') is not None else None,
        'heading': _decimal(raw['heading'], Decimal('0'), Decimal('360')) if raw.get('heading') is not None else None,
        'captured_at': captured,
        'received_at': now,
        'sequence_number': sequence,
        'is_mocked': raw.get('is_mocked') if isinstance(raw.get('is_mocked'), bool) else None,
        'battery_percentage': _decimal(raw['battery_percentage'], Decimal('0'), Decimal('100')) if raw.get('battery_percentage') is not None else None,
        'is_low_accuracy': accuracy > Decimal(str(settings.CLIENT_JOURNEY_LOW_ACCURACY_METRES)),
        'is_suspicious': suspicious,
        'suspicion_reason': suspicion,
    }


def _broadcast(journey_id, point_id):
    point = JourneyLocationPoint.objects.get(pk=point_id)
    payload = JourneyPointSerializer(point).data
    payload.update({
        'type': 'location_update',
        'journey_id': journey_id,
        'employee_id': point.employee.user_id,
    })
    async_to_sync(get_channel_layer().group_send)(
        f'client_journey_{journey_id}',
        {'type': 'location_update', 'payload': payload},
    )


@api_view(['POST'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
@throttle_classes([JourneyLocationThrottle])
def journey_locations_batch(request, pk):
    points = request.data.get('points')
    if not isinstance(points, list):
        return Response({'detail': 'points must be a list.'}, status=400)
    if not points or len(points) > settings.CLIENT_JOURNEY_MAX_BATCH_SIZE:
        return Response({'detail': f'Batch must contain 1-{settings.CLIENT_JOURNEY_MAX_BATCH_SIZE} points.'}, status=400)

    accepted, duplicates, rejected = [], [], []
    newest = None
    with transaction.atomic():
        journey = get_object_or_404(
            ClientVisitJourney.objects.select_for_update().select_related('employee'), pk=pk,
        )
        if journey.employee_id != request.user.id:
            return Response({'detail': 'Only the assigned employee can upload locations.'}, status=403)
        if journey.status != ClientVisitJourney.Status.IN_PROGRESS:
            return Response({'detail': 'Locations are accepted only for an active journey.'}, status=409)
        ids = []
        for item in points:
            try:
                ids.append(uuid.UUID(str(item.get('client_generated_id') or '')))
            except (ValueError, TypeError, AttributeError):
                continue
        existing = {
            str(value) for value in JourneyLocationPoint.objects.filter(
                client_generated_id__in=ids,
            ).values_list('client_generated_id', flat=True)
        }
        previous = journey.location_points.order_by('-captured_at', '-sequence_number').first()
        for raw in points:
            raw_id = str(raw.get('client_generated_id') or '')
            if raw_id in existing:
                duplicates.append(raw_id)
                continue
            try:
                values = _point_values(raw, journey, timezone.now(), previous)
                # A savepoint keeps a single unique-constraint race from
                # poisoning the surrounding all-or-nothing journey lock.
                with transaction.atomic():
                    point = JourneyLocationPoint.objects.create(**values)
            except IntegrityError:
                rejected.append({'client_generated_id': raw_id, 'reason': 'duplicate_sequence_number'})
                continue
            except (ValueError, TypeError, OverflowError) as exc:
                rejected.append({'client_generated_id': raw_id, 'reason': str(exc) or 'invalid_point'})
                continue
            accepted.append(raw_id)
            existing.add(raw_id)
            previous = point if previous is None or point.captured_at >= previous.captured_at else previous
            if newest is None or (point.captured_at, point.sequence_number) > (newest.captured_at, newest.sequence_number):
                newest = point
        if newest:
            journey.last_location_at = newest.captured_at
            if journey.start_latitude is None:
                journey.start_latitude = newest.latitude
                journey.start_longitude = newest.longitude
            journey.save(update_fields=['last_location_at', 'start_latitude', 'start_longitude', 'updated_at'])
            transaction.on_commit(lambda: _broadcast(journey.pk, newest.pk))
    return Response({'accepted': accepted, 'duplicates': duplicates, 'rejected': rejected})


@api_view(['GET'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_latest_location(request, pk):
    journey, error = _journey_or_404(request, pk)
    if error:
        return error
    point = journey.location_points.order_by('-captured_at', '-sequence_number').first()
    if point is None:
        return Response({'location': None, 'online': False})
    online = point.received_at >= timezone.now() - timedelta(seconds=settings.CLIENT_JOURNEY_GAP_SECONDS)
    return Response({'location': JourneyPointSerializer(point).data, 'online': online})


@api_view(['GET'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def journey_route(request, pk):
    journey, error = _journey_or_404(request, pk)
    if error:
        return error
    points = list(journey.location_points.order_by('captured_at', 'sequence_number'))
    payload = JourneyPointSerializer(points, many=True).data
    gap_seconds = settings.CLIENT_JOURNEY_GAP_SECONDS
    gaps = []
    for index, (first, second) in enumerate(zip(points, points[1:])):
        seconds = (second.captured_at - first.captured_at).total_seconds()
        if seconds > gap_seconds:
            gaps.append({'after_index': index, 'duration_seconds': int(seconds)})
    return Response({
        'journey': JourneySerializer(journey).data,
        'points': payload,
        'stops': JourneyStopSerializer(journey.stops.all(), many=True).data,
        'gaps': gaps,
    })


def _team_list(request, history):
    if request.user.role not in {'tl', 'manager', *MANAGEMENT_ROLES}:
        return Response({'detail': 'Team Lead or management access is required.'}, status=403)
    qs = _queryset()
    if request.user.role not in MANAGEMENT_ROLES:
        qs = qs.filter(assigned_team_lead=request.user)
    if history:
        qs = qs.filter(status__in=[ClientVisitJourney.Status.COMPLETED, ClientVisitJourney.Status.CANCELLED])
    else:
        qs = qs.filter(status__in=ClientVisitJourney.ACTIVE_STATUSES)
    paginator = PageNumberPagination()
    paginator.page_size = min(int(request.query_params.get('page_size', 20)), 100)
    page = paginator.paginate_queryset(qs, request)
    return paginator.get_paginated_response(JourneySerializer(page, many=True).data)


@api_view(['GET'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def team_active_journeys(request):
    return _team_list(request, False)


@api_view(['GET'])
@authentication_classes(AUTHENTICATION)
@permission_classes([IsAuthenticated])
def team_journey_history(request):
    return _team_list(request, True)
