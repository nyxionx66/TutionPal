import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/payment.dart';
import 'data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final DataService _dataService = DataService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        print('Notifications not supported on web platform');
        return;
      }

      // Initialize timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _isInitialized = true;
      print('Notification service initialized successfully');
    } catch (e) {
      print('Notification service initialization error: $e');
      _isInitialized = false;
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
    // Handle notification tap - navigate to fees screen, etc.
  }

  Future<void> scheduleOverduePaymentReminders() async {
    if (!_isInitialized) {
      print('Notification service not initialized');
      return;
    }

    try {
      await _dataService.initializeHive();
      final overduePayments = _dataService.getOverduePayments();
      
      if (overduePayments.isEmpty) {
        print('No overdue payments found');
        return;
      }

      // Cancel existing overdue notifications
      await _cancelOverdueNotifications();

      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      
      // Schedule reminders for 1st, 5th, 10th, 15th of next month
      final reminderDays = [1, 5, 10, 15];
      
      for (int day in reminderDays) {
        final reminderDate = DateTime(nextMonth.year, nextMonth.month, day, 9, 0); // 9 AM
        
        if (reminderDate.isAfter(now)) {
          // Convert to TZDateTime
          final tzReminderDate = tz.TZDateTime.from(reminderDate, tz.local);
          
          await _scheduleNotification(
            id: 1000 + day, // Unique ID for each reminder day
            title: 'Overdue Fees Reminder',
            body: 'You have ${overduePayments.length} overdue payment(s) totaling LKR ${overduePayments.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(0)}',
            scheduledDate: tzReminderDate,
            payload: 'overdue_fees',
          );
          
          print('Scheduled overdue reminder for ${reminderDate.day}/${reminderDate.month} at 9:00 AM');
        }
      }
    } catch (e) {
      print('Error scheduling overdue payment reminders: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'overdue_fees_channel',
        'Overdue Fees Reminders',
        channelDescription: 'Notifications for overdue tuition fees',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelOverdueNotifications() async {
    try {
      // Cancel overdue reminder notifications (IDs 1001, 1005, 1010, 1015)
      final reminderIds = [1001, 1005, 1010, 1015];
      for (int id in reminderIds) {
        await _flutterLocalNotificationsPlugin.cancel(id);
      }
      print('Cancelled existing overdue notifications');
    } catch (e) {
      print('Error cancelling overdue notifications: $e');
    }
  }

  Future<void> checkAndScheduleOverdueNotifications() async {
    if (!_isInitialized) {
      print('Notification service not initialized');
      return;
    }

    try {
      await scheduleOverduePaymentReminders();
      print('Overdue notifications checked and scheduled');
    } catch (e) {
      print('Error checking overdue notifications: $e');
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('Notification service not initialized');
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'instant_channel',
        'Instant Notifications',
        channelDescription: 'Instant notifications for app events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('Error showing instant notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }
}