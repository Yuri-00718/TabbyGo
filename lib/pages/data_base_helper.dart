import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'templates.db');
    return await openDatabase(
      path,
      version: 9, // Updated version number to apply changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create the templates table
    await db.execute('''
    CREATE TABLE templates(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      eventName TEXT,
      eventLocation TEXT,
      eventDate TEXT,
      judges TEXT,
      participant TEXT,
      criteria TEXT,
      templateCode TEXT,
      totalWeightage INTEGER
    )
  ''');

    // Create the results table
    await db.execute('''
    CREATE TABLE results(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_code TEXT,
      participant_name TEXT,
      points INTEGER,
      rank INTEGER
    )
  ''');

    // Create the additional_ranks table
    await db.execute('''
    CREATE TABLE additional_ranks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_code TEXT,
      participant_name TEXT,
      additional_points INTEGER,
      additional_rank INTEGER
    )
  ''');

    // Create the judges table
    await db.execute('''
    CREATE TABLE judges(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      username TEXT UNIQUE,
      password TEXT,
      role TEXT,
      template TEXT,
      image TEXT
    )
  ''');

    // Create the admins table (extra comma removed)
    await db.execute('''
    CREATE TABLE admins(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      username TEXT UNIQUE,
      password TEXT,
      role TEXT,
      image TEXT
    )
  ''');

    if (kDebugMode) {
      print('Database and tables created.');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion...');
    }

    if (oldVersion < 9) {
      // Upgrades related to the judges table
      await db.execute('''
    ALTER TABLE judges ADD COLUMN template TEXT;
  ''');

      await db.execute('''
    ALTER TABLE judges ADD COLUMN image TEXT;
  ''');
    }

    if (kDebugMode) {
      print('Database upgrade completed.');
    }
  }

  Future<void> resetDatabase() async {
    final db = await database; // Ensure the database is properly initialized

    try {
      // Drop all necessary tables before resetting, including the 'admins' table
      await db.execute('DROP TABLE IF EXISTS templates');
      await db.execute('DROP TABLE IF EXISTS results');
      await db.execute('DROP TABLE IF EXISTS additional_ranks');
      await db.execute('DROP TABLE IF EXISTS judges');
      await db.execute('DROP TABLE IF EXISTS admins'); // Drop the admins table

      // Call _onCreate to recreate the tables
      await _onCreate(
          db, 9); // Ensure version matches the current schema version

      if (kDebugMode) {
        print('Database reset and tables recreated.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting database: $e');
      }
      rethrow; // Rethrow the exception to handle it higher up if needed
    }
  }

  Future<int> insertTemplate(Map<String, dynamic> template) async {
    final db = await database;
    try {
      final encodedTemplate = {
        'eventName': template['eventName'] ?? '',
        'eventLocation': template['eventLocation'] ?? '',
        'eventDate': template['eventDate'] ?? '',
        'judges': jsonEncode(template['judges'] ?? []),
        'participant': jsonEncode(template['participant'] ?? []),
        'criteria': jsonEncode(template['criteria'] ?? []),
        'templateCode': template['templateCode'] ?? 'No Code',
        'totalWeightage': template['totalWeightage'] ?? 100,
      };

      if (template.containsKey('photo')) {
        encodedTemplate['photo'] = template['photo'];
      }

      return await db.insert('templates', encodedTemplate);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting template: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    final db = await database;
    try {
      final results = await db.query('templates');
      return results.map((result) {
        return {
          'id': result['id'],
          'eventName': result['eventName'] ?? '',
          'eventLocation': result['eventLocation'] ?? '',
          'eventDate': result['eventDate'] ?? '',
          'judges': result['judges'] != null
              ? jsonDecode(result['judges'] as String)
              : [],
          'participant': result['participant'] != null
              ? jsonDecode(result['participant'] as String)
              : [],
          'criteria': result['criteria'] != null
              ? jsonDecode(result['criteria'] as String)
              : [],
          'templateCode': result['templateCode'] ?? 'No Code',
          'totalWeightage': result['totalWeightage'] ?? 100,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving templates: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTemplateByCode(String code) async {
    final db = await database;
    try {
      final results = await db.query(
        'templates',
        where: 'templateCode = ?',
        whereArgs: [code],
      );

      if (results.isNotEmpty) {
        final template = results.first;
        return {
          'id': template['id'],
          'eventName': template['eventName'] ?? '',
          'eventLocation': template['eventLocation'] ?? '',
          'eventDate': template['eventDate'] ?? '',
          'judges': template['judges'] != null
              ? jsonDecode(template['judges'] as String)
              : [],
          'participant': template['participant'] != null
              ? jsonDecode(template['participant'] as String)
              : [],
          'criteria': template['criteria'] != null
              ? jsonDecode(template['criteria'] as String)
              : [],
          'templateCode': template['templateCode'] ?? 'No Code',
          'totalWeightage': template['totalWeightage'] ?? 100,
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
    final db = await database;

    if (!template.containsKey('id') || template['id'] == null) {
      throw ArgumentError('ID must be provided for update');
    }

    final id = template['id'];

    final existingTemplates = await db.query(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingTemplates.isEmpty) {
      throw Exception('Template with ID $id not found');
    }

    final encodedTemplate = {
      'eventName': template['eventName'] ?? '',
      'eventLocation': template['eventLocation'] ?? '',
      'eventDate': template['eventDate'] ?? '',
      'judges': jsonEncode(template['judges'] ?? []),
      'participant': jsonEncode(template['participant'] ?? []),
      'criteria': jsonEncode(template['criteria'] ?? []),
      'templateCode': template['templateCode'] ?? 'No Code',
      'totalWeightage': template['totalWeightage'] ?? 100,
    };

    return await db.update(
      'templates',
      encodedTemplate,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTemplate(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'templates',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting template: $e');
      }
      rethrow;
    }
  }

//judge method CRUD
  Future<int> insertJudge(Map<String, dynamic> judge) async {
    final db = await database;
    try {
      final encodedJudge = {
        'name': judge['name'] ?? '',
        'username': judge['username'] ?? '',
        'password': judge['password'] ?? '',
        'template': judge['template'] ?? '',
        'role': judge['role'] ?? '',
        'image': judge['image'] ?? '',
      };

      return await db.insert('judges', encodedJudge);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting judge: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getJudges() async {
    final db = await database;
    try {
      final results = await db.query('judges');
      return results.map((result) {
        return {
          'id': result['id'],
          'name': result['name'] ?? '',
          'username': result['username'] ?? '',
          'password': result['password'] ?? '',
          'template': result['template'] ?? '',
          'role': result['role'] ?? '',
          'image': result['image'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving judges: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getJudgeByUsername(String username) async {
    final db = await database;
    try {
      final results = await db.query(
        'judges',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (results.isNotEmpty) {
        final judge = results.first;
        return {
          'id': judge['id'],
          'name': judge['name'] ?? '',
          'username': judge['username'] ?? '',
          'password': judge['password'] ?? '',
          'template': judge['template'] ?? '',
          'role': judge['role'] ?? '',
          'image': judge['image'] ?? '',
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving judge by username: $e');
      }
      rethrow;
    }
  }

  Future<int> updateJudge(int id, Map<String, dynamic> judgeData) async {
    final db = await database;

    // Check if the judge exists in the database
    final existingJudges = await db.query(
      'judges',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingJudges.isEmpty) {
      throw Exception('Judge with ID $id not found');
    }

    // Prepare the updated judge data (merge with existing data if necessary)
    final encodedJudge = {
      'name': judgeData['name'] ?? existingJudges.first['name'],
      'username': judgeData['username'] ?? existingJudges.first['username'],
      'password': judgeData['password'] ?? existingJudges.first['password'],
      'role': judgeData['role'] ?? existingJudges.first['role'],
      'template': judgeData['template'] ?? existingJudges.first['template'],
      'image': judgeData['image'] ?? existingJudges.first['image'],
    };

    // Perform the update operation
    return await db.update(
      'judges',
      encodedJudge,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteJudge(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'judges',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting judge: $e');
      }
      rethrow;
    }
  }

  Future<int> insertResult(Map<String, dynamic> result) async {
    final db = await database;
    try {
      final encodedResult = {
        'event_code': result['event_code'] ?? '',
        'participant_name': result['participant_name'] ?? '',
        'points': result['points'] ?? 0,
        'rank': result['rank'] ?? 0,
      };

      return await db.insert('results', encodedResult);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting result: $e');
      }
      rethrow;
    }
  }

// Admin Methods
  Future<int> insertAdmin(Map<String, dynamic> admin) async {
    final db = await database;
    try {
      final encodedAdmin = {
        'name': admin['name'] ?? '',
        'username': admin['username'] ?? '',
        'password':
            admin['password'] ?? '', // Ensure this is hashed before storage
        'role': admin['role'] ?? '',
        'image': admin['image'] ?? '',
        // Add other necessary fields here
      };

      return await db.insert('admins', encodedAdmin);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting admin: $e');
      }
      rethrow;
    }
  }

// Method to retrieve all admins
  Future<List<Map<String, dynamic>>> getAdmins() async {
    final db = await database;
    try {
      final results = await db.query('admins');
      return results.map((result) {
        return {
          'id': result['id'],
          'name': result['name'] ?? '',
          'username': result['username'] ?? '',
          'password': result['password'] ?? '',
          'role': result['role'] ?? '',
          'image': result['image'] ?? '',
          // Add other necessary fields here
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving admins: $e');
      }
      rethrow;
    }
  }

// Method to get a specific admin by username
  Future<Map<String, dynamic>?> getAdminByUsername(String username) async {
    final db = await database;
    try {
      final results = await db.query(
        'admins',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (results.isNotEmpty) {
        final admin = results.first;
        return {
          'id': admin['id'],
          'name': admin['name'] ?? '',
          'username': admin['username'] ?? '',
          'password': admin['password'] ?? '',
          'role': admin['role'] ?? '',
          'image': admin['image'] ?? '',
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving admin by username: $e');
      }
      rethrow;
    }
  }

// Method to update an admin record
  Future<int> updateAdmin(int id, Map<String, dynamic> adminData) async {
    final db = await database;

    // Check if the admin exists in the database
    final existingAdmins = await db.query(
      'admins',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existingAdmins.isEmpty) {
      throw Exception('Admin with ID $id not found');
    }

    // Prepare the updated admin data (merge with existing data if necessary)
    final existingAdmin = existingAdmins.first;
    final encodedAdmin = {
      'name': adminData['name'] ?? existingAdmin['name'],
      'username': adminData['username'] ?? existingAdmin['username'],
      'password': adminData['password'] ??
          existingAdmin['password'], // Ensure this is hashed before storage
      'role': adminData['role'] ?? existingAdmin['role'],
      'image': adminData['image'] ?? existingAdmin['image'],
    };

    // Perform the update operation
    return await db.update(
      'admins',
      encodedAdmin,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// Method to delete an admin record
  Future<int> deleteAdmin(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'admins',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting admin: $e');
      }
      rethrow;
    }
  }

  //Results methods
  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await database;
    try {
      final results = await db.query('results');
      return results.map((result) {
        return {
          'id': result['id'],
          'event_code': result['event_code'] ?? '',
          'participant_name': result['participant_name'] ?? '',
          'points': result['points'] ?? 0,
          'rank': result['rank'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving results: $e');
      }
      rethrow;
    }
  }

  Future<int> insertAdditionalRank(Map<String, dynamic> rank) async {
    final db = await database;
    try {
      final encodedRank = {
        'event_code': rank['event_code'] ?? '',
        'participant_name': rank['participant_name'] ?? '',
        'additional_points': rank['additional_points'] ?? 0,
        'additional_rank': rank['additional_rank'] ?? 0,
      };

      return await db.insert('additional_ranks', encodedRank);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting additional rank: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAdditionalRanks() async {
    final db = await database;
    try {
      final results = await db.query('additional_ranks');
      return results.map((result) {
        return {
          'id': result['id'],
          'event_code': result['event_code'] ?? '',
          'participant_name': result['participant_name'] ?? '',
          'additional_points': result['additional_points'] ?? 0,
          'additional_rank': result['additional_rank'] ?? 0,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving additional ranks: $e');
      }
      rethrow;
    }
  }
}
