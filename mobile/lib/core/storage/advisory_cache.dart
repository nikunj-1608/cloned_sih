import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/advisory_pack.dart';

/// On-device store for the last downloaded advisory pack.
///
/// One row, replaced on every successful download. There is no history to keep:
/// at sea what matters is the most recent pack and how old it is.
///
/// Every method swallows storage errors and degrades to null rather than
/// throwing. A corrupt cache must never stop the app from opening — the map and
/// the geofence engine still work from the bundled fallback geometry.
class AdvisoryCache {
  AdvisoryCache._(this._db);

  final Database _db;

  static const _table = 'advisory_pack';

  static Future<AdvisoryCache> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'orca.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id           INTEGER PRIMARY KEY CHECK (id = 1),
          payload      TEXT    NOT NULL,
          fetched_at   INTEGER NOT NULL,
          valid_until  INTEGER NOT NULL
        )
      '''),
    );
    return AdvisoryCache._(db);
  }

  Future<void> save(AdvisoryPack pack) async {
    try {
      await _db.insert(_table, {
        'id': 1,
        'payload': pack.encode(),
        'fetched_at': pack.fetchedAt.millisecondsSinceEpoch,
        'valid_until': pack.validUntil.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } on Object {
      // A failed write costs freshness, not safety. The in-memory pack is
      // still live for this trip.
    }
  }

  /// The last saved pack, or null if there is none or it cannot be read.
  ///
  /// An expired pack is still returned — an old advisory clearly labelled old
  /// beats no advisory at all when you are 30 km offshore.
  Future<AdvisoryPack?> read() async {
    try {
      final rows = await _db.query(_table, where: 'id = 1', limit: 1);
      if (rows.isEmpty) return null;

      final row = rows.first;
      return AdvisoryPack.fromJson(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        source: AdvisorySource.cache,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(row['fetched_at'] as int),
      );
    } on Object {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _db.delete(_table);
    } on Object {
      // Nothing to do; the next save replaces the row anyway.
    }
  }

  Future<void> close() => _db.close();
}
