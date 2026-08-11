import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'journey_models.dart';

abstract interface class JourneyPointQueue {
  Future<void> enqueue(JourneyLocationPoint point);
  Future<List<JourneyLocationPoint>> pending(int journeyId, {int limit = 100});
  Future<void> acknowledge(Iterable<String> clientIds);
  Future<void> reject(Map<String, String> rejected);
  Future<int> nextSequence(int journeyId);
  Future<int> pendingCount(int journeyId);
}

class SqliteJourneyPointQueue implements JourneyPointQueue {
  SqliteJourneyPointQueue._();
  static final instance = SqliteJourneyPointQueue._();
  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    _database = await openDatabase(
      '$root/client_journey_locations.db',
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE journey_location_queue (
          client_generated_id TEXT PRIMARY KEY,
          journey_id INTEGER NOT NULL,
          sequence_number INTEGER NOT NULL,
          captured_at TEXT NOT NULL,
          payload TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          rejection_reason TEXT,
          created_at TEXT NOT NULL,
          UNIQUE(journey_id, sequence_number)
        )
      '''),
    );
    return _database!;
  }

  @override
  Future<void> enqueue(JourneyLocationPoint point) async {
    final db = await _db;
    await db.insert('journey_location_queue', {
      'client_generated_id': point.clientGeneratedId,
      'journey_id': point.journeyId,
      'sequence_number': point.sequenceNumber,
      'captured_at': point.capturedAt.toUtc().toIso8601String(),
      'payload': jsonEncode(point.toUploadJson()),
      'status': 'pending',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<JourneyLocationPoint>> pending(
    int journeyId, {
    int limit = 100,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'journey_location_queue',
      where: 'journey_id = ? AND status = ?',
      whereArgs: [journeyId, 'pending'],
      orderBy: 'sequence_number ASC',
      limit: limit,
    );
    return rows
        .map((row) {
          final json = Map<String, dynamic>.from(
            jsonDecode('${row['payload']}') as Map,
          );
          json['journey_id'] = journeyId;
          return JourneyLocationPoint.fromJson(json);
        })
        .toList(growable: false);
  }

  @override
  Future<void> acknowledge(Iterable<String> clientIds) async {
    final ids = clientIds.toList(growable: false);
    if (ids.isEmpty) return;
    final db = await _db;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete(
          'journey_location_queue',
          where: 'client_generated_id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  @override
  Future<void> reject(Map<String, String> rejected) async {
    if (rejected.isEmpty) return;
    final db = await _db;
    await db.transaction((txn) async {
      for (final entry in rejected.entries) {
        await txn.update(
          'journey_location_queue',
          {'status': 'rejected', 'rejection_reason': entry.value},
          where: 'client_generated_id = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }

  @override
  Future<int> nextSequence(int journeyId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT MAX(sequence_number) AS value FROM journey_location_queue WHERE journey_id = ?',
      [journeyId],
    );
    return (rows.first['value'] as int? ?? 0) + 1;
  }

  @override
  Future<int> pendingCount(int journeyId) async {
    final db = await _db;
    final value = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM journey_location_queue WHERE journey_id = ? AND status = ?',
        [journeyId, 'pending'],
      ),
    );
    return value ?? 0;
  }
}
