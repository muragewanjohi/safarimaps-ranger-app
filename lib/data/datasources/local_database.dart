import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/dashboard_models.dart';

class LocalDatabase {
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'safari_ranger_offline.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE pending_incidents (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              data TEXT NOT NULL,
              photo_paths TEXT NOT NULL,
              park_id TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE pending_locations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              data TEXT NOT NULL,
              park_id TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE pending_notes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              incident_id TEXT NOT NULL,
              note TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
      );
      debugPrint('Local SQLite Database initialized at path: $path');
    } catch (e) {
      debugPrint('Error initializing SQLite Database: $e');
    }
  }

  Database get _database {
    if (_db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  Future<int> cacheIncident(
    IncidentModel incident, {
    String? parkId,
    List<String> photoPaths = const [],
  }) async {
    final Map<String, dynamic> data = incident.toJson();
    return _database.insert('pending_incidents', {
      'data': jsonEncode(data),
      'photo_paths': jsonEncode(photoPaths),
      'park_id': parkId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> cacheLocation(
    NewLocationInput location, {
    String? parkId,
  }) async {
    final Map<String, dynamic> data = location.toJson();
    return _database.insert('pending_locations', {
      'data': jsonEncode(data),
      'park_id': parkId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingIncidents() async {
    return _database.query('pending_incidents', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getPendingLocations() async {
    return _database.query('pending_locations', orderBy: 'id ASC');
  }

  Future<int> deletePendingIncident(int id) async {
    return _database.delete('pending_incidents', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePendingLocation(int id) async {
    return _database.delete('pending_locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> cacheNote(String incidentId, String noteText) async {
    return _database.insert('pending_notes', {
      'incident_id': incidentId,
      'note': noteText,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingNotes() async {
    return _database.query('pending_notes', orderBy: 'id ASC');
  }

  Future<int> deletePendingNote(int id) async {
    return _database.delete('pending_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingCount() async {
    try {
      final incidentsResult = await _database.rawQuery('SELECT COUNT(*) as count FROM pending_incidents');
      final locationsResult = await _database.rawQuery('SELECT COUNT(*) as count FROM pending_locations');
      final notesResult = await _database.rawQuery('SELECT COUNT(*) as count FROM pending_notes');

      final incidentsCount = Sqflite.firstIntValue(incidentsResult) ?? 0;
      final locationsCount = Sqflite.firstIntValue(locationsResult) ?? 0;
      final notesCount = Sqflite.firstIntValue(notesResult) ?? 0;

      return incidentsCount + locationsCount + notesCount;
    } catch (e) {
      debugPrint('Error getting pending count: $e');
      return 0;
    }
  }
}
