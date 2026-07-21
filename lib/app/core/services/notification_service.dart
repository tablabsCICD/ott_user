import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/pages/news page/NewsScreen.dart';
import 'package:ott/app/route/navigation_service.dart';
import 'package:ott/app/route/routes/app_routes.dart';
import 'package:ott/firebase_options.dart';

const AndroidNotificationChannel _highImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important push notifications.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.handleBackground(message);
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) {
  NotificationService.instance
      .handleNotificationTap(notificationResponse.payload);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationPayloadKey = 'last_notification_payload';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Map<String, dynamic>? _pendingNavigationPayload;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _initializeLocalNotifications();
      await _requestPermissions();
      await _configureForegroundPresentation();
      await _setupTokenHandlers();
      _listenForegroundMessages();
      _listenNotificationTaps();
      await _handleInitialMessage();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('NotificationService init error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    _isInitialized = true;
  }

  Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _persistToken(token);
        return token;
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('FCM token read failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_fcmTokenKey)?.trim();
    return storedToken == null || storedToken.isEmpty ? null : storedToken;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (notificationResponse) {
        handleNotificationTap(notificationResponse.payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_highImportanceChannel);
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint(
          'Notification permission status: ${settings.authorizationStatus}');
    }

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupTokenHandlers() async {
    try {
      final token = await _messaging.getToken();
      await _persistToken(token);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('FCM token fetch failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(newToken);
      if (kDebugMode) {
        debugPrint('FCM token refreshed and stored.');
      }
    }, onError: (Object error, StackTrace stackTrace) {
      if (kDebugMode) {
        debugPrint('FCM token refresh stream error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  Future<void> _persistToken(String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen(handleForeground);
  }

  void _listenNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen(handleBackground);
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await handleBackground(initialMessage);
    }
  }

  Future<void> handleForeground(RemoteMessage message) async {
    await _persistNotificationPayload(message);
    await showLocalNotification(message);
  }

  Future<void> handleBackground(RemoteMessage message) async {
    await _persistNotificationPayload(message);
    await _openTargetScreen(_buildNavigationPayload(message));
  }

  void consumePendingNavigation() {
    final payload = _pendingNavigationPayload;
    if (payload == null) {
      return;
    }

    _pendingNavigationPayload = null;
    unawaited(_openTargetScreen(payload));
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highImportanceChannel.id,
          _highImportanceChannel.name,
          channelDescription: _highImportanceChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(_buildNavigationPayload(message)),
    );
  }

  void handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        unawaited(_openTargetScreen(decoded));
      } else if (decoded is Map) {
        unawaited(_openTargetScreen(decoded.cast<String, dynamic>()));
      }
    } catch (_) {
      unawaited(_openTargetScreen(<String, dynamic>{'rawPayload': payload}));
    }
  }

  Map<String, dynamic> _buildNavigationPayload(RemoteMessage message) {
    return <String, dynamic>{
      'screen': message.data['screen'] ?? 'home',
      'title': message.notification?.title ?? message.data['title'] ?? 'Ott',
      'body': message.notification?.body ?? message.data['body'] ?? '',
      'payload': message.data,
    };
  }

  Future<void> _persistNotificationPayload(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notificationPayloadKey,
      jsonEncode(_buildNavigationPayload(message)),
    );
  }

  Future<void> _openTargetScreen(Map<String, dynamic> payload) async {
    if (await _openDeepLinkFromPayload(payload)) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNavigationPayload = payload;
      return;
    }

    final screen = payload['screen']?.toString().toLowerCase();
    if (screen == 'login') {
      navigator.pushNamed(
        AppRoutes.login,
        arguments: NewsScreenArgs.fromMap(payload),
      );
      return;
    }

    navigator.pushNamed(AppRoutes.notificationPage);
  }

  Future<bool> _openDeepLinkFromPayload(Map<String, dynamic> payload) async {
    for (final candidate in _deepLinkCandidates(payload)) {
      final handled = await DeepLinkService.instance.handleUriString(
        candidate,
        source: 'notification',
      );
      if (handled) return true;
    }

    return false;
  }

  Iterable<String> _deepLinkCandidates(Map<String, dynamic> payload) sync* {
    const linkKeys = <String>{
      'url',
      'link',
      'deepLink',
      'deeplink',
      'dynamicLink',
      'giftLink',
      'claimGiftLink',
      'couponCode',
      'giftCode',
      'code',
      'body',
      'title',
      'rawPayload',
    };

    for (final entry in payload.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map) {
        yield* _deepLinkCandidates(value.cast<String, dynamic>());
        continue;
      }

      if (!linkKeys.contains(key)) continue;

      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }
}
