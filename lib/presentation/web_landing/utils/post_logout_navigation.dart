import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/presentation/web_landing/screens/web_landing_screen.dart';

Route<dynamic> buildPostLogoutRoute() {
  return MaterialPageRoute(
    settings: RouteSettings(name: kIsWeb ? '/' : null),
    builder: (_) {
      if (kIsWeb) return const WebLandingScreen();
      return const LoginCard();
    },
  );
}

void pushPostLogoutReplacement(BuildContext context) {
  _logPostLogout('pushReplacement to ${kIsWeb ? 'web landing /' : 'login'}');
  Navigator.pushReplacement(context, buildPostLogoutRoute());
}

void pushPostLogoutAndRemoveUntil(NavigatorState navigator) {
  _logPostLogout('pushAndRemoveUntil to ${kIsWeb ? 'web landing /' : 'login'}');
  navigator.pushAndRemoveUntil(buildPostLogoutRoute(), (_) => false);
}

void _logPostLogout(String message) {
  if (!kIsWeb || !kDebugMode) return;
  developer.log(message, name: 'WebAuthGuard');
}
