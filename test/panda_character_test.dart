import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peppa_p/core/widgets/panda_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Panda Character System & Animation Tests', () {
    test('1. Frame paths and asset structure validation', () {
      expect(PandaAnimation.idle.frameCount, 8);
      expect(PandaAnimation.thinking.frameCount, 8);
      expect(PandaAnimation.correct.frameCount, 8);
      expect(PandaAnimation.celebrate.frameCount, 8);
      expect(PandaAnimation.wrongSad.frameCount, 8);
      expect(PandaAnimation.appear.frameCount, 8);

      // Verify numerical order formatting
      expect(PandaAnimation.idle.getFramePath(0), 'assets/animations/panda/idle/frame_01.png');
      expect(PandaAnimation.idle.getFramePath(7), 'assets/animations/panda/idle/frame_08.png');
      expect(PandaAnimation.wrongSad.getFramePath(0), 'assets/animations/panda/wrong_sad/frame_01.png');
      expect(PandaAnimation.wrongSad.getFramePath(7), 'assets/animations/panda/wrong_sad/frame_08.png');

      // Total 48 frames
      expect(PandaController.allAssetPaths.length, 48);
    });

    testWidgets('TEST 1 & 2: Panda widget lifecycle - Appear to Idle loop', (WidgetTester tester) async {
      final controller = PandaController(initialAnimation: PandaAnimation.appear);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandaCharacterWidget(
              controller: controller,
              size: 100,
            ),
          ),
        ),
      );

      // Initial state is appear frame 0
      expect(controller.currentAnimation, PandaAnimation.appear);
      expect(controller.currentFrameIndex, 0);

      // Advance through appear animation (8 frames at 11 fps ~ 91ms/frame)
      await tester.pump(const Duration(milliseconds: 900));

      // After appear completes, transitions automatically to idle
      expect(controller.currentAnimation, PandaAnimation.idle);

      // Verify idle continuously loops
      await tester.pump(const Duration(milliseconds: 2000));
      expect(controller.currentAnimation, PandaAnimation.idle);

      controller.dispose();
    });

    testWidgets('TEST 3: FIRST ANSWER = WRONG triggers SAD IMMEDIATELY (Zero Delay / No Missed Event)', (WidgetTester tester) async {
      final controller = PandaController(initialAnimation: PandaAnimation.idle);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandaCharacterWidget(controller: controller),
          ),
        ),
      );

      expect(controller.currentAnimation, PandaAnimation.idle);

      // FIRST WRONG ANSWER TRIGGER
      controller.playWrongSad();

      // Must be in wrongSad state and frame 0 immediately synchronously
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      expect(controller.currentFrameIndex, 0);

      // Advance through sad animation
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      expect(controller.currentFrameIndex > 0, true);

      // Holds final frame and transitions to idle
      await tester.pump(const Duration(milliseconds: 1500));
      expect(controller.currentAnimation, PandaAnimation.idle);

      controller.dispose();
    });

    testWidgets('TEST 4: SECOND ANSWER = WRONG triggers SAD IMMEDIATELY', (WidgetTester tester) async {
      final controller = PandaController(initialAnimation: PandaAnimation.idle);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandaCharacterWidget(controller: controller),
          ),
        ),
      );

      // 1st wrong answer
      controller.playWrongSad();
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(controller.currentAnimation, PandaAnimation.idle);

      // 2nd wrong answer
      controller.playWrongSad();
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      expect(controller.currentFrameIndex, 0);

      await tester.pump(const Duration(milliseconds: 1600));
      expect(controller.currentAnimation, PandaAnimation.idle);

      controller.dispose();
    });

    testWidgets('TEST 5: CORRECT ANSWER triggers CORRECT → CELEBRATE → IDLE', (WidgetTester tester) async {
      final controller = PandaController(initialAnimation: PandaAnimation.idle);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandaCharacterWidget(controller: controller),
          ),
        ),
      );

      // Correct answer event
      controller.playCorrect();
      expect(controller.currentAnimation, PandaAnimation.correct);
      expect(controller.currentFrameIndex, 0);

      // Advance through correct animation (~800ms)
      await tester.pump(const Duration(milliseconds: 850));

      // Automatically transitions to celebrate
      expect(controller.currentAnimation, PandaAnimation.celebrate);

      // Advance through celebrate animation (~800ms)
      await tester.pump(const Duration(milliseconds: 900));

      // Reverts to idle
      expect(controller.currentAnimation, PandaAnimation.idle);

      controller.dispose();
    });

    testWidgets('TEST 6 & 7: Rapid sequence of WRONG → CORRECT → WRONG → CORRECT → WRONG', (WidgetTester tester) async {
      final controller = PandaController(initialAnimation: PandaAnimation.idle);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PandaCharacterWidget(controller: controller),
          ),
        ),
      );

      // 1. WRONG
      controller.playWrongSad();
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      await tester.pump(const Duration(milliseconds: 300));

      // 2. CORRECT
      controller.playCorrect();
      expect(controller.currentAnimation, PandaAnimation.correct);
      await tester.pump(const Duration(milliseconds: 300));

      // 3. WRONG
      controller.playWrongSad();
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      await tester.pump(const Duration(milliseconds: 300));

      // 4. CORRECT
      controller.playCorrect();
      expect(controller.currentAnimation, PandaAnimation.correct);
      await tester.pump(const Duration(milliseconds: 300));

      // 5. WRONG
      controller.playWrongSad();
      expect(controller.currentAnimation, PandaAnimation.wrongSad);
      await tester.pump(const Duration(milliseconds: 1600));

      // Ends in idle
      expect(controller.currentAnimation, PandaAnimation.idle);

      controller.dispose();
    });
  });
}
