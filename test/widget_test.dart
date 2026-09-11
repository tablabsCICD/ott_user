import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/cast/cast_button.dart';

void main() {
  testWidgets('CastButton renders Google Cast icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CastButton(),
          ),
        ),
      ),
    );

    expect(find.byType(CastButton), findsOneWidget);
    expect(find.byIcon(Icons.cast), findsOneWidget);
  });
}
