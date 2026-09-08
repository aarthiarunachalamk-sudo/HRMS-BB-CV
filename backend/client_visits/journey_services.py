import math
from decimal import Decimal

from django.conf import settings
from django.db import transaction

from .models import JourneyStop


EARTH_RADIUS_METRES = 6_371_000.0


def haversine_metres(latitude_a, longitude_a, latitude_b, longitude_b):
    lat1, lon1, lat2, lon2 = map(
        math.radians,
        map(float, (latitude_a, longitude_a, latitude_b, longitude_b)),
    )
    delta_latitude = lat2 - lat1
    delta_longitude = lon2 - lon1
    value = (
        math.sin(delta_latitude / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin(delta_longitude / 2) ** 2
    )
    return EARTH_RADIUS_METRES * 2 * math.atan2(math.sqrt(value), math.sqrt(1 - value))


def point_segment(previous, current):
    seconds = (current.captured_at - previous.captured_at).total_seconds()
    if seconds <= 0:
        return 0.0, seconds, False, 'invalid_time_order'
    distance = haversine_metres(
        previous.latitude, previous.longitude, current.latitude, current.longitude,
    )
    speed = distance / seconds
    if speed > settings.CLIENT_JOURNEY_MAX_SPEED_MPS:
        return 0.0, seconds, False, f'impossible_speed:{speed:.1f}mps'
    if previous.is_low_accuracy or current.is_low_accuracy:
        return 0.0, seconds, False, 'low_accuracy_segment'
    return distance, seconds, True, ''


@transaction.atomic
def recalculate_journey_summary(journey):
    points = list(journey.location_points.order_by('captured_at', 'sequence_number', 'id'))
    JourneyStop.objects.filter(journey=journey).delete()
    if not points:
        journey.total_distance_metres = 0
        journey.total_duration_seconds = 0
        journey.moving_duration_seconds = 0
        journey.stationary_duration_seconds = 0
        journey.save(update_fields=[
            'total_distance_metres', 'total_duration_seconds',
            'moving_duration_seconds', 'stationary_duration_seconds', 'updated_at',
        ])
        return journey

    total_distance = 0.0
    moving_seconds = 0
    stationary_seconds = 0
    stop_radius = settings.CLIENT_JOURNEY_STOP_RADIUS_METRES
    stop_min_seconds = settings.CLIENT_JOURNEY_STOP_MIN_SECONDS
    stop_anchor = points[0]
    stop_cluster = [points[0]]

    for previous, current in zip(points, points[1:]):
        distance, seconds, accepted, _ = point_segment(previous, current)
        if accepted:
            total_distance += distance
            if distance >= 5 or float(current.speed_metres_per_second or 0) >= 1:
                moving_seconds += int(seconds)
            else:
                stationary_seconds += int(seconds)

        anchor_distance = haversine_metres(
            stop_anchor.latitude, stop_anchor.longitude,
            current.latitude, current.longitude,
        )
        if anchor_distance <= stop_radius:
            stop_cluster.append(current)
            continue
        duration = (stop_cluster[-1].captured_at - stop_cluster[0].captured_at).total_seconds()
        if duration >= stop_min_seconds:
            JourneyStop.objects.create(
                journey=journey,
                started_at=stop_cluster[0].captured_at,
                ended_at=stop_cluster[-1].captured_at,
                duration_seconds=int(duration),
                latitude=sum((p.latitude for p in stop_cluster), Decimal('0')) / len(stop_cluster),
                longitude=sum((p.longitude for p in stop_cluster), Decimal('0')) / len(stop_cluster),
            )
        stop_anchor = current
        stop_cluster = [current]

    final_stop_duration = (
        stop_cluster[-1].captured_at - stop_cluster[0].captured_at
    ).total_seconds()
    if final_stop_duration >= stop_min_seconds:
        JourneyStop.objects.create(
            journey=journey,
            started_at=stop_cluster[0].captured_at,
            ended_at=stop_cluster[-1].captured_at,
            duration_seconds=int(final_stop_duration),
            latitude=sum((p.latitude for p in stop_cluster), Decimal('0')) / len(stop_cluster),
            longitude=sum((p.longitude for p in stop_cluster), Decimal('0')) / len(stop_cluster),
        )

    journey.start_latitude = points[0].latitude
    journey.start_longitude = points[0].longitude
    journey.end_latitude = points[-1].latitude
    journey.end_longitude = points[-1].longitude
    journey.last_location_at = points[-1].captured_at
    journey.total_distance_metres = Decimal(str(round(total_distance, 2)))
    if journey.started_at:
        end = journey.completed_at or journey.cancelled_at or points[-1].captured_at
        journey.total_duration_seconds = max(0, int((end - journey.started_at).total_seconds()))
    journey.moving_duration_seconds = moving_seconds
    journey.stationary_duration_seconds = stationary_seconds
    journey.save(update_fields=[
        'start_latitude', 'start_longitude', 'end_latitude', 'end_longitude',
        'last_location_at', 'total_distance_metres', 'total_duration_seconds',
        'moving_duration_seconds', 'stationary_duration_seconds', 'updated_at',
    ])
    return journey
