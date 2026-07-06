import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../storage/prefs.dart';
import '../utils/app_logger.dart';

class NotificationService {
  NotificationService(this._prefs);

  final Prefs _prefs;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'globaly_general',
    'General',
    channelDescription: 'Reminders and updates from Globaly',
    importance: Importance.max,
    priority: Priority.high,
  );

  static const DarwinNotificationDetails _ios = DarwinNotificationDetails(
    presentAlert: true,
    presentBanner: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _android, iOS: _ios);

  bool _initialized = false;

  bool get enabled => _prefs.getBool(Prefs.kNotifications) ?? true;

  Future<void> init() async {
    if (_initialized) return;
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!enabled) return;
    await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      appLogger.w('🔔 notification failed: $e');
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
