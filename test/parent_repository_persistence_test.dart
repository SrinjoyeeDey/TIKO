import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:peppa_p/qa_pipeline/database/database_helper.dart';
import 'package:peppa_p/core/services/parent_repository.dart';
import 'package:peppa_p/core/state/child_state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ParentRepository & SQLite Persistence Tests', () {
    test('Creating parent with email and name TestParent persists in SQLite', () async {
      final testEmail = 'testparent_${DateTime.now().millisecondsSinceEpoch}@gmail.com';
      final parent = await ParentRepository.createParent(
        name: 'TestParent',
        email: testEmail,
        password: 'pin_secured_account',
      );

      expect(parent.id, isNotEmpty);
      expect(parent.name, equals('TestParent'));
      expect(parent.email, equals(testEmail));

      // Set PIN 1234
      await ParentRepository.setParentPin(parent.id, '1234');

      // Verify PIN
      final verified = await ParentRepository.verifyPin(parent.id, '1234');
      expect(verified, isTrue);

      // Verify query by email
      final fetched = await ParentRepository.getParentByEmail(testEmail);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('TestParent'));
      expect(fetched.email, equals(testEmail));

      // Verify linked child is automatically created with parent name
      final children = await ParentRepository.getChildrenForParent(parent.id);
      expect(children, isNotEmpty);
      expect(children.first.name, equals('TestParent'));
      expect(children.first.parentId, equals(parent.id));

      // Test ChildState initRememberedProfile
      await ParentRepository.rememberParent(parent.id);
      await ChildState.instance.initRememberedProfile();

      expect(ChildState.instance.currentParent?.name, equals('TestParent'));
      expect(ChildState.instance.currentProfile.name, equals('TestParent'));
      expect(ChildState.instance.currentProfile.difficultyPercentage, equals(50));
    });
  });
}
