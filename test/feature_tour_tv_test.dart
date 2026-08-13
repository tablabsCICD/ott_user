import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/widgets/feature_tour.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlavorConfig.current =
        const FlavorConfig.forFlavor(FilmytellFlavor.tv);
  });

  tearDown(() {
    FlavorConfig.current =
        const FlavorConfig.forFlavor(FilmytellFlavor.mobile);
  });

  testWidgets('TV remote advances and dismisses the feature tour',
      (tester) async {
    final provider = OnboardingTourProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<OnboardingTourProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                SizedBox.expand(),
                Positioned.fill(child: FeatureTourOverlay()),
              ],
            ),
          ),
        ),
      ),
    );

    provider.replayTour();
    await tester.pumpAndSettle();

    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('2/5'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(provider.isActive, isFalse);

    provider.replayTour();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(provider.isActive, isFalse);

    provider.dispose();
  });
}
