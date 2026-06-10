import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:kinday/constant/app_widget.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize timezone
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = tzInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Could not get local timezone, defaulting to UTC: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Initialize FlutterLocalNotificationsPlugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle when notification is clicked if needed
      },
    );

    // 3. Create high importance notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kinday_task_reminders', // id
      'Task Reminders', // title
      description: 'This channel is used for task due date/time reminders.', // description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    // Android 13+ permission
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Android exact alarm permission
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    // iOS permission
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleTaskNotification(TaskCard task) async {
    if (task.id == null) return;

    // Cancel existing notification first
    await cancelTaskNotification(task.id!);

    // If task has no due date, no reminder, or is completed, return
    if (task.dueDate == null || task.reminderMinutes == null || task.isCompleted) {
      return;
    }

    // Parse time
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0); // Default to 9:00 AM
    if (task.dueTime != null && task.dueTime!.isNotEmpty) {
      final parsed = _parseTimeOfDay(task.dueTime!);
      if (parsed != null) {
        time = parsed;
      }
    }

    // Combine due date and time
    final dueDateTime = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      time.hour,
      time.minute,
    );

    // Calculate reminder time
    final reminderDateTime = dueDateTime.subtract(Duration(minutes: task.reminderMinutes!));

    // If the reminder time is in the past, don't schedule
    if (reminderDateTime.isBefore(DateTime.now())) {
      debugPrint("Reminder time is in the past ($reminderDateTime). Skipping schedule.");
      return;
    }

    // Convert to tz.TZDateTime
    final tzReminderTime = tz.TZDateTime.from(reminderDateTime, tz.local);

    // Android notification details
    final androidNotificationDetails = AndroidNotificationDetails(
      'kinday_task_reminders',
      'Task Reminders',
      channelDescription: 'This channel is used for task due date/time reminders.',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Darwin/iOS notification details
    const darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    String reminderLabel = "${task.reminderMinutes} minutes";
    if (task.reminderMinutes == 60) {
      reminderLabel = "1 hour";
    } else if (task.reminderMinutes == 1440) {
      reminderLabel = "1 day";
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id!,
      title: 'Task Due Soon: ${task.title}',
      body: 'This task is due in $reminderLabel (at ${task.dueTime ?? "9:00 AM"}).',
      scheduledDate: tzReminderTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint("Scheduled notification for task ${task.id} at $tzReminderTime");
  }

  Future<void> cancelTaskNotification(int taskId) async {
    await flutterLocalNotificationsPlugin.cancel(id: taskId);
    debugPrint("Cancelled notification for task $taskId");
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hourPart = parts[0].trim();
        final minutePart = parts[1].trim();
        int hour = int.parse(hourPart.replaceAll(RegExp(r'\D'), ''));
        int minute = int.parse(minutePart.replaceAll(RegExp(r'\D'), ''));
        if (timeStr.toLowerCase().contains('pm') && hour < 12) {
          hour += 12;
        } else if (timeStr.toLowerCase().contains('am') && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint("Error parsing TimeOfDay in NotificationHelper: $e");
    }
    return null;
  }
}
