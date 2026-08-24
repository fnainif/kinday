import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEventItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isAllDay;
  final String? calendarName;
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
  static const String _prefKeyConnected = 'is_gcal_connected';
  static const String _prefKeyConvertedEvents = 'gcal_converted_events';
  static const String _prefKeyIncludeSubCalendars = 'gcal_include_sub_calendars';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', _scopeCalendarRead, _scopeCalendarEventsRead],
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
        debugPrint("Silent sign in for Google Calendar failed: $e");
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
      debugPrint("Error connecting Google Calendar: $e");
      return e.toString();
    }
  }

  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint("Error disconnecting Google Calendar: $e");
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
        start = event.start!.date!;
        end = event.end?.date ?? start;
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
          isConvertedToTask: isConverted,
          convertedTaskId: convertedTaskId,
        ),
      );
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
        debugPrint("Unable to obtain authenticated client for Google Calendar");
        return [];
      }

      final calendarApi = calendar.CalendarApi(authClient);
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final includeSub = await isIncludeSubCalendarsEnabled();
      final convertedMap = await _getConvertedEventsMap();
      final List<CalendarEventItem> result = [];
      final Set<String> seenEventIds = {};

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

      result.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      return result;
    } catch (e) {
      debugPrint("Error fetching Google Calendar events for date $date: $e");
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
