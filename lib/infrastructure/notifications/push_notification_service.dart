import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:redux/redux.dart';
import 'package:solarisdemo/infrastructure/notifications/push_notification_storage_service.dart';
import 'package:solarisdemo/models/notifications/notification_type.dart';
import 'package:solarisdemo/models/user.dart';
import 'package:solarisdemo/navigator.dart' as navigator;
import 'package:solarisdemo/redux/notification/notification_action.dart';
import 'package:solarisdemo/screens/transactions/transaction_approval_pending_screen.dart';
import 'package:solarisdemo/services/api_service.dart';
import 'package:solarisdemo/utilities/helpers/force_reload_helper.dart';
import 'package:solarisdemo/utilities/remote_message_utils.dart';

import '../../redux/app_state.dart';

const String highImportanceChannelId = 'high_importance_channel';

// When PATROL_TEST is true (set via --dart-define=PATROL_TEST=true),
// we skip requesting OS notification permissions to avoid native dialogs
// interfering with Patrol integration tests.
const bool kIsPatrolTestEnv =
    bool.fromEnvironment('PATROL_TEST', defaultValue: false);

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint("FCM Background Message Received: ${message.notification?.title}");
  saveNotificationMessage(message);
}

void saveNotificationMessage(RemoteMessage message) async {
  debugPrint("Save notification message");
  await PushNotificationSharedPreferencesStorageService()
      .add(jsonEncode(message.toMap()));
}

abstract class PushNotificationService extends ApiService {
  PushNotificationService({super.user});

  Future<void> init(Store<AppState> store);

  Future<bool> hasPermission();

  Future<void> handleSavedNotification();

  Future<void> clearNotification();

  Future<String?> getToken();

  void handleTokenRefresh({required User user});

  bool get isInitialized;
}

class FirebasePushNotificationService extends PushNotificationService {
  Store<AppState>? store;

  final _messaging = FirebaseMessaging.instance;
  final PushNotificationStorageService storageService;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState> navigatorKey = navigator.navigatorKey;

  bool _isInitialized = false;

  FirebasePushNotificationService({super.user, required this.storageService}) {
    handleAndroidLocalNotifications();
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> init(Store<AppState> store) async {
    if (isInitialized) {
      return;
    }

    this.store = store;

    // In Patrol test runs we don't need push notifications,
    // and OS dialogs can break automated flows, so we skip
    // requesting notification permissions entirely.
    if (kDebugMode && kIsPatrolTestEnv) {
      debugPrint(
          'PushNotificationService.init: skipping permission request in Patrol test environment');
      _isInitialized = true;
      return;
    }

    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted notifications');
      return;
    }

    // Show notification when app is in foreground
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS foreground notifications are handled by the OS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        sound: true,
      );
    } else {
      // Android foreground notifications are handled by the app
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                android.channelId ?? highImportanceChannelId,
                android.channelId ?? highImportanceChannelId,
              ),
            ),
            payload: jsonEncode(message.toMap()),
          );
        }
      });
    }

    FirebaseMessaging.onBackgroundMessage(
        _onBackgroundMessage); // App is in background and notification received
    FirebaseMessaging.onMessageOpenedApp
        .listen(_onMessage); // App was in background and notification clicked
    FirebaseMessaging.instance
        .getInitialMessage()
        .then(_onMessage); // App was terminated and notification clicked
    FirebaseMessaging.onMessage.listen(_pushNotificationReceived);

    _isInitialized = true;
  }

  @override
  void handleTokenRefresh({required User user}) {
    this.user = user;

    // Handle token
    if (Platform.isIOS) {
      _messaging.getAPNSToken().then((apnsToken) {
        if (apnsToken != null) {
          _messaging
              .getToken()
              .then(_onTokenRefresh); // Initial token (on app start)
        }
      });
    } else {
      _messaging
          .getToken()
          .then(_onTokenRefresh); // Initial token (on app start)
    }
    _messaging.onTokenRefresh.listen(_onTokenRefresh); // Token refresh
  }

  void _onMessage(RemoteMessage? message) {
    if (message == null) return;

    debugPrint('FCM Message received: ${message.toMap().toString()}');

    _redirect(message);
    clearNotification();
  }

  void _pushNotificationReceived(RemoteMessage? message) {
    if (store == null) return;

    forceReloadAppStates(store!);
    _onMessage(message);
  }

  Future<void> handleAndroidLocalNotifications() async {
    if (!Platform.isAndroid) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      highImportanceChannelId,
      highImportanceChannelId,
      importance: Importance.max,
    );
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.initialize(
      const AndroidInitializationSettings('@mipmap/ic_launcher'),
      onDidReceiveNotificationResponse: (response) async {
        // On click handled for our foreground notifications on Android
        if (response.payload == null || response.payload!.isEmpty) return;
        final message = RemoteMessage.fromMap(jsonDecode(response.payload!));
        _onMessage(message);
      },
    );

    await androidImplementation?.createNotificationChannel(channel);
  }

  void _onTokenRefresh(String? token) async {
    debugPrint('FCM Token refreshed: $token');
    if (token == null) return;

    try {
      if (await hasPermission() == false) {
        debugPrint(
            'onTokenRefresh: User declined or has not accepted notifications');
        return;
      }

      await post('notifications/token',
          body: {'token': token}, authNeeded: true);
    } catch (e) {
      log(e.toString());
      throw Exception("Could not update token");
    }
  }

  @override
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  void _redirect(RemoteMessage message) {
    if (store == null) return;

    debugPrint("Redirect from notification");
    final context = navigatorKey.currentContext as BuildContext;
    final notificationType =
        RemoteMessageUtils.getNotificationType(message.data["type"] as String);

    if (notificationType == NotificationType.scaChallenge) {
      store!.dispatch(ReceivedTransactionApprovalNotificationEventAction(
        user: user!,
        message: RemoteMessageUtils.getNotificationTransactionMessage(message),
      ));
      Navigator.of(context)
          .pushNamed(TransactionApprovalPendingScreen.routeName);
    } else if (notificationType == NotificationType.scoringSuccessful) {
      store!.dispatch(ReceivedScoringSuccessfulNotificationEventAction());
    } else if (notificationType == NotificationType.scoringFailed) {
      store!.dispatch(ReceivedScoringFailedNotificationEventAction());
    } else if (notificationType == NotificationType.scoringInProgress) {
      store!.dispatch(ReceivedScoringInProgressNotificationEventAction());
    } else {
      debugPrint("Unsupported notification type ${message.data["type"]}");
    }
  }

  @override
  Future<void> handleSavedNotification() async {
    if (!isInitialized || store == null) {
      return;
    }

    final message = await storageService.find();
    if (message == null) return;

    debugPrint("Handle saved notification");

    final notification = RemoteMessage.fromMap(jsonDecode(message));
    _redirect(notification);
    clearNotification();
  }

  @override
  Future<String?> getToken() async {
    if (Platform.isIOS) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null) {
        return null;
      }
    }
    return await _messaging.getToken();
  }

  @override
  Future<void> clearNotification() async {
    debugPrint("Clear notification");
    await storageService.delete();
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
