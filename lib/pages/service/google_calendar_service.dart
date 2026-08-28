import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/tasks/v1.dart' as tasks_api;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEventItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String? calendarName;
  final bool isGoogleTask;
  final String? taskListTitle;
  bool isConvertedToTask;
  int? convertedTaskId;

  CalendarEventItem({
    required this.id,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    this.isAllDay = false,
    this.calendarName,
    this.isGoogleTask = false,
    this.taskListTitle,
    this.isConvertedToTask = false,
    this.convertedTaskId,
  });

  String get formattedTimeRange {
    if (isAllDay) return "All Day";
    final startHour = startDateTime.hour.toString().padLeft(2, '0');
    final startMin = startDateTime.minute.toString().padLeft(2, '0');
    final endHour = endDateTime.hour.toString().padLeft(2, '0');
    final endMin = endDateTime.minute.toString().padLeft(2, '0');
    return "$startHour:$startMin - $endHour:$endMin";
  }
}

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  static const String _scopeCalendarRead =
      'https://www.googleapis.com/auth/calendar.readonly';
  static const String _scopeCalendarEventsRead =
      'https://www.googleapis.com/auth/calendar.events.readonly';
  static const String _scopeTasksRead =
      'https://www.googleapis.com/auth/tasks.readonly';
  static const String _prefKeyConnected = 'is_gcal_connected';
  static const String _prefKeyConvertedEvents = 'gcal_converted_events';
  static const String _prefKeyIncludeSubCalendars = 'gcal_include_sub_calendars';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      _scopeCalendarRead,
      _scopeCalendarEventsRead,
      _scopeTasksRead,
    ],
    serverClientId:
        '397404342098-up2b9mnpe5bh87d7qkakj69kk2vdnvdu.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isMarked = prefs.getBool(_prefKeyConnected) ?? false;
    if (!isMarked) return false;

    if (_currentUser == null) {
      try {
        _currentUser = await _googleSignIn.signInSilently();
      } catch (e) {
        debugPrint("Silent sign in for Google Calendar & Tasks failed: $e");
      }
    }
    return _currentUser != null;
  }

  Future<bool> isIncludeSubCalendarsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyIncludeSubCalendars) ?? false;
  }

  Future<void> setIncludeSubCalendars(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyIncludeSubCalendars, value);
  }

  Future<String?> connect() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKeyConnected, true);
        return null; // Success
      } else {
        return "cancelled";
      }
    } catch (e) {
      debugPrint("Error connecting Google Calendar & Tasks: $e");
      return e.toString();
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint("Error disconnecting Google Calendar & Tasks: $e");
    }
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyConnected, false);
  }

  String? get userEmail => _currentUser?.email;

  void _parseAndAddEvents({
    required List<calendar.Event>? events,
    required String? calendarName,
    required Map<String, int> convertedMap,
    required List<CalendarEventItem> targetList,
    required Set<String> seenIds,
  }) {
    if (events == null) return;
    for (final event in events) {
      if (event.id == null || event.summary == null) continue;
      if (seenIds.contains(event.id)) continue;
      seenIds.add(event.id!);

      DateTime start;
      DateTime end;
      bool isAllDay = false;

      if (event.start?.dateTime != null) {
        start = event.start!.dateTime!.toLocal();
        end = event.end?.dateTime?.toLocal() ??
            start.add(const Duration(hours: 1));
      } else if (event.start?.date != null) {
        start = event.start!.date!.toLocal();
        end = event.end?.date?.toLocal() ?? start;
        isAllDay = true;
      } else {
        continue;
      }

      final isConverted = convertedMap.containsKey(event.id);
      final convertedTaskId = isConverted ? convertedMap[event.id] : null;

      targetList.add(
        CalendarEventItem(
          id: event.id!,
          title: event.summary ?? "Untitled Event",
          description: event.description,
          startDateTime: start,
          endDateTime: end,
          isAllDay: isAllDay,
          calendarName: calendarName,
          isGoogleTask: false,
          isConvertedToTask: isConverted,
          convertedTaskId: convertedTaskId,
        ),
      );
    }
  }

  Future<void> _fetchAndAddGoogleTasks({
    required tasks_api.TasksApi tasksApi,
    required DateTime date,
    required Map<String, int> convertedMap,
    required List<CalendarEventItem> targetList,
    required Set<String> seenIds,
  }) async {
    try {
      final taskListsResult = await tasksApi.tasklists.list();
      final taskLists = taskListsResult.items ?? [];
      final targetDateOnly = DateTime(date.year, date.month, date.day);

      for (final taskList in taskLists) {
        if (taskList.id == null) continue;
        try {
          final tasksResult = await tasksApi.tasks.list(
            taskList.id!,
            showCompleted: false,
            showHidden: false,
          );
          final items = tasksResult.items ?? [];
          for (final t in items) {
            if (t.id == null || t.title == null || t.title!.trim().isEmpty) {
              continue;
            }
            if (t.deleted == true || t.status == 'completed') continue;
            if (seenIds.contains(t.id)) continue;

            DateTime? taskDue;
            bool isAllDay = true;
            if (t.due != null && t.due!.isNotEmpty) {
              try {
                taskDue = DateTime.parse(t.due!).toLocal();
              } catch (_) {}
            }

            // Check if task is due on the requested date
            if (taskDue != null) {
              final dueDay = DateTime(taskDue.year, taskDue.month, taskDue.day);
              if (dueDay != targetDateOnly) {
                continue;
              }
            } else {
              // Task without explicit due date: show on today's view
              final today = DateTime.now();
              final todayDay = DateTime(today.year, today.month, today.day);
              if (targetDateOnly != todayDay) {
                continue;
              }
            }

            seenIds.add(t.id!);
            final isConverted = convertedMap.containsKey(t.id);
            final convertedTaskId = isConverted ? convertedMap[t.id] : null;

            final start = taskDue ?? DateTime(date.year, date.month, date.day, 9, 0);
            final end = start.add(const Duration(hours: 1));

            targetList.add(
              CalendarEventItem(
                id: t.id!,
                title: t.title!,
                description: t.notes,
                startDateTime: start,
                endDateTime: end,
                isAllDay: isAllDay,
                calendarName: taskList.title ?? "Google Tasks",
                isGoogleTask: true,
                taskListTitle: taskList.title,
                isConvertedToTask: isConverted,
                convertedTaskId: convertedTaskId,
              ),
            );
          }
        } catch (taskErr) {
          debugPrint("Error fetching tasks for list ${taskList.id}: $taskErr");
        }
      }
    } catch (e) {
      debugPrint("Error fetching Google Tasks lists: $e");
    }
  }

  Future<List<CalendarEventItem>> fetchEventsForDate(DateTime date) async {
    final connected = await isConnected();
    if (!connected || _currentUser == null) {
      return [];
    }

    try {
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        debugPrint("Unable to obtain authenticated client for Google Services");
        return [];
      }

      final calendarApi = calendar.CalendarApi(authClient);
      final tasksApi = tasks_api.TasksApi(authClient);
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final includeSub = await isIncludeSubCalendarsEnabled();
      final convertedMap = await _getConvertedEventsMap();
      final List<CalendarEventItem> result = [];
      final Set<String> seenEventIds = {};

      // 1. Fetch Google Calendar Events
      try {
        if (!includeSub) {
          // Fetch only primary calendar
          final eventsResult = await calendarApi.events.list(
            'primary',
            timeMin: startOfDay.toUtc(),
            timeMax: endOfDay.toUtc(),
            singleEvents: true,
            orderBy: 'startTime',
          );
          _parseAndAddEvents(
            events: eventsResult.items,
            calendarName: null,
            convertedMap: convertedMap,
            targetList: result,
            seenIds: seenEventIds,
          );
        } else {
          // Fetch from all accessible calendars in user's calendar list
          try {
            final calendarList = await calendarApi.calendarList.list();
            final calendars = calendarList.items ?? [];

            for (final cal in calendars) {
              if (cal.id == null || cal.deleted == true) continue;
              try {
                final eventsResult = await calendarApi.events.list(
                  cal.id!,
                  timeMin: startOfDay.toUtc(),
                  timeMax: endOfDay.toUtc(),
                  singleEvents: true,
                  orderBy: 'startTime',
                );
                final calName = cal.primary == true ? null : cal.summary;
                _parseAndAddEvents(
                  events: eventsResult.items,
                  calendarName: calName,
                  convertedMap: convertedMap,
                  targetList: result,
                  seenIds: seenEventIds,
                );
              } catch (calErr) {
                debugPrint("Error fetching events for calendar ${cal.id}: $calErr");
              }
            }
          } catch (listErr) {
            debugPrint("Error fetching calendar list, fallback to primary: $listErr");
            final eventsResult = await calendarApi.events.list(
              'primary',
              timeMin: startOfDay.toUtc(),
              timeMax: endOfDay.toUtc(),
              singleEvents: true,
              orderBy: 'startTime',
            );
            _parseAndAddEvents(
              events: eventsResult.items,
              calendarName: null,
              convertedMap: convertedMap,
              targetList: result,
              seenIds: seenEventIds,
            );
          }
        }
      } catch (calErr) {
        debugPrint("Error fetching Google Calendar events: $calErr");
      }

      // 2. Fetch Google Tasks
      try {
        await _fetchAndAddGoogleTasks(
          tasksApi: tasksApi,
          date: date,
          convertedMap: convertedMap,
          targetList: result,
          seenIds: seenEventIds,
        );
      } catch (tasksErr) {
        debugPrint("Error fetching Google Tasks: $tasksErr");
      }

      result.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        return a.startDateTime.compareTo(b.startDateTime);
      });
      return result;
    } catch (e) {
      debugPrint("Error fetching Google Calendar & Tasks for date $date: $e");
      return [];
    }
  }

  Future<Map<String, int>> _getConvertedEventsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKeyConvertedEvents);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final Map decoded = jsonDecode(jsonStr);
      return decoded.map((k, v) => MapEntry(k.toString(), v as int));
    } catch (e) {
      debugPrint("Error decoding converted events map: $e");
      return {};
    }
  }

  Future<void> markEventAsConverted(String eventId, int taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _getConvertedEventsMap();
    map[eventId] = taskId;
    await prefs.setString(_prefKeyConvertedEvents, jsonEncode(map));
  }

  Future<int?> getConvertedTaskId(String eventId) async {
    final map = await _getConvertedEventsMap();
    return map[eventId];
  }
}

