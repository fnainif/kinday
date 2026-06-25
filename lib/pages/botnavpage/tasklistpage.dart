import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/constant/task_notifier.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/database/notification_helper.dart';
import 'package:kinday/pages/service/repeat_task_service.dart';
import 'package:kinday/widgets/speech_mic_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class Tasklistpage extends StatefulWidget {
  const Tasklistpage({super.key});

  @override
  State<Tasklistpage> createState() => _TasklistpageState();
}

class _TasklistpageState extends State<Tasklistpage> {
  int selectedTab = 1;
  late List<TaskCard> _tasks;
  int _currentEnergyLvl = 3;

  @override
  void initState() {
    super.initState();
    _tasks = [];
    _loadTasks();
    TaskNotifier.taskUpdated.addListener(_loadTasks);
  }

  @override
  void dispose() {
    TaskNotifier.taskUpdated.removeListener(_loadTasks);
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    var dbTasks = await DBHelper().getTasksForUser(userId);
    
    // Check and reset repeatable tasks for new day
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    bool anyUpdated = false;
    
    for (var task in dbTasks) {
      if (task.repeatType != RepeatType.none) {
        final lastOccur = task.lastOccurrenceDate;
        if (lastOccur == null) {
          task.lastOccurrenceDate = now;
          await DBHelper().updateTask(task);
          anyUpdated = true;
        } else {
          final lastOccurDay = DateTime(lastOccur.year, lastOccur.month, lastOccur.day);
          if (lastOccurDay.isBefore(todayStart)) {
            task.isCompleted = false;
            for (var sub in task.subtasks) {
              sub['isDone'] = false;
              sub['isCompleted'] = false;
            }
            task.lastOccurrenceDate = now;
            await DBHelper().updateTask(task);
            anyUpdated = true;
          }
        }
      }
    }
    
    if (anyUpdated) {
      dbTasks = await DBHelper().getTasksForUser(userId);
    }

    final latestEnergy = await DBHelper().getLatestEnergyForUser(userId);
    setState(() {
      _tasks = dbTasks;
      if (latestEnergy != null) {
        _currentEnergyLvl = latestEnergy;
      }
    });
  }

  void _showEditTaskBottomSheet(TaskCard task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? "");
    int tempPriority = task.prioritytask;
    int tempEnergyLvl = task.energylvl;
    DateTime? tempDueDate = task.dueDate;
    int? tempReminderMinutes = task.reminderMinutes;
    bool tempIsCompleted = task.isCompleted;
    final List<Map<String, dynamic>> tempSubtasks = List.from(
      task.subtasks.map((e) => Map<String, dynamic>.from(e)),
    );
    final newSubtaskController = TextEditingController();
    RepeatType tempRepeatType = task.repeatType;
    List<int> tempSelectedWeekDays = List.from(task.selectedWeekDays);
    DateTime? tempFinishDate = task.finishDate;

    final stt.SpeechToText speech = stt.SpeechToText();
    bool isListeningTitle = false;
    bool isListeningDesc = false;

    void listenForField(
      TextEditingController controller,
      bool isTitle,
      StateSetter setModalState,
    ) async {
      final messenger = ScaffoldMessenger.of(context);

      if (isTitle ? isListeningTitle : isListeningDesc) {
        await speech.stop();
        setModalState(() {
          if (isTitle) {
            isListeningTitle = false;
          } else {
            isListeningDesc = false;
          }
        });
        return;
      }

      if (isTitle && isListeningDesc) {
        await speech.stop();
        setModalState(() {
          isListeningDesc = false;
        });
      } else if (!isTitle && isListeningTitle) {
        await speech.stop();
        setModalState(() {
          isListeningTitle = false;
        });
      }

      bool available = await speech.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (status == 'done' || status == 'notListening') {
            setModalState(() {
              if (isTitle) {
                isListeningTitle = false;
              } else {
                isListeningDesc = false;
              }
            });
          }
        },
        onError: (error) {
          debugPrint('STT error: $error');
          setModalState(() {
            if (isTitle) {
              isListeningTitle = false;
            } else {
              isListeningDesc = false;
            }
          });
          messenger.showSnackBar(
            SnackBar(
              content: Text("Speech recognition error: ${error.errorMsg}"),
            ),
          );
        },
      );

      if (available) {
        setModalState(() {
          if (isTitle) {
            isListeningTitle = true;
          } else {
            isListeningDesc = true;
          }
        });

        String baseText = controller.text;
        if (baseText.isNotEmpty && !baseText.endsWith(' ')) {
          baseText += ' ';
        }

        speech.listen(
          onResult: (val) {
            setModalState(() {
              if (val.recognizedWords.isNotEmpty) {
                controller.text = baseText + val.recognizedWords;
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
            });
          },
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Speech recognition is not available or permission denied",
            ),
          ),
        );
      }
    }

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
        debugPrint("Error parsing TimeOfDay: $e");
      }
      return null;
    }

    TimeOfDay? tempDueTime = parseTimeOfDay(task.dueTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Edit Task Details",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.button,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Text(
                                      L10n.tr("Delete Task", "Hapus Tugas"),
                                      style: const TextStyle(
                                        fontFamily: "Quicksand",
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    content: Text(
                                        L10n.tr("Are you sure you want to delete this task?", "Apakah Anda yakin ingin menghapus tugas ini?")),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          L10n.tr("Cancel", "Batal"),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Text(
                                          L10n.tr("Delete", "Hapus"),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirm == true) {
                                if (task.id != null) {
                                  await NotificationHelper()
                                      .cancelTaskNotification(task.id!);
                                  await DBHelper().deleteTask(task.id!);
                                }
                                await _loadTasks();
                                TaskNotifier.notify();
                                titleController.dispose();
                                descController.dispose();
                                newSubtaskController.dispose();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Color(0xFF5852A0)),
                        decoration: InputDecoration(
                          labelText: "Task Title",
                          labelStyle: TextStyle(color: AppColors.button),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.background,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: SpeechMicButton(
                            isListening: isListeningTitle,
                            onTap: () => listenForField(
                              titleController,
                              true,
                              setModalState,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: Color(0xFF5852A0)),
                        decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: TextStyle(color: AppColors.button),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.background,
                              width: 1.5,
                            ),
                          ),
                          suffixIcon: SpeechMicButton(
                            isListening: isListeningDesc,
                            onTap: () => listenForField(
                              descController,
                              false,
                              setModalState,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Priority Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Priority",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: List.generate(3, (index) {
                              final pVal = index + 1;
                              final isSelected = tempPriority == pVal;
                              Color color;
                              String label;
                              if (pVal == 3) {
                                color = Colors.red;
                                label = "High";
                              } else if (pVal == 2) {
                                color = Colors.orange;
                                label = "Mid";
                              } else {
                                color = Colors.green;
                                label = "Low";
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: color,

                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() {
                                        tempPriority = pVal;
                                      });
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Due Date Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Due Date",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempDueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  tempDueDate = picked;
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              tempDueDate == null
                                  ? L10n.tr("Choose Date", "Pilih Tanggal")
                                  : "${tempDueDate!.day}/${tempDueDate!.month}/${tempDueDate!.year}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.button,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (tempDueDate != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Due Time",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (tempDueTime != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        tempDueTime = null;
                                      });
                                    },
                                  ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          tempDueTime ?? TimeOfDay.now(),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempDueTime = picked;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    tempDueTime == null
                                        ? L10n.tr("Choose Time", "Pilih Jam")
                                        : tempDueTime!.format(context),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Reminder",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            DropdownButton<int?>(
                              value: tempReminderMinutes,
                              dropdownColor: Colors.white,
                              style: TextStyle(color: AppColors.button),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text("No reminder"),
                                ),
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text("At due time"),
                                ),
                                DropdownMenuItem(
                                  value: 5,
                                  child: Text("5 minutes before"),
                                ),
                                DropdownMenuItem(
                                  value: 10,
                                  child: Text("10 minutes before"),
                                ),
                                DropdownMenuItem(
                                  value: 15,
                                  child: Text("15 minutes before"),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text("30 minutes before"),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text("1 hour before"),
                                ),
                                DropdownMenuItem(
                                  value: 1440,
                                  child: Text("1 day before"),
                                ),
                              ],
                              onChanged: (int? value) {
                                setModalState(() {
                                  tempReminderMinutes = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Repeat configuration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Repeat",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          DropdownButton<RepeatType>(
                            value: tempRepeatType,
                            dropdownColor: Colors.white,
                            style: TextStyle(color: AppColors.button),
                            items: const [
                              DropdownMenuItem(value: RepeatType.none, child: Text("None")),
                              DropdownMenuItem(value: RepeatType.daily, child: Text("Every Day")),
                              DropdownMenuItem(value: RepeatType.selectedDays, child: Text("Every Few Days")),
                              DropdownMenuItem(value: RepeatType.weekly, child: Text("Every Week")),
                              DropdownMenuItem(value: RepeatType.monthly, child: Text("Every Month")),
                              DropdownMenuItem(value: RepeatType.yearly, child: Text("Every Year")),
                            ],
                            onChanged: (RepeatType? value) {
                              setModalState(() {
                                tempRepeatType = value ?? RepeatType.none;
                              });
                            },
                          ),
                        ],
                      ),
                      if (tempRepeatType == RepeatType.selectedDays) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            {"label": "Mon", "value": DateTime.monday},
                            {"label": "Tue", "value": DateTime.tuesday},
                            {"label": "Wed", "value": DateTime.wednesday},
                            {"label": "Thu", "value": DateTime.thursday},
                            {"label": "Fri", "value": DateTime.friday},
                            {"label": "Sat", "value": DateTime.saturday},
                            {"label": "Sun", "value": DateTime.sunday},
                          ].map((day) {
                            final isSelected = tempSelectedWeekDays.contains(day["value"]);
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    tempSelectedWeekDays.remove(day["value"]);
                                  } else {
                                    tempSelectedWeekDays.add(day["value"] as int);
                                  }
                                });
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.button : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  day["label"] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      if (tempRepeatType != RepeatType.none) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Finish Date",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (tempFinishDate != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        tempFinishDate = null;
                                      });
                                    },
                                  ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tempFinishDate ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        tempFinishDate = picked;
                                      });
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.event_busy,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    tempFinishDate == null
                                        ? L10n.tr("Choose Date", "Pilih Tanggal")
                                        : "${tempFinishDate!.day}/${tempFinishDate!.month}/${tempFinishDate!.year}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Energy Level Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Energy Level",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  final lvl = index + 1;
                                  final isActive = tempEnergyLvl >= lvl;
                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.energy_savings_leaf,
                                      color: isActive
                                          ? AppColors.button
                                          : Colors.grey.shade400,
                                      size: 28,
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
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Level: ${_getEnergyLabel(tempEnergyLvl)}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.button,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Completion Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Completed",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: tempIsCompleted,
                            activeThumbColor: AppColors.button,
                            activeTrackColor: AppColors.button,
                            onChanged: (val) {
                              setModalState(() {
                                tempIsCompleted = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Subtask Header and List
                      const Text(
                        "Subtasks",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Add new subtask inline
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: newSubtaskController,
                              style: const TextStyle(color: Color(0xFF5852A0)),
                              decoration: InputDecoration(
                                hintText: "Add new subtask...",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final text = newSubtaskController.text.trim();
                              if (text.isNotEmpty) {
                                setModalState(() {
                                  tempSubtasks.add({
                                    "title": text,
                                    "isDone": false,
                                  });
                                  newSubtaskController.clear();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.button,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (tempSubtasks.isEmpty)
                        Text(
                          "No subtasks yet",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: tempSubtasks.length,
                            onReorder: (oldIndex, newIndex) {
                              setModalState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = tempSubtasks.removeAt(oldIndex);
                                tempSubtasks.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final sub = tempSubtasks[index];
                              return ListTile(
                                key: ValueKey((sub["title"] ?? "") + index.toString()),
                                contentPadding: EdgeInsets.zero,
                                leading: Checkbox(
                                  activeColor: AppColors.button,
                                  value: sub["isDone"] ?? false,
                                  onChanged: (val) {
                                    setModalState(() {
                                      sub["isDone"] = val;
                                    });
                                  },
                                ),
                                title: Text(
                                  sub["title"] ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF5852A0),
                                    decoration: (sub["isDone"] ?? false)
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.button,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        final editController = TextEditingController(text: sub["title"]);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Edit Subtask"),
                                            content: TextField(
                                              controller: editController,
                                              decoration: const InputDecoration(hintText: "Edit subtask title"),
                                              autofocus: true,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final text = editController.text.trim();
                                                  if (text.isNotEmpty) {
                                                    setModalState(() {
                                                      sub["title"] = text;
                                                    });
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Save"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          tempSubtasks.removeAt(index);
                                        });
                                      },
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                titleController.dispose();
                                descController.dispose();
                                newSubtaskController.dispose();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.button),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(color: AppColors.button),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  task.title = titleController.text.trim();
                                  task.description = descController.text.trim();
                                  task.prioritytask = tempPriority;
                                  task.energylvl = tempEnergyLvl;
                                  task.dueDate = tempDueDate;
                                  task.dueTime = tempDueDate != null
                                      ? tempDueTime?.format(context)
                                      : null;
                                  task.isCompleted = tempIsCompleted;
                                  task.subtasks =
                                      tempSubtasks; // Commit subtasks
                                  task.reminderMinutes = tempDueDate != null
                                      ? tempReminderMinutes
                                      : null;
                                  task.repeatType = tempRepeatType;
                                  task.selectedWeekDays = tempSelectedWeekDays;
                                  task.finishDate = tempFinishDate;
                                });
                                await DBHelper().updateTask(task);
                                await _loadTasks();
                                TaskNotifier.notify();

                                // Manage Scheduled Notification
                                if (task.reminderMinutes != null &&
                                    !task.isCompleted) {
                                  await NotificationHelper()
                                      .scheduleTaskNotification(task);
                                } else {
                                  if (task.id != null) {
                                    await NotificationHelper()
                                        .cancelTaskNotification(task.id!);
                                  }
                                }

                                titleController.dispose();
                                descController.dispose();
                                newSubtaskController.dispose();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.button,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                "Save",
                                style: TextStyle(color: Colors.white),
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
          },
        );
      },
    ).whenComplete(() {
      speech.stop();
    });
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 5:
        return "High";
      case 4:
        return "Mid-High";
      case 3:
        return "Mid";
      case 2:
        return "Mid-Low";
      default:
        return "Low";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Tasks", style: AppTextStyles.greeting),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Text(
                          "Organized around your energy",
                          style: AppTextStyles.affirmation,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Image.asset(AppImage.mascotfocus, height: 120),
                ],
              ),
            ),
            CustomSlidingSegmentedControl<int>(
              isStretch: true,
              decoration: BoxDecoration(
                color: AppColors.container2,
                border: Border.all(
                  width: 1,
                  style: BorderStyle.solid,
                  color: AppColors.containerline2,
                ),
              ),
              thumbDecoration: BoxDecoration(
                color: AppColors.button,
                borderRadius: BorderRadius.circular(10),
              ),
              initialValue: selectedTab,
              children: const {
                1: Text("Energy Level"),
                2: Text("Due Date"),
                3: Text("Priority"),
              },
              onValueChanged: (value) {
                setState(() {
                  selectedTab = value;
                });
              },
            ),
            Expanded(
              child: selectedTab == 1
                  ? EnergyLevelView(
                      tasks: _tasks,
                      userEnergy: _currentEnergyLvl,
                      onEdit: _showEditTaskBottomSheet,
                    )
                  : selectedTab == 2
                  ? DueDateView(tasks: _tasks, onEdit: _showEditTaskBottomSheet)
                  : PriorityView(
                      tasks: _tasks,
                      onEdit: _showEditTaskBottomSheet,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

//Category Task berdasarkan Energy Level
class EnergyLevelView extends StatelessWidget {
  const EnergyLevelView({
    super.key,
    required this.tasks,
    required this.userEnergy,
    required this.onEdit,
  });
  final List<TaskCard> tasks;
  final int userEnergy;
  final Function(TaskCard) onEdit;

  @override
  Widget build(BuildContext context) {
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
        debugPrint("Error parsing TimeOfDay: $e");
      }
      return null;
    }

    final activeTasks = tasks
        .where((t) =>
            !t.isCompleted &&
            (t.repeatType == RepeatType.none ||
                RepeatTaskService.shouldShowTaskOnDate(t, DateTime.now())))
        .toList();
    final recommendedTasks = activeTasks
        .where((t) => t.energylvl <= userEnergy)
        .toList();

    recommendedTasks.sort((a, b) {
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

    final lowEnergyTasks = activeTasks.where((t) => t.energylvl <= 2).toList();
    final highFocusTasks = activeTasks.where((t) => t.energylvl >= 4).toList()
      ..sort(
        (a, b) => b.energylvl.compareTo(a.energylvl),
      ); // Sort dari energi terbesar

    Widget buildTaskCard(TaskCard task) {
      task.onTap = () => onEdit(task);
      return task;
    }

    return ListView(
      shrinkWrap: true,
      children: [
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.recommend, size: 20, color: AppColors.button),
                    const SizedBox(width: 10),
                    Text(
                      "Recommended Task",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (recommendedTasks.isEmpty)
                      const Text("Tidak ada tugas")
                    else
                      ...recommendedTasks.map(buildTaskCard),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 20, color: AppColors.button),
                    const SizedBox(width: 10),
                    Text(
                      "Low Energy Task",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (lowEnergyTasks.isEmpty)
                      const Text("Tidak ada tugas")
                    else
                      ...lowEnergyTasks.map(buildTaskCard),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 20,
                      color: AppColors.button,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "High Focus Task",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (highFocusTasks.isEmpty)
                      const Text("Tidak ada tugas")
                    else
                      ...highFocusTasks.map(buildTaskCard),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//Category Task berdasarkan Due Date
class DueDateView extends StatelessWidget {
  const DueDateView({super.key, required this.tasks, required this.onEdit});
  final List<TaskCard> tasks;
  final Function(TaskCard) onEdit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));

    // Non-completed tasks
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();

    final todayTasks = activeTasks.where((t) {
      return RepeatTaskService.shouldShowTaskOnDate(t, todayDate);
    }).toList();

    final tomorrowTasks = activeTasks.where((t) {
      return RepeatTaskService.shouldShowTaskOnDate(t, tomorrowDate);
    }).toList();

    final upcomingTasks = activeTasks.where((t) {
      if (t.repeatType != RepeatType.none) {
        if (t.finishDate != null) {
          final finishDay = DateTime(t.finishDate!.year, t.finishDate!.month, t.finishDate!.day);
          return finishDay.isAfter(tomorrowDate);
        }
        return true;
      }
      if (t.dueDate == null) return true;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d.isAfter(tomorrowDate);
    }).toList();

    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    Widget buildTaskCard(TaskCard task) {
      task.onTap = () => onEdit(task);
      return task;
    }

    return ListView(
      shrinkWrap: true,
      children: [
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20, color: AppColors.button),
                    const SizedBox(width: 10),
                    Text(
                      "Today",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: todayTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : todayTasks.map(buildTaskCard).toList(),
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 20, color: AppColors.button),
                    const SizedBox(width: 10),
                    Text(
                      "Tomorrow",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tomorrowTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : tomorrowTasks.map(buildTaskCard).toList(),
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.upcoming, size: 20, color: AppColors.button),
                    const SizedBox(width: 10),
                    Text(
                      "Upcoming",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: upcomingTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : upcomingTasks.map(buildTaskCard).toList(),
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.button,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Completed",
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: completedTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : completedTasks.map(buildTaskCard).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//Category Task berdasarkan priority
class PriorityView extends StatelessWidget {
  const PriorityView({super.key, required this.tasks, required this.onEdit});
  final List<TaskCard> tasks;
  final Function(TaskCard) onEdit;

  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks
        .where((t) =>
            !t.isCompleted &&
            (t.repeatType == RepeatType.none ||
                RepeatTaskService.shouldShowTaskOnDate(t, DateTime.now())))
        .toList();
    final highPriority = activeTasks.where((t) => t.prioritytask == 3).toList();
    final midPriority = activeTasks.where((t) => t.prioritytask == 2).toList();
    final lowPriority = activeTasks
        .where((t) => t.prioritytask == 1 || t.prioritytask == 0)
        .toList();

    Widget buildTaskCard(TaskCard task) {
      task.onTap = () => onEdit(task);
      return task;
    }

    return ListView(
      shrinkWrap: true,
      children: [
        Container1(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("High Priority Tasks", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (highPriority.isEmpty)
                      const Text("Tidak ada tugas")
                    else
                      ...highPriority.map(buildTaskCard),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Medium Priority Tasks",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (midPriority.isEmpty)
                      const Text("Tidak ada tugas")
                    else
                      ...midPriority.map(buildTaskCard),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container1(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text("Low Priority Task", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (lowPriority.isEmpty)
                      const Text("Tidak ada tugas")
                    else
                      ...lowPriority.map(buildTaskCard),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
