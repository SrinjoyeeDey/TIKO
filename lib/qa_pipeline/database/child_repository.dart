import 'package:uuid/uuid.dart';

import '../models/child_profile.dart';
import 'database_helper.dart';

/// Repository for child profile CRUD operations.
class ChildRepository {
  static const _table = 'child_profiles';
  static const _uuid = Uuid();

  /// Returns the active (most recently created) child profile, or `null`.
  static Future<ChildProfile?> getActiveChild() async {
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
      whereArgs: [name],
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
  }) async {
    final profile = ChildProfile(
      id: _uuid.v4(),
      name: name,
      age: age,
      className: className,
      createdAt: DateTime.now(),
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert(_table, profile.toMap());
    return profile;
  }

  /// Returns all child profiles, ordered by creation date descending.
  static Future<List<ChildProfile>> getAllChildren() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(_table, orderBy: 'created_at DESC');
    return results.map((m) => ChildProfile.fromMap(m)).toList();
  }
}
