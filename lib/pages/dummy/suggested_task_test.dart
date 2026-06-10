import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinday/constant/app_widget.dart';

void main() {
  test('Suggested Task Selection Logic Test', () {
    TimeOfDay? parseTimeOfDay(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
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
        // ignore
      }
      return null;
    }

    // Define a list of tasks matching all criteria
    final tasks = [
      TaskCard(
        title: 'Task A (Filtered Out - Energy 4)',
        energylvl: 4,
        prioritytask: 3,
        dueDate: DateTime(2026, 6, 10),
        dueTime: '9:00 AM',
      ),
      TaskCard(
        title: 'Task B (Earliest Due Date)',
        energylvl: 2,
        prioritytask: 1,
        dueDate: DateTime(2026, 6, 10),
        dueTime: '5:00 PM',
      ),
      TaskCard(
        title: 'Task C (Same Due Date, Earliest Due Time)',
        energylvl: 3,
        prioritytask: 1,
        dueDate: DateTime(2026, 6, 11),
        dueTime: '9:00 AM',
      ),
      TaskCard(
        title: 'Task D (Same Due Date, Later Due Time)',
        energylvl: 3,
        prioritytask: 3,
        dueDate: DateTime(2026, 6, 11),
        dueTime: '10:00 AM',
      ),
      TaskCard(
        title: 'Task E (Same Due Date, No Due Time, High Priority)',
        energylvl: 3,
        prioritytask: 3,
        dueDate: DateTime(2026, 6, 11),
        dueTime: null,
      ),
      TaskCard(
        title: 'Task F (Same Due Date, No Due Time, Low Priority)',
        energylvl: 3,
        prioritytask: 1,
        dueDate: DateTime(2026, 6, 11),
        dueTime: null,
      ),
      TaskCard(
        title: 'Task G (Later Due Date)',
        energylvl: 1,
        prioritytask: 3,
        dueDate: DateTime(2026, 6, 12),
        dueTime: '8:00 AM',
      ),
      TaskCard(
        title: 'Task H (No Due Date, High Priority)',
        energylvl: 3,
        prioritytask: 3,
        dueDate: null,
        dueTime: null,
      ),
      TaskCard(
        title: 'Task I (No Due Date, Low Priority)',
        energylvl: 3,
        prioritytask: 1,
        dueDate: null,
        dueTime: null,
      ),
    ];

    // Simulate user energy level 3
    final userEnergy = 3;

    // Filter: active tasks with energy level <= userEnergy
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();
    final filteredTasks = activeTasks.where((t) => t.energylvl <= userEnergy).toList();

    // Verify filtering
    expect(filteredTasks.length, 8); // Task A filtered out
    expect(filteredTasks.any((t) => t.title.contains('Task A')), isFalse);

    // Sort matching homepage.dart logic:
    filteredTasks.sort((a, b) {
      // 1. Closest due date first (ascending)
      if (a.dueDate != null && b.dueDate != null) {
        final dateCompare = a.dueDate!.compareTo(b.dueDate!);
        if (dateCompare != 0) {
          return dateCompare;
        }
      } else if (a.dueDate != null && b.dueDate == null) {
        return -1;
      } else if (a.dueDate == null && b.dueDate != null) {
        return 1;
      }

      // 2. Closest due time first (ascending)
      final timeA = parseTimeOfDay(a.dueTime);
      final timeB = parseTimeOfDay(b.dueTime);
      if (timeA != null && timeB != null) {
        final minA = timeA.hour * 60 + timeA.minute;
        final minB = timeB.hour * 60 + timeB.minute;
        final timeCompare = minA.compareTo(minB);
        if (timeCompare != 0) {
          return timeCompare;
        }
      } else if (timeA != null && timeB == null) {
        return -1;
      } else if (timeA == null && timeB != null) {
        return 1;
      }

      // 3. Highest priority first (descending)
      return b.prioritytask.compareTo(a.prioritytask);
    });

    // Verify sorted order
    expect(filteredTasks[0].title, contains('Task B'));
    expect(filteredTasks[1].title, contains('Task C'));
    expect(filteredTasks[2].title, contains('Task D'));
    expect(filteredTasks[3].title, contains('Task E'));
    expect(filteredTasks[4].title, contains('Task F'));
    expect(filteredTasks[5].title, contains('Task G'));
    expect(filteredTasks[6].title, contains('Task H'));
    expect(filteredTasks[7].title, contains('Task I'));
  });
}
