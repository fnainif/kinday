import 'package:kinday/constant/app_widget.dart';

class RepeatTaskService {
  /// Checks if a [task] should appear on a specific [targetDate].
  static bool shouldShowTaskOnDate(TaskCard task, DateTime targetDate) {
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

    // If finishDate is set and targetDay is after finishDate (comparing only dates)
    if (task.finishDate != null) {
      final finishDay = DateTime(task.finishDate!.year, task.finishDate!.month, task.finishDate!.day);
      if (targetDay.isAfter(finishDay)) {
        return false;
      }
    }

    if (task.repeatType == RepeatType.none) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, targetDay);
    }

    // For repeatable tasks, they should start appearing on or after their start date (dueDate or createdAt).
    final startDate = task.dueDate ?? task.createdAt;
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);

    if (targetDay.isBefore(startDay)) {
      return false;
    }

    switch (task.repeatType) {
      case RepeatType.daily:
        return true;
      case RepeatType.selectedDays:
        // selectedWeekDays has weekday values from DateTime (1 = Monday, ..., 7 = Sunday)
        return task.selectedWeekDays.contains(targetDay.weekday);
      case RepeatType.weekly:
        // Weekly: appears on the same weekday as start day
        return targetDay.weekday == startDay.weekday;
      case RepeatType.monthly:
        // Monthly: appears on the same day of the month as start day
        return targetDay.day == startDay.day;
      case RepeatType.yearly:
        // Yearly: appears on the same day and month as start day
        return targetDay.day == startDay.day && targetDay.month == startDay.month;
      case RepeatType.none:
        return false;
    }
  }

  static bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
