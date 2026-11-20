import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/utils/app_l10n.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'baseProvider.dart';

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

class OnboardingTourProvider extends BaseProvider {
  static const String _completedKey = 'feature_tour_completed';
  static const String _skippedKey = 'feature_tour_skipped';

  /// Tour steps in display order. Built on every access so the text follows
  /// the currently selected app language.
  static List<FeatureTourStep> get defaultSteps =>
      _defaultStepIds.map(_buildStep).toList(growable: false);

  static const List<FeatureTourStepId> _defaultStepIds = [
    FeatureTourStepId.language,
    FeatureTourStepId.wallet,
    // FeatureTourStepId.profile,
    FeatureTourStepId.search,
    FeatureTourStepId.notifications,
    FeatureTourStepId.moreActions,
    // FeatureTourStepId.watchlist,
    // FeatureTourStepId.download,
  ];

  static FeatureTourStep _buildStep(FeatureTourStepId id) {
    final l10n = appL10n();
    switch (id) {
      case FeatureTourStepId.language:
        return FeatureTourStep(
          id: id,
          title: l10n.tourLanguageTitle,
          description: l10n.tourLanguageDescription,
        );
      case FeatureTourStepId.wallet:
        return FeatureTourStep(
          id: id,
          title: l10n.wallet,
          description: l10n.tourWalletDescription,
        );
      case FeatureTourStepId.profile:
        return FeatureTourStep(
          id: id,
          title: l10n.tourProfileTitle,
          description: l10n.tourProfileDescription,
        );
      case FeatureTourStepId.search:
        return FeatureTourStep(
          id: id,
          title: l10n.tourSearchTitle,
          description: l10n.tourSearchDescription,
        );
      case FeatureTourStepId.notifications:
        return FeatureTourStep(
          id: id,
          title: l10n.tourNotificationsTitle,
          description: l10n.tourNotificationsDescription,
        );
      case FeatureTourStepId.moreActions:
        return FeatureTourStep(
          id: id,
          title: l10n.tourMoreActionsTitle,
          description: l10n.tourMoreActionsDescription,
        );
      case FeatureTourStepId.watchlist:
        return FeatureTourStep(
          id: id,
          title: l10n.tourWatchlistTitle,
          description: l10n.tourWatchlistDescription,
        );
      case FeatureTourStepId.download:
        return FeatureTourStep(
          id: id,
          title: l10n.tourDownloadTitle,
          description: l10n.tourDownloadDescription,
        );
    }
  }

  final Map<FeatureTourStepId, Rect> _targetRects = {};
  List<FeatureTourStepId> _activeStepIds = _defaultStepIds;
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
  List<FeatureTourStep> get activeSteps =>
      List.unmodifiable(_activeStepIds.map(_buildStep));
  FeatureTourStep get currentStep => _buildStep(_activeStepIds[_currentIndex]);
  Rect? rectFor(FeatureTourStepId id) => _targetRects[id];

  Future<void> initialize() async {
    if (_initialized || isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    if (isDisposed) return;
    _completed = prefs.getBool(_completedKey) ?? false;
    _skipped = prefs.getBool(_skippedKey) ?? false;
    _initialized = true;
    _track('Tour Initialized completed=$_completed skipped=$_skipped');
    notifyListeners();
  }

  Future<void> startFirstLaunchTour({BuildContext? context}) async {
    final contextDescription = _describeContext(context);
    _track('Tour first launch requested context=$contextDescription');
    await initialize();
    if (isDisposed) return;
    if (context != null && !context.mounted) {
      _track('Tour first launch aborted: context unmounted');
      return;
    }
    if (_completed || _skipped || _isActive) return;
    _activeStepIds = _stepsForContext(context);
    _start();
  }

  void replayTour({BuildContext? context}) {
    if (isDisposed) return;
    if (context != null && !context.mounted) {
      _track('Tour replay aborted: context unmounted');
      return;
    }
    _activeStepIds = _stepsForContext(context);
    _start();
  }

  List<FeatureTourStepId> _stepsForContext(BuildContext? context) {
    if (context != null && !context.mounted) {
      return _defaultStepIds;
    }
    final removeFifthStep =
        kIsWeb || (context != null && ResponsiveWidget.isTv(context));
    if (!removeFifthStep) return _defaultStepIds;

    return _defaultStepIds
        .where((id) => id != FeatureTourStepId.moreActions)
        .toList();
  }

  void _start() {
    if (isDisposed) return;
    _targetRects.clear();
    _targetRefreshRevision += 1;
    _currentIndex = 0;
    _isActive = true;
    _track('Tour Started');
    notifyListeners();
  }

  Future<void> next() async {
    if (!_isActive || isDisposed) return;
    if (_currentIndex >= _activeStepIds.length - 1) {
      await complete();
      return;
    }
    if (isDisposed) return;
    _currentIndex += 1;
    notifyListeners();
  }

  Future<void> complete() async {
    if (isDisposed) return;
    final prefs = await SharedPreferences.getInstance();
    if (isDisposed) return;
    await prefs.setBool(_completedKey, true);
    if (isDisposed) return;
    await prefs.setBool(_skippedKey, false);
    if (isDisposed) return;
    _completed = true;
    _skipped = false;
    _isActive = false;
    _track('Tour Completed');
    notifyListeners();
  }

  Future<void> skip() async {
    if (isDisposed) return;
    final prefs = await SharedPreferences.getInstance();
    if (isDisposed) return;
    await prefs.setBool(_skippedKey, true);
    if (isDisposed) return;
    _skipped = true;
    _isActive = false;
    _track('Tour Skipped');
    notifyListeners();
  }

  void registerTarget(FeatureTourStepId id, Rect rect) {
    if (isDisposed) return;
    final previous = _targetRects[id];
    if (previous == rect) return;
    _targetRects[id] = rect;
    if (_isActive && _activeStepIds[_currentIndex] == id) {
      notifyListeners();
    }
  }

  void unregisterTarget(FeatureTourStepId id) {
    if (isDisposed) return;
    if (_targetRects.remove(id) != null &&
        _isActive &&
        _activeStepIds[_currentIndex] == id) {
      notifyListeners();
    }
  }

  void trackFeatureClicked(FeatureTourStepId id) {
    if (isDisposed || !_completed) return;
    _track('Feature Clicked After Tour: ${id.name}');
  }

  String _describeContext(BuildContext? context) {
    if (context == null) return 'none';
    return 'mounted=${context.mounted}';
  }

  void _track(String event) {
    if (kDebugMode) {}
  }
}
