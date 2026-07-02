import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/constant/task_notifier.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/pages/botnavpage/pomodoropage.dart';
import 'package:kinday/pages/mainpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final breakdowncontroller = TextEditingController();

  int? _userId;
  String _name = "User";
  int _currentEnergyLvl = 3;
  String _lastUpdated = "No logs yet";
  TaskCard? _suggestedTask;
  int _totalTasks = 0;
  int _completedTasksCount = 0;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    _loadHomepageData();
    TaskNotifier.taskUpdated.addListener(_loadHomepageData);
  }

  @override
  void dispose() {
    TaskNotifier.taskUpdated.removeListener(_loadHomepageData);
    breakdowncontroller.dispose();
    super.dispose();
  }

  Future<void> _loadHomepageData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final name = prefs.getString('user_name') ?? "User";

    final dbHelper = DBHelper();
    final latestEnergy = await dbHelper.getLatestEnergyForUser(userId);
    final userTasks = await dbHelper.getTasksForUser(userId);

    String lastUpdatedStr = "No logs yet";
    final logs = await dbHelper.getEnergyLogsForUser(userId);
    if (logs.isNotEmpty) {
      try {
        final dt = DateTime.parse(logs.last['timestamp'] as String);
        final minStr = dt.minute.toString().padLeft(2, '0');
        final hrStr = dt.hour.toString().padLeft(2, '0');
        lastUpdatedStr = "Last Updated $hrStr:$minStr";
      } catch (e) {
        lastUpdatedStr = "Last Updated";
      }
    }

    final activeTasks = userTasks.where((t) => !t.isCompleted).toList();
    TaskCard? suggested;
    final userEnergy = latestEnergy ?? 3;
    final filteredTasks = activeTasks
        .where((t) => t.energylvl <= userEnergy)
        .toList();

    if (filteredTasks.isNotEmpty) {
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
        final timeA = _parseTimeOfDay(a.dueTime);
        final timeB = _parseTimeOfDay(b.dueTime);
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
      suggested = filteredTasks.first;
    }

    setState(() {
      _userId = userId;
      _name = name;
      if (latestEnergy != null) {
        _currentEnergyLvl = latestEnergy;
      }
      _lastUpdated = lastUpdatedStr;
      _suggestedTask = suggested;
      _totalTasks = userTasks.length;
      _completedTasksCount = userTasks.where((t) => t.isCompleted).length;
    });
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
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

  String _getEnergyLabel(int level) {
    switch (level) {
      case 5:
        return "High";
      case 4:
        return "Mid-High";
      case 3:
        return "Medium";
      case 2:
        return "Mid-Low";
      default:
        return "Low";
    }
  }

  Future<void> _breakDownTaskWithAI() async {
    final taskTitle = breakdowncontroller.text.trim();
    if (taskTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.tr(
              "Please write what you want to do today first!",
              "Silakan tulis apa yang ingin Anda lakukan hari ini terlebih dahulu!",
            ),
          ),
        ),
      );
      return;
    }

    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            L10n.tr("AI Unavailable", "AI Tidak Tersedia"),
            style: TextStyle(
              fontFamily: "Quicksand",
              fontWeight: FontWeight.bold,
              color: AppColors.button,
            ),
          ),
          content: Text(
            L10n.tr(
              "This AI feature cannot be used yet.",
              "Fitur AI ini belum dapat digunakan untuk saat ini.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAI = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = 'Break down the task: "$taskTitle" into 3 to 5 brief, actionable subtasks. '
          'Output a JSON list of strings only. Example: ["Subtask 1", "Subtask 2"]. Do not include markdown code block formatting.';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        String cleanJson = response.text!.trim();
        if (cleanJson.startsWith("```")) {
          final match = RegExp(r'^```(?:json)?\s*(.*?)\s*```$', dotAll: true).firstMatch(cleanJson);
          if (match != null && match.groupCount >= 1) {
            cleanJson = match.group(1)!.trim();
          } else {
            if (cleanJson.startsWith("```json")) {
              cleanJson = cleanJson.substring(7);
            } else if (cleanJson.startsWith("```")) {
              cleanJson = cleanJson.substring(3);
            }
            if (cleanJson.endsWith("```")) {
              cleanJson = cleanJson.substring(0, cleanJson.length - 3);
            }
            cleanJson = cleanJson.trim();
          }
        }

        final List decodedList = jsonDecode(cleanJson);
        final List<Map<String, dynamic>> subtaskMaps = [];
        for (var subtaskTitle in decodedList) {
          if (subtaskTitle is String && subtaskTitle.trim().isNotEmpty) {
            subtaskMaps.add({
              "title": subtaskTitle.trim(),
              "isDone": false,
            });
          }
        }

        final newTask = TaskCard(
          title: taskTitle,
          description: "AI Generated Breakdown",
          energylvl: 3, // medium energy
          prioritytask: 2, // medium priority
          subtasks: subtaskMaps,
          createdAt: DateTime.now(),
        );

        final dbHelper = DBHelper();
        final insertedId = await dbHelper.insertTask(newTask, _userId ?? 1);
        newTask.id = insertedId;

        breakdowncontroller.clear();
        TaskNotifier.notify();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                L10n.tr(
                  "AI broke down and created your task successfully!",
                  "AI berhasil memecah dan membuat tugas Anda!",
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("AI error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr(
                "Failed to break down task: $e",
                "Gagal memecah tugas: $e",
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: Column(
          children: [
            // 1. Fixed Header Section (Does not scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Good Morning,", style: AppTextStyles.greeting),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Text(_name, style: AppTextStyles.username),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Text(
                          "You've done your best today!",
                          style: AppTextStyles.affirmation,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Image.asset(AppImage.mascottask, height: 120),
                ],
              ),
            ),
            // 2. Wrap the content Column in Expanded to take up remaining height
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container3(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Image.asset(
                            AppImage.iconenergy,
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Current Energy",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.button,
                                ),
                              ),
                              Text(
                                _getEnergyLabel(_currentEnergyLvl),
                                style: TextStyle(
                                  fontSize: 25,

                                  color: AppColors.button,
                                ),
                              ),
                              Text(
                                _lastUpdated,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.button,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              int tempEnergyLvl = _currentEnergyLvl;
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Text(
                                      "What's your energy level?",
                                      style: TextStyle(
                                        fontFamily: "Quicksand",
                                        color: AppColors.button,
                                      ),
                                    ),
                                    content: SingleChildScrollView(
                                      child: StatefulBuilder(
                                        builder: (context, setModalState) {
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(5, (
                                                  index,
                                                ) {
                                                  final lvl = index + 1;
                                                  final isActive =
                                                      tempEnergyLvl >= lvl;
                                                  return IconButton(
                                                    icon: Icon(
                                                      Icons.energy_savings_leaf,
                                                      color: isActive
                                                          ? AppColors.button
                                                          : Colors
                                                                .grey
                                                                .shade300,
                                                    ),
                                                    onPressed: () {
                                                      setModalState(() {
                                                        tempEnergyLvl = lvl;
                                                      });
                                                    },
                                                  );
                                                }),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (_userId != null) {
                                            await DBHelper().insertEnergyLog(
                                              _userId!,
                                              tempEnergyLvl,
                                              DateTime.now().toIso8601String(),
                                            );
                                            await _loadHomepageData();
                                          }
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.button,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "Save",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Row(
                              children: [
                                Text("Log Energy"),
                                SizedBox(width: 5),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container1(
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 10, left: 10),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.container2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                width: 1,
                                style: BorderStyle.solid,
                                color: AppColors.containerline2,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_border,
                                    size: 15,
                                    color: AppColors.normaltext,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Suggested for now",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.normaltext,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 15),

                          Row(
                            children: [
                              Image.asset(
                                AppImage.icontask,
                                height: 80,
                                width: 80,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _suggestedTask?.title ??
                                          "No Suggested Task",
                                      style: AppTextStyles.greeting,
                                      maxLines: 2,
                                    ),
                                    Text(
                                      _suggestedTask?.description ??
                                          "No description",
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: AppColors.normaltext,
                                      ),
                                    ),
                                    if (_suggestedTask != null) ...[
                                      const SizedBox(height: 8),
                                      if (_suggestedTask!.dueDate != null) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: AppColors.button,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _suggestedTask!.dueTime !=
                                                            null &&
                                                        _suggestedTask!
                                                            .dueTime!
                                                            .isNotEmpty
                                                    ? "${_suggestedTask!.dueDate!.day}/${_suggestedTask!.dueDate!.month}/${_suggestedTask!.dueDate!.year}  ${_suggestedTask!.dueTime}"
                                                    : "${_suggestedTask!.dueDate!.day}/${_suggestedTask!.dueDate!.month}/${_suggestedTask!.dueDate!.year}",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.button,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.energy_savings_leaf,
                                            size: 14,
                                            color: AppColors.button,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getEnergyLabel(
                                              _suggestedTask!.energylvl,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          PriorityIndicator(
                                            priority:
                                                _suggestedTask!.prioritytask,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 15),

                          ElevatedButton(
                            onPressed: () {
                              if (_suggestedTask != null) {
                                TaskCard.activePomodoroTask = _suggestedTask;
                                final mainState = context
                                    .findAncestorStateOfType<MainpageState>();
                                if (mainState != null) {
                                  mainState.changeTab(2);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Pomodoropage(task: _suggestedTask),
                                    ),
                                  ).then((_) {
                                    _loadHomepageData();
                                  });
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "No suggested task available.",
                                      style: TextStyle(color: AppColors.button),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.button,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Start Focus Session",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container2(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Image.asset(
                            AppImage.iconprogress,
                            height: 50,
                            width: 50,
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's progress",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.button,
                                  ),
                                ),
                                Text(
                                  "$_completedTasksCount out of $_totalTasks tasks completed",
                                  style: TextStyle(color: AppColors.normaltext),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container3(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Turn big tasks into small, doable steps",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.button,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: breakdowncontroller,
                            maxLines: 2,
                            style: const TextStyle(color: Color(0xFF5852A0)),
                            decoration: InputDecoration(
                              hintText: "Let AI break down your task",
                              hintStyle: TextStyle(color: AppColors.background),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.indigo.shade200,
                                  width: 1.5,
                                ),
                              ),

                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: _isLoadingAI
                                ? SizedBox(
                                    height: 36,
                                    width: 36,
                                    child: CircularProgressIndicator(
                                      color: AppColors.button,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : SmallButton(
                                    sign: "Break down task",
                                    warnaBox: AppColors.button,
                                    textbuttoncolor: Colors.white,
                                    leadImage: AppImage.iconsubtask,
                                    onPressed: _breakDownTaskWithAI,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
