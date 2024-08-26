import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'templates.db');
    return await openDatabase(
      path,
      version: 2, // Increment the version to trigger an upgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE templates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventName TEXT,
        eventLocation TEXT,
        eventDate TEXT,
        judges TEXT,               -- JSON string for judges
        criteria TEXT,             -- JSON string for criteria
        templateCode TEXT          -- Template code for the event
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE templates ADD COLUMN templateCode TEXT');
    }
    // Add more migrations as needed for future versions
  }

  Future<int> insertTemplate(Map<String, dynamic> template) async {
    Database db = await instance.database;

    try {
      final encodedTemplate = {
        'eventName': template['eventName'],
        'eventLocation': template['eventLocation'],
        'eventDate': template['eventDate'],
        'judges': jsonEncode(template['judges']),
        'criteria': jsonEncode(template['criteria']),
        'templateCode': template['templateCode'] ?? 'No Code',
      };

      int result = await db.insert('templates', encodedTemplate);
      if (kDebugMode) {
        print('Inserted template with code: ${template['templateCode']}');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting template: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    Database db = await instance.database;
    try {
      List<Map<String, dynamic>> results = await db.query('templates');

      // Decode JSON fields
      List<Map<String, dynamic>> decodedResults = results.map((result) {
        return {
          ...result,
          'judges': jsonDecode(result['judges'] as String),
          'criteria': jsonDecode(result['criteria'] as String),
          'templateCode': result['templateCode'] ?? 'No Code',
        };
      }).toList();

      if (kDebugMode) {
        print(
            'Retrieved templates: ${decodedResults.map((e) => e['templateCode'])}');
      }

      return decodedResults;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving templates: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTemplateById(int id) async {
    Database db = await instance.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        'templates',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isNotEmpty) {
        var template = results.first;
        return {
          'id': template['id'],
          'eventName': template['eventName'],
          'eventLocation': template['eventLocation'],
          'eventDate': template['eventDate'],
          'judges': jsonDecode(template['judges'] as String),
          'criteria': jsonDecode(template['criteria'] as String),
          'templateCode': template['templateCode'] ?? 'No Code',
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving template by id: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTemplateByCode(String code) async {
    Database db = await instance.database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        'templates',
        where: 'templateCode = ?',
        whereArgs: [code],
      );

      if (results.isNotEmpty) {
        var template = results.first;
        return {
          'id': template['id'],
          'eventName': template['eventName'],
          'eventLocation': template['eventLocation'],
          'eventDate': template['eventDate'],
          'judges': jsonDecode(template['judges'] as String),
          'criteria': jsonDecode(template['criteria'] as String),
          'templateCode': template['templateCode'] ?? 'No Code',
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving template by code: $e');
      }
      rethrow;
    }
  }

  Future<int> updateTemplate(Map<String, dynamic> template) async {
    Database db = await instance.database;

    if (!template.containsKey('id') || template['id'] == null) {
      throw ArgumentError('ID must be provided for update');
    }

    int id = template['id'];

    try {
      final updatedTemplate = {
        'eventName': template['eventName'],
        'eventLocation': template['eventLocation'],
        'eventDate': template['eventDate'],
        'judges': jsonEncode(template['judges']),
        'criteria': jsonEncode(template['criteria']),
        'templateCode': template['templateCode'] ?? 'No Code',
      };

      int result = await db.update(
        'templates',
        updatedTemplate,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print(
            'Updated template with id: $id and code: ${template['templateCode']}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating template: $e');
      }
      rethrow;
    }
  }

  Future<int> deleteTemplate(int id) async {
    Database db = await instance.database;
    try {
      int result = await db.delete(
        'templates',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print('Deleted template with id: $id');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting template: $e');
      }
      rethrow;
    }
  }

  Future<void> close() async {
    Database db = await instance.database;
    await db.close();
  }
}
