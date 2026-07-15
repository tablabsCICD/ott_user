import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/widgets/video_skip_controls.dart';

void main() {
  group('boundedSeekPosition', () {
    const duration = Duration(minutes: 2);

    test('seeks exactly ten seconds when within bounds', () {
      expect(
        boundedSeekPosition(
          position: const Duration(seconds: 30),
          duration: duration,
          offset: const Duration(seconds: 10),
        ),
        const Duration(seconds: 40),
      );
      expect(
        boundedSeekPosition(
          position: const Duration(seconds: 30),
          duration: duration,
          offset: const Duration(seconds: -10),
        ),
        const Duration(seconds: 20),
      );
    });

    test('clamps seeking to zero and total duration', () {
      expect(
        boundedSeekPosition(
          position: const Duration(seconds: 4),
          duration: duration,
          offset: const Duration(seconds: -10),
        ),
        Duration.zero,
      );
      expect(
        boundedSeekPosition(
          position: const Duration(seconds: 115),
          duration: duration,
          offset: const Duration(seconds: 10),
        ),
        duration,
      );
    });
  });

  testWidgets('exposes and invokes both skip controls', (tester) async {
    var backwardCalls = 0;
    var forwardCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoSkipControls(
            onBackward: () => backwardCalls++,
            onForward: () => forwardCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Skip backward 10 seconds'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Skip forward 10 seconds'));
    await tester.pumpAndSettle();

    expect(backwardCalls, 1);
    expect(forwardCalls, 1);
  });
}
