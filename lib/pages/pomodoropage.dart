import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class Pomodoropage extends StatefulWidget {
  const Pomodoropage({super.key});

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
  String taskName = "Belajar Flutter";

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

    totalSeconds = focusDuration;
    secondsRemaining = focusDuration;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Focus Page"),
        backgroundColor: AppColors.background,
      ),
      body: BgContainer(
        child: Center(
          child: Column(
            children: [
              Text(taskName, style: const TextStyle(fontSize: 18)),

              const SizedBox(height: 10),

              Stack(
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

              IconButton(
                onPressed: resetTimer,
                icon: const Icon(Icons.refresh),
              ),
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
