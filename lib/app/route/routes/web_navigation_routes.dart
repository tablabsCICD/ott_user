class WebNavigationRoute {
  const WebNavigationRoute({
    required this.path,
    required this.index,
    this.homeContentType,
  });

  final String path;
  final int index;
  final String? homeContentType;
}

class WebNavigationRoutes {
  WebNavigationRoutes._();

  static const home = WebNavigationRoute(
    path: '/home',
    index: 0,
    homeContentType: 'MOVIE',
  );
  static const movies = WebNavigationRoute(
    path: '/movies',
    index: 0,
    homeContentType: 'MOVIE',
  );
  static const series = WebNavigationRoute(path: '/series', index: 1);
  static const shorts = WebNavigationRoute(path: '/shorts', index: 2);
  static const search = WebNavigationRoute(path: '/search', index: 3);
  static const watchlist = WebNavigationRoute(path: '/watchlist', index: 4);
  static const profile = WebNavigationRoute(path: '/profile', index: 5);
  static const upcoming = WebNavigationRoute(path: '/upcoming', index: 6);
  static const subscription = WebNavigationRoute(
    path: '/subscription',
    index: 7,
  );
  static const downloads = WebNavigationRoute(path: '/downloads', index: 8);
  static const settings = WebNavigationRoute(path: '/settings', index: 9);
  static const help = WebNavigationRoute(path: '/help_support', index: 10);

  static const values = <WebNavigationRoute>[
    home,
    movies,
    series,
    shorts,
    search,
    watchlist,
    profile,
    upcoming,
    subscription,
    downloads,
    settings,
    help,
  ];

  static WebNavigationRoute? fromPath(String? rawPath) {
    final path = Uri.tryParse(rawPath ?? '')?.path ?? rawPath ?? '';
    for (final route in values) {
      if (route.path == path) return route;
    }
    return null;
  }

  static WebNavigationRoute fromIndex(
    int index, {
    String? homeContentType,
  }) {
    if (index == 0 && homeContentType == 'MOVIE') return movies;
    for (final route in values) {
      if (route.index == index) return route;
    }
    return home;
  }
}
