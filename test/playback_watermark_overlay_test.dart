import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/widgets/playback_watermark_overlay.dart';
import 'package:ott/data/models/anti_piracy_models.dart';

void main() {
  test('masks watermark email', () {
    expect(WatermarkData.maskEmail('user@example.com'), 'us***@example.com');
  });

  testWidgets('watermark is visible above the player surface', (tester) async {
    final watermark = WatermarkData(
      userId: '1',
      userName: 'Viewer',
      email: 'user@example.com',
      deviceId: '2f44b286-0ca9-4f9f-8b29-a777e02ea198',
      timestamp: DateTime(2026, 7, 9, 16),
      signature: 'not-rendered',
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const ColoredBox(color: Colors.black),
            Positioned.fill(
              child: PlaybackWatermarkOverlay(watermark: watermark),
            ),
          ],
        ),
      ),
    ));

    expect(
      find.descendant(
        of: find.byType(PlaybackWatermarkOverlay),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('us***@example.com'), findsOneWidget);
    expect(find.textContaining('not-rendered'), findsNothing);
  });
}
