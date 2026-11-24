import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<FeatureTourStepId> ids(OnboardingTourProvider p) =>
    p.activeSteps.map((s) => s.id).toList();

Future<Map<String, Object>> prefsSnapshot() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    for (final k in prefs.getKeys()) k: prefs.get(k)!,
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh install: first-launch tour shows only Select Language', () async {
    final tour = OnboardingTourProvider();
    await tour.startFirstLaunchTour();
    expect(tour.isActive, isTrue);
    expect(ids(tour), [FeatureTourStepId.language]);
  });

  test('completing the first-launch tour stops it on later launches',
      () async {
    final first = OnboardingTourProvider();
    await first.startFirstLaunchTour();
    await first.next(); // single step -> completes
    expect(first.isActive, isFalse);

    final nextLaunch = OnboardingTourProvider();
    await nextLaunch.startFirstLaunchTour();
    expect(nextLaunch.isActive, isFalse);
  });

  test('skipping the first-launch tour stops it on later launches', () async {
    final first = OnboardingTourProvider();
    await first.startFirstLaunchTour();
    await first.skip();

    final nextLaunch = OnboardingTourProvider();
    await nextLaunch.startFirstLaunchTour();
    expect(nextLaunch.isActive, isFalse);
  });

  test('Profile/Help replay shows all five steps in the existing order',
      () async {
    final tour = OnboardingTourProvider();
    tour.replayTour();
    expect(ids(tour), [
      FeatureTourStepId.language,
      FeatureTourStepId.wallet,
      FeatureTourStepId.search,
      FeatureTourStepId.notifications,
      FeatureTourStepId.moreActions,
    ]);
  });

  test('completing or skipping a replay does not touch first-launch state',
      () async {
    final tour = OnboardingTourProvider();
    tour.replayTour();
    for (var i = 0; i < 5; i++) {
      await tour.next();
    }
    expect(tour.isActive, isFalse);
    tour.replayTour();
    await tour.skip();
    expect(tour.isActive, isFalse);
    expect(await prefsSnapshot(), isEmpty);

    // The automatic one-step tour still appears on the first launch.
    final launch = OnboardingTourProvider();
    await launch.startFirstLaunchTour();
    expect(launch.isActive, isTrue);
    expect(ids(launch), [FeatureTourStepId.language]);
  });

  test('replay stays available (all five steps) after first-launch completion',
      () async {
    final tour = OnboardingTourProvider();
    await tour.startFirstLaunchTour();
    await tour.next();
    tour.replayTour();
    expect(tour.isActive, isTrue);
    expect(ids(tour).length, 5);
  });
}
