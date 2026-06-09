import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_widget.dart';

class FocusPage extends StatefulWidget {
  final TaskCard? task;
  const FocusPage({super.key, this.task});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  final CountDownController _controller = CountDownController();
  final AudioPlayer player = AudioPlayer();

  bool isPaused = false;
  bool isFocusSession = true;
  int duration = 25 * 60;
  String currentTime = "25:00";

  void switchSession() {
    setState(() {
      if (isFocusSession) {
        duration = 5 * 60; // istirahat 5 menit
      } else {
        duration = 25 * 60; // fokus 25 menit
      }

      isFocusSession = !isFocusSession;
      isPaused = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.restart(duration: duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: Center(
          child: Column(
            children: [
              Text(
                widget.task?.title ?? "((Name of the task))",
                style: const TextStyle(
                  fontFamily: "Quicksand",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.button,
                ),
              ),
              Text(
                isFocusSession ? "Focus Time" : "Break Time",
                style: const TextStyle(fontSize: 24),
              ),

              Stack(
                alignment: Alignment.center,
                children: [
                  CircularCountDownTimer(
                    duration: duration,
                    controller: _controller,
                    width: 250,
                    height: 250,
                    fillColor: isFocusSession ? Colors.red : Colors.green,
                    ringColor: Colors.grey.shade300,
                    backgroundColor: Colors.transparent,
                    strokeWidth: 12,
                    isReverse: true,
                    autoStart: true,
                    textFormat: CountdownTextFormat.MM_SS,
                    textStyle: const TextStyle(
                      fontSize: 0,
                      color: Colors.transparent,
                    ),
                    onChange: (String timeStamp) {
                      setState(() {
                        currentTime = timeStamp;
                      });
                    },
                    onComplete: switchSession,
                  ),

                  Text(
                    currentTime,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Positioned(
                    bottom: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isPaused) {
                            _controller.resume();
                          } else {
                            _controller.pause();
                          }

                          isPaused = !isPaused;
                        });
                      },
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
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
