import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';

void main() {
  testWidgets('StarRatingWidget basic test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StarRatingWidget(rating: 4.5),
        ),
      ),
    );
    expect(find.byType(StarRatingWidget), findsOneWidget);
  });

  test('FlavorConfig test', () {
    FlavorConfig.current = const FlavorConfig.forFlavor(FilmytellFlavor.tv);
    expect(FlavorConfig.current.isTv, isTrue);
    expect(FlavorConfig.current.flavor, FilmytellFlavor.tv);
  });
}
