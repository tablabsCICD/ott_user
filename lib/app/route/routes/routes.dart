import 'package:flutter/material.dart';
import 'package:ott/app/pages/news%20page/NewsScreen.dart';
import 'package:ott/app/pages/notification%20page/NotificationPage.dart';
import 'package:ott/app/pages/sign%20in%20page/SignInPage.dart';

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
