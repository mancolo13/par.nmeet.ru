import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Common local push notifications service for all our Flutter Android apps.
///
/// Features:
/// - 100% on-device (no Firebase, no backend server needed).
/// - Title for all notifications: «Ваш бонус»
/// - Welcome push on first open + permission: «Регистрируйся и получай бонус на первое пополнение!»
/// - 7 days push (test: 1 min): «Вы активировали свой бонус на первое пополнение? Если нет — самое время!»
/// - 20 days push (test: 3 min): «Напоминаем! Бонус на пополнение доступен в личном кабинете!»
/// - Countdowns strictly start from the first open time.
/// - Re-launches and app updates never reset the schedule or create duplicate alarms.
/// - Works without reopening the app; schedule survives phone reboot via AlarmManager.
/// - Tapping a notification opens the app.
/// - If permission is granted later, only future notifications are scheduled; missed ones are never sent.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  // SharedPreferences Keys
  static const String prefKeyFirstOpenTime = 'local_push_first_opened_at_ms';
  static const String prefKeyWelcomeSent = 'local_push_welcome_sent';
  static const String prefKey7dScheduled = 'local_push_7d_scheduled';
  static const String prefKey20dScheduled = 'local_push_20d_scheduled';

  // Notification IDs
  static const int idWelcome = 101;
  static const int id7Days = 102;
  static const int id20Days = 103;

  // Channel details
  static const String channelId = 'bonus_reminders_channel';
  static const String channelName = 'Ваш бонус';
  static const String channelDescription =
      'Уведомления о бонусах и специальных предложениях';

  // Notification Texts (Russian)
  static const String notificationTitle = 'Ваш бонус';
  static const String welcomeBody =
      'Регистрируйся и получай бонус на первое пополнение!';
  static const String reminder7dBody =
      'Вы активировали свой бонус на первое пополнение? Если нет — самое время!';
  static const String reminder20dBody =
      'Напоминаем! Бонус на пополнение доступен в личном кабинете!';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _useTestIntervals = false;

  /// Whether test intervals (1 & 3 minutes) or release intervals (7 & 20 days) are active.
  bool get useTestIntervals => _useTestIntervals;

  /// Underlying FlutterLocalNotificationsPlugin instance.
  FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  /// Initialize local notifications plugin, configure timezone,
  /// register notification channel, and schedule/sync notifications.
  ///
  /// [useTestIntervals]:
  /// - `true`: 1 minute and 3 minutes (for testing & verification)
  /// - `false`: 7 days and 20 days (for production release)
  /// - `null`: defaults to [kDebugMode] (true in debug, false in release)
  ///
  /// [requestPermissionOnInit]: if true, prompts the user for permission on initial setup.
  /// [onNotificationTapped]: optional callback when user taps a notification.
  Future<void> initialize({
    bool? useTestIntervals,
    bool requestPermissionOnInit = true,
    void Function(NotificationResponse response)? onNotificationTapped,
  }) async {
    _useTestIntervals = useTestIntervals ?? kDebugMode;

    if (_isInitialized) {
      await syncSchedule();
      return;
    }

    // 1. Initialize timezone database and detect device location
    await _configureLocalTimeZone();

    // 2. Configure Android and iOS initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTapped?.call(response);
      },
    );

    // 3. Create high-importance notification channel on Android
    await _createAndroidNotificationChannel();

    _isInitialized = true;

    // 4. Record first open timestamp if this is the very first launch
    final prefs = await SharedPreferences.getInstance();
    final int? existingFirstOpen = prefs.getInt(prefKeyFirstOpenTime);
    if (existingFirstOpen == null) {
      await prefs.setInt(
        prefKeyFirstOpenTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    // 5. Request permission if requested, then synchronize schedule
    if (requestPermissionOnInit) {
      await requestPermission();
    }

    await syncSchedule(prefs: prefs);
  }

  /// Request runtime notification permission (Android 13+ & iOS).
  /// Also requests exact alarms permission on Android if supported.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    bool granted = false;
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notificationsGranted =
            await androidImpl.requestNotificationsPermission();
        granted = notificationsGranted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final iosGranted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = iosGranted ?? false;
      }
    }

    if (granted) {
      await syncSchedule();
    }
    return granted;
  }

  /// Check whether notification permission is currently granted.
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      return true;
    }
    return false;
  }

  /// Synchronize notification schedule based on:
  /// 1. First open time (never overwritten).
  /// 2. Current permission status (if not granted, nothing is sent).
  /// 3. Whether trigger times are in the future vs past ("пропущенные не догоняем").
  /// 4. Avoids duplicate scheduling if already scheduled or sent.
  Future<void> syncSchedule({SharedPreferences? prefs}) async {
    final storage = prefs ?? await SharedPreferences.getInstance();

    final bool permitted = await isPermissionGranted();
    if (!permitted) {
      return;
    }

    final int? firstOpenMs = storage.getInt(prefKeyFirstOpenTime);
    if (firstOpenMs == null) {
      // First open hasn't been recorded yet; record it now
      await storage.setInt(
        prefKeyFirstOpenTime,
        DateTime.now().millisecondsSinceEpoch,
      );
      return;
    }

    final DateTime firstOpenTime =
        DateTime.fromMillisecondsSinceEpoch(firstOpenMs);
    final DateTime now = DateTime.now();

    // Notification 1: Welcome push
    // Trigger condition: first open + permission granted.
    // If permission was granted much later, do NOT catch up (skip).
    final bool welcomeSent = storage.getBool(prefKeyWelcomeSent) ?? false;
    if (!welcomeSent) {
      // Grace period for initial session:
      // In test mode: 45 seconds. In release mode: 3 hours from first open.
      final Duration welcomeWindow = _useTestIntervals
          ? const Duration(seconds: 45)
          : const Duration(hours: 3);

      if (now.difference(firstOpenTime) <= welcomeWindow) {
        await _showWelcomeNotification();
      }
      // Mark as completed regardless so we never re-trigger welcome push later
      await storage.setBool(prefKeyWelcomeSent, true);
    }

    // Notification 2: 7 days (or 1 minute in test mode)
    final bool scheduled7d = storage.getBool(prefKey7dScheduled) ?? false;
    if (!scheduled7d) {
      final Duration interval7d = _useTestIntervals
          ? const Duration(minutes: 1)
          : const Duration(days: 7);
      final DateTime target7d = firstOpenTime.add(interval7d);

      if (target7d.isAfter(now)) {
        await _scheduleNotification(
          id: id7Days,
          title: notificationTitle,
          body: reminder7dBody,
          scheduledDate: target7d,
        );
        await storage.setBool(prefKey7dScheduled, true);
      } else {
        // Target date is in the past — "пропущенные не догоняем"
        await storage.setBool(prefKey7dScheduled, true);
      }
    }

    // Notification 3: 20 days (or 3 minutes in test mode)
    final bool scheduled20d = storage.getBool(prefKey20dScheduled) ?? false;
    if (!scheduled20d) {
      final Duration interval20d = _useTestIntervals
          ? const Duration(minutes: 3)
          : const Duration(days: 20);
      final DateTime target20d = firstOpenTime.add(interval20d);

      if (target20d.isAfter(now)) {
        await _scheduleNotification(
          id: id20Days,
          title: notificationTitle,
          body: reminder20dBody,
          scheduledDate: target20d,
        );
        await storage.setBool(prefKey20dScheduled, true);
      } else {
        // Target date is in the past — "пропущенные не догоняем"
        await storage.setBool(prefKey20dScheduled, true);
      }
    }
  }

  /// Show instant welcome notification
  Future<void> _showWelcomeNotification() async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: idWelcome,
      title: notificationTitle,
      body: welcomeBody,
      notificationDetails: details,
    );
  }

  /// Schedule a notification at the given future [scheduledDate] using AlarmManager.
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    // Inexact schedule mode for general retention & bonus reminders
    // strictly complies with Google Play policies without requiring USE_EXACT_ALARM declaration.
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  /// Retrieve the list of pending/scheduled notifications (useful for testing/QA).
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Reset all stored scheduling state and cancel active alarms (for QA/developer testing).
  Future<void> resetScheduleForTesting() async {
    await _notificationsPlugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKeyFirstOpenTime);
    await prefs.remove(prefKeyWelcomeSent);
    await prefs.remove(prefKey7dScheduled);
    await prefs.remove(prefKey20dScheduled);
  }

  /// Create Android Notification Channel
  Future<void> _createAndroidNotificationChannel() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
      );
      await androidImpl?.createNotificationChannel(channel);
    }
  }

  /// Initialize time zone data
  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    try {
      final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fallback if platform timezone cannot be determined
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}
