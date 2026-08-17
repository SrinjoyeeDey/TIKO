import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../qa_pipeline/database/database_helper.dart';
import '../models/parent_account.dart';
import '../../qa_pipeline/models/child_profile.dart';

/// Local Repository for Parent Account management, SHA-256 password & PIN hashing,
/// and child profile linkage.
class ParentRepository {
  static const String _table = 'parents';
  static const String _rememberedParentKey = 'remembered_parent_id';

  /// Hashes passwords and PINs securely with SHA-256.
  static String hashSecret(String input) {
    final bytes = utf8.encode(input.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a persistent unique parent identifier (e.g., `parent_8f312a`).
  static String generateParentId() {
    final random = Random();
    final hex = List.generate(6, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'parent_$hex';
  }

  /// Generates a persistent unique child identifier (e.g., `child_29ab4e`).
  static String generateChildId() {
    final random = Random();
    final hex = List.generate(6, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'child_$hex';
  }

  /// Checks if any parent account exists in local database.
  static Future<bool> hasParentAccount() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    final count = res.first['cnt'] as int;
    return count > 0;
  }

  /// Creates a new Parent Account with hashed password.
  static Future<ParentAccount> createParent({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.toLowerCase().trim();
    final db = await DatabaseHelper.instance.database;

    final existing = await db.query(
      _table,
      where: 'email = ?',
      whereArgs: [trimmedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('An account with email $trimmedEmail already exists.');
    }

    final parentId = generateParentId();
    final passwordHash = hashSecret(password);
    final now = DateTime.now();

    final parent = ParentAccount(
      id: parentId,
      name: name.trim(),
      email: trimmedEmail,
      passwordHash: passwordHash,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert(_table, parent.toMap());
    await DatabaseHelper.instance.setSetting(_rememberedParentKey, parentId);

    return parent;
  }

  /// Sets or updates the 4-digit Parent PIN (stored as SHA-256 hash).
  static Future<ParentAccount> setParentPin(String parentId, String pin) async {
    final pinHash = hashSecret(pin);
    final now = DateTime.now();

    final db = await DatabaseHelper.instance.database;
    await db.update(
      _table,
      {
        'pin_hash': pinHash,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [parentId],
    );

    final updated = await getParentById(parentId);
    if (updated == null) {
      throw Exception('Failed to update PIN for parent $parentId');
    }
    return updated;
  }

  /// Verifies entered PIN against stored SHA-256 pinHash.
  static Future<bool> verifyPin(String parentId, String enteredPin) async {
    final parent = await getParentById(parentId);
    if (parent == null || parent.pinHash == null) return false;
    return parent.pinHash == hashSecret(enteredPin);
  }

  /// Verifies entered PIN across any existing parent account (if parentId omitted).
  static Future<ParentAccount?> verifyAnyParentPin(String enteredPin) async {
    final targetHash = hashSecret(enteredPin);
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(_table);
    for (final map in results) {
      final p = ParentAccount.fromMap(map);
      if (p.pinHash == targetHash) {
        return p;
      }
    }
    return null;
  }

  /// Gets parent account by ID.
  static Future<ParentAccount?> getParentById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ParentAccount.fromMap(results.first);
  }

  /// Gets remembered or first available Parent Account.
  static Future<ParentAccount?> getActiveParent() async {
    final rememberedId = await DatabaseHelper.instance.getSetting(_rememberedParentKey);
    if (rememberedId != null && rememberedId.isNotEmpty) {
      final p = await getParentById(rememberedId);
      if (p != null) return p;
    }

    final db = await DatabaseHelper.instance.database;
    final results = await db.query(_table, orderBy: 'created_at DESC', limit: 1);
    if (results.isEmpty) return null;
    return ParentAccount.fromMap(results.first);
  }

  /// Creates a persistent Child Profile under a Parent Account.
  static Future<ChildProfile> createChildProfile({
    required String parentId,
    required String name,
    int? age,
    String? className,
    int difficultyPercentage = 50,
    String? difficultyLevel,
    String? difficultyReasoning,
  }) async {
    final childId = generateChildId();
    final now = DateTime.now();

    final profile = ChildProfile(
      id: childId,
      parentId: parentId,
      name: name.trim(),
      age: age ?? 6,
      className: className ?? 'Grade 1',
      difficultyPercentage: difficultyPercentage,
      difficultyLevel: difficultyLevel,
      difficultyReasoning: difficultyReasoning,
      createdAt: now,
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert('child_profiles', profile.toMap());

    return profile;
  }

  /// Returns all child profiles belonging to a parent account.
  static Future<List<ChildProfile>> getChildrenForParent(String parentId) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'child_profiles',
      where: 'parent_id = ? OR parent_id IS NULL',
      whereArgs: [parentId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => ChildProfile.fromMap(m)).toList();
  }
}
