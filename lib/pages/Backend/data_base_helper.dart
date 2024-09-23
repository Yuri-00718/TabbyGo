import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'templates.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables
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

    await db.execute('''
    CREATE TABLE results(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_code TEXT,
      participant_name TEXT,
      points INTEGER,
      rank INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE additional_ranks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_code TEXT,
      participant_name TEXT,
      additional_points INTEGER,
      additional_rank INTEGER
    )
  ''');

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

    await db.execute('''
    CREATE TABLE admins(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      username TEXT UNIQUE,
      password TEXT,
      raw_password TEXT,
      role TEXT,
      image TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE synchronized_templates (
      id TEXT PRIMARY KEY
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
      CREATE TABLE IF NOT EXISTS judges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        username TEXT UNIQUE,
        password TEXT,
        role TEXT,
        template TEXT,
        image TEXT
      )
    ''');

      // Additional upgrades if necessary
      // Example: Handle other schema changes based on version
    }

    if (kDebugMode) {
      print('Database upgrade completed.');
    }
  }

  Future<void> resetDatabase() async {
    final db = await _initDatabase();

    try {
      // Drop all necessary tables before resetting, including the 'admins' table
      await db.execute('DROP TABLE IF EXISTS synchronized_templates');
      await db.execute('DROP TABLE IF EXISTS templates');
      await db.execute('DROP TABLE IF EXISTS results');
      await db.execute('DROP TABLE IF EXISTS additional_ranks');
      await db.execute('DROP TABLE IF EXISTS judges');
      await db.execute('DROP TABLE IF EXISTS admins');

      await _onCreate(
          db, 9); // Ensure version matches the current schema version

      if (kDebugMode) {
        print('Database reset and tables recreated.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting database: $e');
      }
      rethrow;
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

  Future<void> insertOrUpdateTemplate(Map<String, dynamic> template) async {
    // Check if the template already exists in the database by ID
    final existingTemplate = await getTemplateByCode(template['id']);

    if (existingTemplate == null) {
      // Insert new template if it doesn't exist
      await insertTemplate(template);
    } else {
      // Update the existing template if it exists
      await updateTemplate(template);
    }
  }

// Judge CRUD methods
  Future<List<String>> getJudgeEmailsFromTemplate(String templateCode) async {
    try {
      // Get the template data from the database
      final data = await getTemplateByCode(templateCode);

      if (data == null || !data.containsKey('judges')) {
        throw const FormatException('Invalid data format or missing judges');
      }

      // Check if the judges field is a String, if so decode it
      final judgesData = data['judges'];

      // Convert it to List<dynamic> if it's a JSON string
      List<dynamic> judgesList;
      if (judgesData is String) {
        judgesList = jsonDecode(judgesData);
      } else if (judgesData is List<dynamic>) {
        judgesList = judgesData;
      } else {
        throw const FormatException('Unexpected format for judges data');
      }

      // Extract emails from the judges list
      return judgesList.map<String>((judge) {
        if (judge is Map<String, dynamic> && judge.containsKey('email')) {
          return judge['email'] as String;
        } else {
          throw const FormatException('Invalid JSON format for judge email');
        }
      }).toList();
    } catch (e) {
      // Log the error and handle it appropriately
      if (kDebugMode) {
        print('Error retrieving judge emails from template: $e');
      }
      return [];
    }
  }

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
    final existingJudges = await db.query(
      'judges',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existingJudges.isEmpty) {
      throw Exception('Judge with ID $id not found');
    }
    final existingJudge = existingJudges.first;
    final encodedJudge = {
      'name': judgeData['name'] ?? existingJudge['name'],
      'username': judgeData['username'] ?? existingJudge['username'],
      'password': judgeData['password'] ?? existingJudge['password'],
      'template': judgeData['template'] ?? existingJudge['template'],
      'role': judgeData['role'] ?? existingJudge['role'],
      'image': judgeData['image'] ?? existingJudge['image'],
    };
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

  //admin methods
  Future<int> insertAdmin(Map<String, dynamic> admin) async {
    final db = await database;
    try {
      final encodedAdmin = {
        'name': admin['name'] ?? '',
        'username': admin['username'] ?? '',
        'password': _hashPassword(admin['password'] ?? ''),
        'raw_password': admin['password'] ?? '',
        'role': admin['role'] ?? '',
        'image': admin['image'] ?? '',
      };
      return await db.insert(
        'admins',
        encodedAdmin,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting admin: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAdmins() async {
    final db = await database;
    try {
      final results = await db.query('admins');
      return results.map((result) {
        return {
          'id': result['id'],
          'name': result['name'] ?? '',
          'username': result['username'] ?? '',
          'password': result['raw_password'] ?? '',
          'role': result['role'] ?? '',
          'image': result['image'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving admins: $e');
      }
      rethrow;
    }
  }

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
          'password': admin['raw_password'] ?? '',
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

  Future<int> updateAdmin(int id, Map<String, dynamic> adminData) async {
    final db = await database;
    final existingAdmins = await db.query(
      'admins',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existingAdmins.isEmpty) {
      throw Exception('Admin with ID $id not found');
    }
    final existingAdmin = existingAdmins.first;
    final encodedAdmin = {
      'name': adminData['name'] ?? existingAdmin['name'],
      'username': adminData['username'] ?? existingAdmin['username'],
      'password': adminData['password'] != null
          ? _hashPassword(adminData['password'])
          : existingAdmin['password'],
      'raw_password': adminData['password'] ?? existingAdmin['raw_password'],
      'role': adminData['role'] ?? existingAdmin['role'],
      'image': adminData['image'] ?? existingAdmin['image'],
    };
    return await db.update(
      'admins',
      encodedAdmin,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  // Custom admin authentication methods for offline use
  Future<void> registerAdmin(
      String username, String password, String name, String role) async {
    String hashedPassword = _hashPassword(password);
    await _database!.insert(
      'admins',
      {
        'username': username,
        'password': hashedPassword,
        'name': name,
        'role': role,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Method to login Admin in offline mode
  Future<bool> loginAdmin(String username, String password) async {
    String hashedPassword = _hashPassword(password);
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'admins',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );
    return result.isNotEmpty;
  }

// Custom judge registration method for offline use
  Future<void> registerJudge(String username, String password, String name,
      String role, String template, String? image) async {
    String hashedPassword = _hashPassword(password);
    await _database!.insert(
      'judges',
      {
        'username': username,
        'password': hashedPassword,
        'name': name,
        'role': role,
        'template': template,
        'image': image,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// Method to login Judge in offline mode
  Future<bool> loginJudge(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'judges',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isNotEmpty) {
      // Assuming the password is stored as plaintext; otherwise, use proper hash comparison.
      final judge = result.first;
      return judge['password'] == password;
    }
    return false;
  }

  // Method to hash the password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Return the hashed password
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

  // Firestore CRUD operations for templates

  //chats method
  Future<void> addMessage(
      String chatId, Map<String, dynamic> messageData) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> insertTemplateFirestore(
      String id, Map<String, dynamic> template) async {
    try {
      await _firestore.collection('templates').doc(id).set(template);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting template in Firestore: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTemplatesFirestore() async {
    try {
      final snapshot = await _firestore.collection('templates').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving templates from Firestore: $e');
      }
      rethrow;
    }
  }

  Future<void> updateTemplateFirestore(
      String id, Map<String, dynamic> template) async {
    try {
      await _firestore.collection('templates').doc(id).update(template);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating template in Firestore: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteTemplateFirestore(String id) async {
    try {
      await _firestore.collection('templates').doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting template in Firestore: $e');
      }
      rethrow;
    }
  }

  Future<void> insertOrUpdateTemplateFirestore(
      String id, Map<String, dynamic> template) async {
    try {
      await _firestore
          .collection('templates')
          .doc(id)
          .set(template, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting or updating template in Firestore: $e');
      }
      rethrow;
    }
  }

//this method to track and manage templates also to avoid duplication of templates :)
  Future<Set<String>> getSynchronizedTemplateIds() async {
    final db = await instance.database;
    final result = await db.query('synchronized_templates');
    return result.map((row) => row['id'].toString()).toSet();
  }

  Future<void> markTemplateAsSynchronized(String id) async {
    final db = await instance.database;
    await db.insert(
      'synchronized_templates',
      {'id': id},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

// Firestore CRUD operations for judges
  Future<void> insertJudgeFirestore(Map<String, dynamic> judge) async {
    try {
      await _firestore.collection('judges').add(judge);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting judge in Firestore: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getJudgesFirestore() async {
    try {
      final snapshot = await _firestore.collection('judges').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving judges from Firestore: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getJudgeByUsernameFirestore(
      String username) async {
    try {
      final snapshot = await _firestore
          .collection('judges')
          .where('username', isEqualTo: username)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving judge by username from Firestore: $e');
      }
      rethrow;
    }
  }

  Future<void> updateJudgeFirestore(
      String id, Map<String, dynamic> judge) async {
    try {
      await _firestore.collection('judges').doc(id).update(judge);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating judge in Firestore: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteJudgeFirestore(String id) async {
    try {
      await _firestore.collection('judges').doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting judge in Firestore: $e');
      }
      rethrow;
    }
  }

  // Add a new admin to Firestore
  Future<void> insertAdminFirestore(Map<String, dynamic> admin) async {
    try {
      await _firestore.collection('admins').add(admin);
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting admin in Firestore: $e');
      }
      rethrow;
    }
  }

  // Retrieve all admins from Firestore
  Future<List<Map<String, dynamic>>> getAdminsFirestore() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving admins from Firestore: $e');
      }
      rethrow;
    }
  }

  // Retrieve a specific admin by username
  Future<Map<String, dynamic>?> getAdminByUsernameFirestore(
      String username) async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('username', isEqualTo: username)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving admin by username from Firestore: $e');
      }
      rethrow;
    }
  }

  // Update admin data in Firestore
  Future<void> updateAdminFirestore(
      String id, Map<String, dynamic> admin) async {
    try {
      await _firestore.collection('admins').doc(id).update(admin);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin in Firestore: $e');
      }
      rethrow;
    }
  }

  // Delete an admin from Firestore
  Future<void> deleteAdminFirestore(String id) async {
    try {
      await _firestore.collection('admins').doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting admin in Firestore: $e');
      }
      rethrow;
    }
  }

  // Insert or update admin in Firestore
  Future<void> insertOrUpdateAdminFirestore(
      String id, Map<String, dynamic> admin) async {
    try {
      await _firestore
          .collection('admins')
          .doc(id)
          .set(admin, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting or updating admin in Firestore: $e');
      }
      rethrow;
    }
  }
}
