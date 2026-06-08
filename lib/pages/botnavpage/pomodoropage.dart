import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/datadummy.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pomodoropage extends StatefulWidget {
  final TaskCard? task;
  const Pomodoropage({super.key, this.task});

  @override
  State<Pomodoropage> createState() => _PomodoropageState();
}

class _PomodoropageState extends State<Pomodoropage> {
  final AudioPlayer player = AudioPlayer();
  Timer? timer;
  bool isRunning = false;
  bool isFocusTime = true;
  int focusDuration = 25 * 60;
  int breakDuration = 5 * 60;
  late int totalSeconds;
  late int secondsRemaining;
  late TaskCard? activeTask;
  final TextEditingController _pomodoroSubtaskController =
      TextEditingController();

  String get taskName => activeTask?.title ?? "Belajar Flutter";

  double get progress {
    return secondsRemaining / totalSeconds;
  }

  String formatTime() {
    int minutes = secondsRemaining ~/ 60;
    int seconds = secondsRemaining % 60;

    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadFocusSettings();
    activeTask =
        TaskCard.activePomodoroTask ??
        widget.task ??
        (dummydata.isNotEmpty ? dummydata.first : null);
    totalSeconds = focusDuration;
    secondsRemaining = focusDuration;
  }

  Future<void> _loadFocusSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDuration = prefs.getInt('focus_duration') ?? 25;
    setState(() {
      focusDuration = savedDuration * 60;
      if (!isRunning && isFocusTime) {
        totalSeconds = focusDuration;
        secondsRemaining = focusDuration;
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pomodoroSubtaskController.dispose();
    super.dispose();
  }

  Widget _buildSubtasksSection() {
    final subtasks = activeTask?.subtasks ?? [];
    final total = subtasks.length;
    final completed = subtasks.where((sub) => sub["isDone"] == true).length;
    final progressPercent = total > 0 ? (completed / total) : 0.0;

    return StatefulBuilder(
      builder: (context, setSubtaskState) {
        return Container1(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: AppColors.button,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Subtasks",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.button,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "$completed/$total",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.button,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.button),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 15),
              // List of subtasks
              if (subtasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(
                    child: Text(
                      "No subtasks yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subtasks.length,
                  itemBuilder: (context, index) {
                    final sub = subtasks[index];
                    final isDone = sub["isDone"] ?? false;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          sub["isDone"] = !isDone;
                        });
                        // Also update state of StatefulBuilder
                        setSubtaskState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isDone
                                  ? AppColors.button
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sub["title"] ?? "",
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone ? Colors.grey : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  subtasks.removeAt(index);
                                });
                                setSubtaskState(() {});
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const Divider(height: 25),
              // Add subtask inline input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pomodoroSubtaskController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Add quick subtask...",
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.button),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _pomodoroSubtaskController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          subtasks.add({"title": text, "isDone": false});
                        });
                        setSubtaskState(() {});
                        _pomodoroSubtaskController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(taskName, style: const TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularPercentIndicator(
                      radius: 130,
                      lineWidth: 12,
                      percent: progress,

                      circularStrokeCap: CircularStrokeCap.round,

                      backgroundColor: Colors.white38,

                      progressColor: isFocusTime
                          ? AppColors.button
                          : Colors.white,
                    ),

                    isFocusTime
                        ? SpinKitRipple(size: 260, color: Colors.white24)
                        : SpinKitPouringHourGlass(
                            size: 200,
                            color: Colors.white24,
                          ),

                    Positioned(
                      top: 50,
                      child: Text(
                        isFocusTime ? "Focus Time" : "Break Time",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 75,
                      child: Text(
                        formatTime(),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 45,

                      child: GestureDetector(
                        onTap: toggleTimer,

                        child: Container(
                          width: 60,
                          height: 60,

                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,

                            boxShadow: [
                              BoxShadow(blurRadius: 10, color: Colors.black12),
                            ],
                          ),

                          child: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,

                            size: 35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Center(
                child: IconButton(
                  onPressed: resetTimer,
                  icon: const Icon(Icons.refresh),
                ),
              ),

              if (activeTask != null) ...[
                const SizedBox(height: 10),
                _buildSubtasksSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining > 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        switchMode();
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();

    setState(() {
      isRunning = false;
    });
  }

  void resumeTimer() {
    startTimer();

    setState(() {
      isRunning = true;
    });
  }

  void toggleTimer() {
    if (isRunning) {
      pauseTimer();
    } else {
      resumeTimer();
    }
  }

  void switchMode() {
    setState(() {
      isFocusTime = !isFocusTime;

      if (isFocusTime) {
        totalSeconds = focusDuration;
        secondsRemaining = focusDuration;
      } else {
        totalSeconds = breakDuration;
        secondsRemaining = breakDuration;
      }
    });
  }

  void resetTimer() {
    timer?.cancel();

    setState(() {
      isRunning = false;
      isFocusTime = true;

      totalSeconds = focusDuration;
      secondsRemaining = focusDuration;
    });
  }
}
