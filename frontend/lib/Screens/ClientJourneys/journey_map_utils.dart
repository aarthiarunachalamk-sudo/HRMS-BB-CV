import 'journey_models.dart';
import 'dart:math' as math;

class JourneyRouteSegment {
  final List<JourneyLocationPoint> points;
  final bool lowAccuracy;
  const JourneyRouteSegment(this.points, {required this.lowAccuracy});
}

double calculateRecordedDistanceMetres(List<JourneyLocationPoint> points) {
  var total = 0.0;
  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final seconds =
        current.capturedAt.difference(previous.capturedAt).inMilliseconds /
        1000;
    if (seconds <= 0 ||
        previous.accuracyMetres > 100 ||
        current.accuracyMetres > 100) {
      continue;
    }
    final lat1 = previous.latitude * math.pi / 180;
    final lat2 = current.latitude * math.pi / 180;
    final deltaLat = lat2 - lat1;
    final deltaLon = (current.longitude - previous.longitude) * math.pi / 180;
    final value =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final distance =
        6371000 * 2 * math.atan2(math.sqrt(value), math.sqrt(1 - value));
    if (distance / seconds <= 70) total += distance;
  }
  return total;
}

List<JourneyRouteSegment> buildJourneyRouteSegments(
  List<JourneyLocationPoint> points, {
  Duration gapThreshold = const Duration(minutes: 3),
}) {
  final segments = <JourneyRouteSegment>[];
  var current = <JourneyLocationPoint>[];
  var lowAccuracy = false;

  void flush() {
    if (current.length > 1) {
      segments.add(
        JourneyRouteSegment(
          List.unmodifiable(current),
          lowAccuracy: lowAccuracy,
        ),
      );
    }
    current = [];
  }

  for (var index = 0; index < points.length; index++) {
    final point = points[index];
    final hasGap =
        index > 0 &&
        point.capturedAt.difference(points[index - 1].capturedAt) >
            gapThreshold;
    if (hasGap) flush();
    if (current.isNotEmpty && lowAccuracy != point.isLowAccuracy) flush();
    lowAccuracy = point.isLowAccuracy;
    current.add(point);
  }
  flush();
  return segments;
}
