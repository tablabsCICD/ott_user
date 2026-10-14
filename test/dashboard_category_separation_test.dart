import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/provider/dashboardProvider.dart';

void main() {
  group('DashboardProvider Category Separation & Type Filtering', () {
    late DashboardProvider provider;

    setUp(() {
      provider = DashboardProvider();
    });

    test('initial state is clean and empty', () {
      expect(provider.dashboardData, isEmpty);
      expect(provider.continueWatchedMovies, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('clear() resets dashboard and continue watched data', () {
      provider.clear();
      expect(provider.dashboardData, isEmpty);
      expect(provider.continueWatchedMovies, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });
}
