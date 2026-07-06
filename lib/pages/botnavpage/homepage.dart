import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/constant/task_notifier.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/database/firebase_backup_service.dart';
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

    // Trigger silent weekly auto-backup
    FirebaseBackupService().checkAndRunAutoBackup(userId);

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

    setState(() {
      _isLoadingAI = true;
    });

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.1-flash-lite',
      );

      final prompt =
          'Break down the task: "$taskTitle" into 3 to 5 brief, actionable subtasks. '
          'Output a JSON list of strings only. Example: ["Subtask 1", "Subtask 2"]. Do not include markdown code block formatting.';

      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        String cleanJson = response.text!.trim();
        if (cleanJson.startsWith("```")) {
          final match = RegExp(
            r'^```(?:json)?\s*(.*?)\s*```$',
            dotAll: true,
          ).firstMatch(cleanJson);
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
            subtaskMaps.add({"title": subtaskTitle.trim(), "isDone": false});
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Fixed Header Section (Does not scroll)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            L10n.tr("Good Morning,", "Selamat Pagi,"),
                            style: AppTextStyles.greeting,
                          ),
                          Transform.translate(
                            offset: const Offset(0, -5),
                            child: Text(
                              _name,
                              style: AppTextStyles.username.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: "Quicksand",
                                color: AppColors.button,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -2),
                            child: Text(
                              L10n.tr(
                                "You've done your best today!",
                                "Kamu telah melakukan yang terbaik hari ini!",
                              ),
                              style: AppTextStyles.affirmation,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(AppImage.mascottask, height: 120),
                  ],
                ),
              ),
              // 2. Wrap the content Column in Expanded to take up remaining height
              Column(
                children: [
                  Container3(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Image.asset(AppImage.iconenergy, height: 50, width: 50),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                L10n.tr("Current Energy", "Energi Saat Ini"),
                                style: TextStyle(
                                  fontFamily: "Quicksand",
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.button,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getEnergyLabel(_currentEnergyLvl),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.button,
                                  fontFamily: "Quicksand",
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _lastUpdated,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.button.withValues(
                                    alpha: 0.7,
                                  ),
                                  fontFamily: "Nunito",
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            int tempEnergyLvl = _currentEnergyLvl;
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  title: Text(
                                    L10n.tr(
                                      "What's your energy level?",
                                      "Berapa tingkat energimu?",
                                    ),
                                    style: TextStyle(
                                      fontFamily: "Quicksand",
                                      fontWeight: FontWeight.bold,
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
                                                  iconSize: 32,
                                                  icon: Icon(
                                                    Icons
                                                        .energy_savings_leaf_rounded,
                                                    color: isActive
                                                        ? AppColors.button
                                                        : Colors.grey.shade300,
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
                                      child: Text(
                                        L10n.tr("Cancel", "Batal"),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
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
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        L10n.tr("Save", "Simpan"),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.button,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                L10n.tr("Log Energy", "Catat"),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container1(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.container2.withValues(
                                alpha: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                width: 1,
                                color: AppColors.containerline2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.normaltext,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  L10n.tr(
                                    "Suggested for now",
                                    "Disarankan saat ini",
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.normaltext,
                                    fontFamily: "Quicksand",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                AppImage.icontask,
                                height: 64,
                                width: 64,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _suggestedTask?.title ??
                                        L10n.tr(
                                          "No Suggested Task",
                                          "Tidak Ada Tugas Disarankan",
                                        ),
                                    style: TextStyle(
                                      fontFamily: "Quicksand",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.button,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _suggestedTask?.description ??
                                        L10n.tr(
                                          "No description",
                                          "Tidak ada deskripsi",
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.normaltext.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontFamily: "Nunito",
                                    ),
                                  ),
                                  if (_suggestedTask != null) ...[
                                    const SizedBox(height: 8),
                                    if (_suggestedTask!.dueDate != null) ...[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 13,
                                            color: AppColors.button,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _suggestedTask!.dueTime != null &&
                                                      _suggestedTask!
                                                          .dueTime!
                                                          .isNotEmpty
                                                  ? "${_suggestedTask!.dueDate!.day}/${_suggestedTask!.dueDate!.month}/${_suggestedTask!.dueDate!.year}  ${_suggestedTask!.dueTime}"
                                                  : "${_suggestedTask!.dueDate!.day}/${_suggestedTask!.dueDate!.month}/${_suggestedTask!.dueDate!.year}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.button,
                                                fontFamily: "Nunito",
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
                                          Icons.energy_savings_leaf_rounded,
                                          size: 15,
                                          color: AppColors.button,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _getEnergyLabel(
                                            _suggestedTask!.energylvl,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.normaltext,
                                            fontFamily: "Nunito",
                                          ),
                                        ),
                                        const SizedBox(width: 16),
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

                        const SizedBox(height: 16),

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
                                    L10n.tr(
                                      "No suggested task available.",
                                      "Tidak ada tugas yang disarankan.",
                                    ),
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
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                L10n.tr(
                                  "Start Focus Session",
                                  "Mulai Sesi Fokus",
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container2(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              AppImage.iconprogress,
                              height: 50,
                              width: 50,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    L10n.tr(
                                      "Today's Progress",
                                      "Kemajuan Hari Ini",
                                    ),
                                    style: TextStyle(
                                      fontFamily: "Quicksand",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.button,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    L10n.tr(
                                      "$_completedTasksCount out of $_totalTasks tasks completed",
                                      "$_completedTasksCount dari $_totalTasks tugas selesai",
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.normaltext,
                                      fontFamily: "Nunito",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_totalTasks > 0) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _completedTasksCount / _totalTasks,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.button,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container3(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L10n.tr(
                            "Turn big tasks into small, doable steps",
                            "Ubah tugas besar menjadi langkah kecil yang bisa dilakukan",
                          ),
                          style: TextStyle(
                            fontFamily: "Quicksand",
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.button,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: breakdowncontroller,
                          maxLines: 2,
                          style: TextStyle(
                            color: AppColors.button,
                            fontFamily: "Nunito",
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: L10n.tr(
                              "Let AI break down your task...",
                              "Biar AI memecah tugas Anda...",
                            ),
                            hintStyle: TextStyle(
                              color: AppColors.button.withValues(alpha: 0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.button,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              : ElevatedButton.icon(
                                  onPressed: _breakDownTaskWithAI,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: Image.asset(
                                    AppImage.iconsubtask,
                                    width: 18,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    L10n.tr("Break down task", "Pecah Tugas"),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ],
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
