import 'package:flutter/material.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/news%20page/NewsScreen.dart';
import 'package:ott/app/pages/notification%20page/NotificationPage.dart';

import '../../pages/onboarding pages/SplashScreen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // case AppRoutes.login:
      //   return buildRoute(SignInPage(), settings: settings);

      case AppRoutes.entry:
        return buildRoute(SplashScreen(), settings: settings);

      case AppRoutes.news:
        final args = settings.arguments is NewsScreenArgs
            ? settings.arguments as NewsScreenArgs
            : const NewsScreenArgs(
                title: 'News',
                body: 'Opened from notification',
                payload: <String, dynamic>{},
              );
        return buildRoute(NewsScreen(args: args), settings: settings);

      case AppRoutes.movieDetails:
        final movieId = _parseMovieId(settings.arguments);
        if (movieId == null || movieId <= 0) {
          return _invalidMovieRoute(settings);
        }
        return buildRoute(
          MovieDetailsPage(movieId: movieId),
          settings: settings,
        );

      case AppRoutes.notificationPage:
        return buildRoute(const NotificationPage(), settings: settings);

      /*  case AppRoutes.home:
         return buildRoute(DashboardPage(), settings: settings);

       case AppRoutes.forgotPassword:
         return buildRoute(DashboardPage(), settings: settings);

      case AppRoutes.profile:
        return buildRoute(ProfilePage(), settings: settings);

      case AppRoutes.editProfile:
        return buildRoute(EditProfilePage(), settings: settings);

      case AppRoutes.document:
        return buildRoute(DocumentsPage(), settings: settings);

      case AppRoutes.analytics:
        return buildRoute(AnalyticsPage(), settings: settings);

      case AppRoutes.settlement:
        return buildRoute(SettlementPage(), settings: settings);

      case AppRoutes.helpSupport:
        return buildRoute(HelpDeskPage(), settings: settings);

      case AppRoutes.releaseContent:
        return buildRoute(ReleasedContentPage(), settings: settings);

      case AppRoutes.pendingContent:
        return buildRoute(PendingContentPage(), settings: settings);*/

      default:
        return buildRoute(SplashScreen(), settings: settings);
    }
  }

  static MaterialPageRoute buildRoute(Widget child,
      {required RouteSettings settings}) {
    return MaterialPageRoute(
        settings: settings, builder: (BuildContext context) => child);
  }

  static int? _parseMovieId(Object? arguments) {
    if (arguments is MovieDetailsRouteArgs) {
      return arguments.movieId;
    }

    if (arguments is int) {
      return arguments;
    }

    if (arguments is String) {
      return int.tryParse(arguments);
    }

    if (arguments is Map<String, dynamic>) {
      final value = arguments['movieId'] ?? arguments['id'];
      return int.tryParse('$value');
    }

    if (arguments is Map) {
      final value = arguments['movieId'] ?? arguments['id'];
      return int.tryParse('$value');
    }

    return null;
  }

  static Route<dynamic> _invalidMovieRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Movie not found'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The shared movie link is invalid or incomplete.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static Route _createRoute(Widget root) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => root,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = const Offset(0.0, 1.0);
        var end = Offset.zero;
        const curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Exit App',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 450.0,
                  width: 450.0,
                  //child: Lottie.asset('assets/lottie/error.json'),
                ),
                Text(
                  'Seems the route you\'ve navigated to doesn\'t exist!!',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
