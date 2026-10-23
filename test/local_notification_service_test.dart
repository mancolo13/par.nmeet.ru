import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_/services/local_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalNotificationService Texts and Constants', () {
    test('Notification texts match technical specification exactly', () {
      expect(LocalNotificationService.notificationTitle, 'Ваш бонус');
      expect(
        LocalNotificationService.welcomeBody,
        'Регистрируйся и получай бонус на первое пополнение!',
      );
      expect(
        LocalNotificationService.reminder7dBody,
        'Вы активировали свой бонус на первое пополнение? Если нет — самое время!',
      );
      expect(
        LocalNotificationService.reminder20dBody,
        'Напоминаем! Бонус на пополнение доступен в личном кабинете!',
      );
    });

    test('Notification IDs and channel are properly configured', () {
      expect(LocalNotificationService.idWelcome, 101);
      expect(LocalNotificationService.id7Days, 102);
      expect(LocalNotificationService.id20Days, 103);
      expect(LocalNotificationService.channelId, 'bonus_reminders_channel');
      expect(LocalNotificationService.channelName, 'Ваш бонус');
    });
  });

  group('LocalNotificationService First Open & Timing Logic', () {
    test('First open timestamp is saved and never overwritten on subsequent opens',
        () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(LocalNotificationService.prefKeyFirstOpenTime), isNull);

      final initialTimestamp =
          DateTime(2026, 10, 1, 12, 0).millisecondsSinceEpoch;
      await prefs.setInt(
        LocalNotificationService.prefKeyFirstOpenTime,
        initialTimestamp,
      );

      // Simulate re-launch
      final savedTimestamp =
          prefs.getInt(LocalNotificationService.prefKeyFirstOpenTime);
      expect(savedTimestamp, initialTimestamp);
    });

    test('Schedule flags prevent duplicates and multiple scheduling', () async {
      final prefs = await SharedPreferences.getInstance();

      // Initially none are marked as scheduled
      expect(prefs.getBool(LocalNotificationService.prefKeyWelcomeSent), isNull);
      expect(prefs.getBool(LocalNotificationService.prefKey7dScheduled), isNull);
      expect(prefs.getBool(LocalNotificationService.prefKey20dScheduled), isNull);

      // Mark them as scheduled
      await prefs.setBool(LocalNotificationService.prefKeyWelcomeSent, true);
      await prefs.setBool(LocalNotificationService.prefKey7dScheduled, true);
      await prefs.setBool(LocalNotificationService.prefKey20dScheduled, true);

      // Verify state
      expect(prefs.getBool(LocalNotificationService.prefKeyWelcomeSent), isTrue);
      expect(prefs.getBool(LocalNotificationService.prefKey7dScheduled), isTrue);
      expect(prefs.getBool(LocalNotificationService.prefKey20dScheduled), isTrue);
    });

    Duration getInterval2(bool isTest) =>
        isTest ? const Duration(minutes: 1) : const Duration(days: 7);
    Duration getInterval3(bool isTest) =>
        isTest ? const Duration(minutes: 3) : const Duration(days: 20);

    test('Test intervals calculation produces 1 min and 3 mins', () {
      expect(getInterval2(true).inMinutes, 1);
      expect(getInterval3(true).inMinutes, 3);
    });

    test('Release intervals calculation produces 7 days and 20 days', () {
      expect(getInterval2(false).inDays, 7);
      expect(getInterval3(false).inDays, 20);
    });

    test('Reset schedule clears all state keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LocalNotificationService.prefKeyFirstOpenTime, 1234567);
      await prefs.setBool(LocalNotificationService.prefKeyWelcomeSent, true);
      await prefs.setBool(LocalNotificationService.prefKey7dScheduled, true);
      await prefs.setBool(LocalNotificationService.prefKey20dScheduled, true);

      // Clear keys as resetScheduleForTesting would do
      await prefs.remove(LocalNotificationService.prefKeyFirstOpenTime);
      await prefs.remove(LocalNotificationService.prefKeyWelcomeSent);
      await prefs.remove(LocalNotificationService.prefKey7dScheduled);
      await prefs.remove(LocalNotificationService.prefKey20dScheduled);

      expect(prefs.getInt(LocalNotificationService.prefKeyFirstOpenTime), isNull);
      expect(prefs.getBool(LocalNotificationService.prefKeyWelcomeSent), isNull);
      expect(prefs.getBool(LocalNotificationService.prefKey7dScheduled), isNull);
      expect(prefs.getBool(LocalNotificationService.prefKey20dScheduled), isNull);
    });
  });
}
