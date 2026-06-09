import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeatureTourStepId {
  language,
  wallet,
  profile,
  search,
  notifications,
  moreActions,
  watchlist,
  download,
}

class FeatureTourStep {
  const FeatureTourStep({
    required this.id,
    required this.title,
    required this.description,
  });

  final FeatureTourStepId id;
  final String title;
  final String description;
}

class OnboardingTourProvider extends ChangeNotifier {
  static const String _completedKey = 'feature_tour_completed';
  static const String _skippedKey = 'feature_tour_skipped';

  static const List<FeatureTourStep> defaultSteps = [
    FeatureTourStep(
      id: FeatureTourStepId.language,
      title: 'Choose Your Language',
      description: 'Select app content language according to your preference.',
    ),
    FeatureTourStep(
      id: FeatureTourStepId.wallet,
      title: 'Wallet',
      description: 'Add/View your balance and view transactions.',
    ),
    /*   FeatureTourStep(
      id: FeatureTourStepId.profile,
      title: 'Your Profile',
      description:
          'Manage account settings, preferences, and personal information.',
    ), */
    FeatureTourStep(
      id: FeatureTourStepId.search,
      title: 'Find Content Faster',
      description:
          'Search by movies, series, genres, language and rating instantly.',
    ),
    FeatureTourStep(
      id: FeatureTourStepId.notifications,
      title: 'Stay Updated',
      description:
          'Receive updates about new releases, recommendations, rewards, and important announcements.',
    ),
    FeatureTourStep(
      id: FeatureTourStepId.moreActions,
      title: 'More Actions',
      description: 'Access additional options like Bookmark, Share and Gift.',
    ),
    /*  FeatureTourStep(
      id: FeatureTourStepId.watchlist,
      title: 'Save for Later',
      description: 'Add content to your watchlist and access it anytime.',
    ),
    FeatureTourStep(
      id: FeatureTourStepId.download,
      title: 'Watch Offline',
      description:
          'Download your favorite content and watch it later without an internet connection.',
    ), */
  ];

  final Map<FeatureTourStepId, Rect> _targetRects = {};
  List<FeatureTourStep> _activeSteps = defaultSteps;
  bool _initialized = false;
  bool _isActive = false;
  bool _completed = false;
  bool _skipped = false;
  int _currentIndex = 0;
  int _targetRefreshRevision = 0;

  bool get initialized => _initialized;
  bool get isActive => _isActive;
  bool get completed => _completed;
  bool get skipped => _skipped;
  int get currentIndex => _currentIndex;
  int get targetRefreshRevision => _targetRefreshRevision;
  List<FeatureTourStep> get activeSteps => List.unmodifiable(_activeSteps);
  FeatureTourStep get currentStep => _activeSteps[_currentIndex];
  Rect? rectFor(FeatureTourStepId id) => _targetRects[id];

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _completed = prefs.getBool(_completedKey) ?? false;
    _skipped = prefs.getBool(_skippedKey) ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> startFirstLaunchTour() async {
    await initialize();
    if (_completed || _skipped || _isActive) return;
    _activeSteps = defaultSteps;
    _start();
  }

  void replayTour() {
    _activeSteps = defaultSteps;
    _start();
  }

  void _start() {
    _targetRects.clear();
    _targetRefreshRevision += 1;
    _currentIndex = 0;
    _isActive = true;
    _track('Tour Started');
    notifyListeners();
  }

  Future<void> next() async {
    if (!_isActive) return;
    if (_currentIndex >= _activeSteps.length - 1) {
      await complete();
      return;
    }
    _currentIndex += 1;
    notifyListeners();
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    await prefs.setBool(_skippedKey, false);
    _completed = true;
    _skipped = false;
    _isActive = false;
    _track('Tour Completed');
    notifyListeners();
  }

  Future<void> skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skippedKey, true);
    _skipped = true;
    _isActive = false;
    _track('Tour Skipped');
    notifyListeners();
  }

  void registerTarget(FeatureTourStepId id, Rect rect) {
    final previous = _targetRects[id];
    if (previous == rect) return;
    _targetRects[id] = rect;
    if (_isActive && currentStep.id == id) {
      notifyListeners();
    }
  }

  void unregisterTarget(FeatureTourStepId id) {
    if (_targetRects.remove(id) != null && _isActive && currentStep.id == id) {
      notifyListeners();
    }
  }

  void trackFeatureClicked(FeatureTourStepId id) {
    if (!_completed) return;
    _track('Feature Clicked After Tour: ${id.name}');
  }

  void _track(String event) {
    if (kDebugMode) {
      debugPrint('ONBOARDING_ANALYTICS: $event');
    }
  }
}
