import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientJourneys/journey_map_utils.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/ClientJourneys/journey_models.dart';

JourneyLocationPoint point(
  int sequence,
  DateTime capturedAt, {
  bool lowAccuracy = false,
}) => JourneyLocationPoint(
  clientGeneratedId: 'point-$sequence',
  journeyId: 7,
  latitude: 11.6643 + sequence / 10000,
  longitude: 78.1460,
  accuracyMetres: lowAccuracy ? 140 : 10,
  capturedAt: capturedAt,
  sequenceNumber: sequence,
  isLowAccuracy: lowAccuracy,
);

void main() {
  test('location upload retains UUID, UTC capture time, and sequence', () {
    final capturedAt = DateTime.utc(2026, 8, 11, 4, 30);
    final value = point(42, capturedAt).toUploadJson();
    expect(value['client_generated_id'], 'point-42');
    expect(value['sequence_number'], 42);
    expect(value['captured_at'], capturedAt.toIso8601String());
  });

  test('actual route is split at GPS gaps', () {
    final now = DateTime.utc(2026, 8, 11, 4);
    final segments = buildJourneyRouteSegments([
      point(1, now),
      point(2, now.add(const Duration(seconds: 30))),
      point(3, now.add(const Duration(minutes: 6))),
      point(4, now.add(const Duration(minutes: 6, seconds: 30))),
    ]);
    expect(segments, hasLength(2));
    expect(segments.first.points.map((item) => item.sequenceNumber), [1, 2]);
    expect(segments.last.points.map((item) => item.sequenceNumber), [3, 4]);
  });

  test('low accuracy route is visually separated', () {
    final now = DateTime.utc(2026, 8, 11, 4);
    final segments = buildJourneyRouteSegments([
      point(1, now),
      point(2, now.add(const Duration(seconds: 20))),
      point(3, now.add(const Duration(seconds: 40)), lowAccuracy: true),
      point(4, now.add(const Duration(seconds: 60)), lowAccuracy: true),
    ]);
    expect(segments, hasLength(2));
    expect(segments.first.lowAccuracy, isFalse);
    expect(segments.last.lowAccuracy, isTrue);
  });

  test('empty and single point routes render without fake segments', () {
    final now = DateTime.utc(2026, 8, 11, 4);
    expect(buildJourneyRouteSegments(const []), isEmpty);
    expect(buildJourneyRouteSegments([point(1, now)]), isEmpty);
  });

  test('display distance ignores low accuracy and impossible jumps', () {
    final now = DateTime.utc(2026, 8, 11, 4);
    final valid = [
      point(1, now),
      point(2, now.add(const Duration(seconds: 20))),
    ];
    expect(calculateRecordedDistanceMetres(valid), greaterThan(0));
    final noisy = [
      point(1, now),
      point(2, now.add(const Duration(seconds: 20)), lowAccuracy: true),
    ];
    expect(calculateRecordedDistanceMetres(noisy), 0);
  });
}
