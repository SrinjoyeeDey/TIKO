import 'package:sqflite/sqflite.dart';
import '../models/child_profile.dart';
import 'database_helper.dart';

/// Repository for child profile CRUD operations with stable deterministic IDs and Remember Me support.
class ChildRepository {
  static const _table = 'child_profiles';
  static const String _rememberedChildKey = 'remembered_child_id';

  /// Generates a deterministic stable ID from a child's name/username.
  static String generateChildId(String name) {
    final cleaned = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return cleaned.isEmpty ? 'child_user' : 'child_$cleaned';
  }

  /// Logs in an existing child by username or registers a new one with a stable deterministic ID.
  static Future<ChildProfile> loginOrRegisterChild({
    required String name,
    int? age,
    String? className,
    bool rememberMe = true,
  }) async {
    final trimmedName = name.trim().isEmpty ? 'Explorer' : name.trim();
    final childId = generateChildId(trimmedName);

    final existing = await getChildById(childId) ?? await getChildByName(trimmedName);
    if (existing != null) {
      if (rememberMe) {
        await rememberChild(existing.id);
      }
      return existing;
    }

    final profile = ChildProfile(
      id: childId,
      name: trimmedName,
      age: age ?? 6,
      className: className ?? 'Grade 1',
      createdAt: DateTime.now(),
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert(
      _table,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (rememberMe) {
      await rememberChild(profile.id);
    }

    return profile;
  }

  /// Sets the remembered child ID in SQLite app settings.
  static Future<void> rememberChild(String childId) async {
    await DatabaseHelper.instance.setSetting(_rememberedChildKey, childId);
  }

  /// Gets the remembered child ID from SQLite app settings.
  static Future<String?> getRememberedChildId() async {
    return await DatabaseHelper.instance.getSetting(_rememberedChildKey);
  }

  /// Clears the remembered child ID (logout).
  static Future<void> clearRememberedChild() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [_rememberedChildKey],
    );
  }

  /// Returns the remembered child profile, or the most recently active one, or `null`.
  static Future<ChildProfile?> getActiveChild() async {
    final rememberedId = await getRememberedChildId();
    if (rememberedId != null && rememberedId.isNotEmpty) {
      final rememberedProfile = await getChildById(rememberedId);
      if (rememberedProfile != null) return rememberedProfile;
    }

    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ChildProfile.fromMap(results.first);
  }

  /// Returns one child profile by its stable identifier.
  static Future<ChildProfile?> getChildById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ChildProfile.fromMap(results.first);
  }

  /// Returns an existing profile with this name, if one has been created.
  static Future<ChildProfile?> getChildByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      where: 'name = ?',
      whereArgs: [name.trim()],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ChildProfile.fromMap(results.first);
  }

  /// Returns `true` if at least one child profile exists.
  static Future<bool> childExists() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    final count = result.first['cnt'] as int;
    return count > 0;
  }

  /// Creates a new child profile and returns it.
  static Future<ChildProfile> createChild({
    required String name,
    int? age,
    String? className,
    bool rememberMe = true,
  }) async {
    return await loginOrRegisterChild(
      name: name,
      age: age,
      className: className,
      rememberMe: rememberMe,
    );
  }

  /// Returns all child profiles, ordered by creation date descending.
  static Future<List<ChildProfile>> getAllChildren() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(_table, orderBy: 'created_at DESC');
    return results.map((m) => ChildProfile.fromMap(m)).toList();
  }
}
