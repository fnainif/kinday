import 'package:flutter/foundation.dart';

class TaskNotifier {
  static final ValueNotifier<bool> taskUpdated = ValueNotifier<bool>(false);

  static void notify() {
    taskUpdated.value = !taskUpdated.value;
  }
}
