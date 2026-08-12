import 'package:flutter/foundation.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// Singleton database manager for the application's SQLite database.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'qs_ans_learning_v2.db';
  static const int _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use FFI for Windows/Linux/macOS desktop support.
    if (!kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.linux || 
         defaultTargetPlatform == TargetPlatform.macOS)) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE question_attempts ADD COLUMN correct_matches INTEGER');
      await db.execute('ALTER TABLE question_attempts ADD COLUMN total_matches INTEGER');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE child_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER,
        class_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE level_progress (
        child_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        level_id TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        stars INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        PRIMARY KEY (child_id, chapter_id, level_id),
        FOREIGN KEY (child_id) REFERENCES child_profiles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE question_attempts (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        level_id TEXT NOT NULL,
        question_id INTEGER NOT NULL,
        question_type TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        time_taken_seconds INTEGER NOT NULL,
        is_correct INTEGER NOT NULL DEFAULT 0,
        similarity_score REAL,
        user_answer TEXT,
        correct_matches INTEGER,
        total_matches INTEGER,
        FOREIGN KEY (child_id) REFERENCES child_profiles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_attempts_child_level
      ON question_attempts(child_id, chapter_id, level_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_attempts_child_type
      ON question_attempts(child_id, question_type)
    ''');
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
