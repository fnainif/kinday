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
import 'package:kinday/pages/service/google_calendar_service.dart';
import 'package:kinday/pages/service/repeat_task_service.dart';
import 'package:kinday/widgets/calendar_event_card.dart';
import 'package:kinday/widgets/kinday_calendar_widget.dart';
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
  DateTime _calendarSelectedDate = DateTime.now();
  List<CalendarEventItem> _gcalEvents = [];
  bool _isLoadingGcal = false;

  @override
  void initState() {
    super.initState();
    _tasks = [];
    _loadTasks();
    _loadGcalEvents(_calendarSelectedDate);
    TaskNotifier.taskUpdated.addListener(_loadTasks);
  }

  @override
  void dispose() {
    TaskNotifier.taskUpdated.removeListener(_loadTasks);
    super.dispose();
  }

  Future<void> _loadGcalEvents(DateTime date) async {
    final connected = await GoogleCalendarService().isConnected();
    if (!connected) {
      if (mounted) setState(() => _gcalEvents = []);
      return;
    }
    if (mounted) setState(() => _isLoadingGcal = true);
    final events = await GoogleCalendarService().fetchEventsForDate(date);
    if (mounted) {
      setState(() {
        _gcalEvents = events;
        _isLoadingGcal = false;
      });
    }
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;

    // Check and reset repeatable tasks for new day
    await RepeatTaskService.checkAndResetDailyRepeatTasks(userId);
    final dbTasks = await DBHelper().getTasksForUser(userId);

    final latestEnergy = await DBHelper().getLatestEnergyForUser(userId);
    if (!mounted) return;
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
    int tempScheduleMode = task.repeatType == RepeatType.none ? 0 : 1;
    DateTime? tempStartDate = task.startDate ?? task.dueDate ?? task.createdAt;
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

        String localeId;
        switch (L10n.lang) {
          case 'id':
            localeId = 'id_ID';
            break;
          case 'ja':
            localeId = 'ja_JP';
            break;
          default:
            localeId = 'en_US';
        }

        speech.listen(
          listenOptions: stt.SpeechListenOptions(localeId: localeId),
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
                            L10n.tr("Edit Task Details", "Ubah Detail Tugas"),
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
                                      L10n.tr(
                                        "Are you sure you want to delete this task?",
                                        "Apakah Anda yakin ingin menghapus tugas ini?",
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          L10n.tr("Cancel", "Batal"),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          L10n.tr("Delete", "Hapus"),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
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
                          Text(
                            "Priority",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.button,
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
                      // Mode Selector: Single Task vs Repeated Task
                      CustomSlidingSegmentedControl<int>(
                        isStretch: true,
                        decoration: BoxDecoration(
                          color: AppColors.container2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 1,
                            color: AppColors.containerline2,
                          ),
                        ),
                        thumbDecoration: BoxDecoration(
                          color: AppColors.button,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        initialValue: tempScheduleMode,
                        children: {
                          0: Text(
                            L10n.tr("Single Task", "Tugas Sekali"),
                            style: TextStyle(
                              fontFamily: "Quicksand",
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: tempScheduleMode == 0
                                  ? Colors.white
                                  : AppColors.button,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          1: Text(
                            L10n.tr("Repeated Task", "Tugas Berulang"),
                            style: TextStyle(
                              fontFamily: "Quicksand",
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: tempScheduleMode == 1
                                  ? Colors.white
                                  : AppColors.button,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        },
                        onValueChanged: (val) {
                          setModalState(() {
                            tempScheduleMode = val;
                            if (val == 0) {
                              tempRepeatType = RepeatType.none;
                              tempFinishDate = null;
                              tempSelectedWeekDays = [];
                            } else {
                              if (tempRepeatType == RepeatType.none) {
                                tempRepeatType = RepeatType.daily;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      if (tempScheduleMode == 0) ...[
                        // --- SINGLE TASK FIELDS ---
                        // 1. Start Date (Tanggal Mulai)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Start Date", "Tanggal Mulai"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tempStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    tempStartDate = picked;
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                tempStartDate == null
                                    ? L10n.tr("Today", "Hari Ini")
                                    : "${tempStartDate!.day}/${tempStartDate!.month}/${tempStartDate!.year}",
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
                        const SizedBox(height: 16),
                        // 2. Due Date (Batas Waktu)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Due Date", "Batas Waktu"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
                              ),
                            ),
                            Row(
                              children: [
                                if (tempDueDate != null)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        tempDueDate = null;
                                        tempDueTime = null;
                                        tempReminderMinutes = null;
                                      });
                                    },
                                  ),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tempDueDate ?? (tempStartDate ?? DateTime.now()),
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
                          ],
                        ),
                        if (tempDueDate != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                L10n.tr("Due Time", "Waktu Tenggat"),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.button,
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
                              Text(
                                L10n.tr("Reminder", "Pengingat"),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.button,
                                ),
                              ),
                              DropdownButton<int?>(
                                value: tempReminderMinutes,
                                dropdownColor: Colors.white,
                                style: TextStyle(color: AppColors.button),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(L10n.tr("None", "Tidak Ada")),
                                  ),
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text(L10n.tr("At due time", "Pada batas waktu")),
                                  ),
                                  DropdownMenuItem(
                                    value: 5,
                                    child: Text(L10n.tr("5 minutes before", "5 menit sebelum")),
                                  ),
                                  DropdownMenuItem(
                                    value: 10,
                                    child: Text(L10n.tr("10 minutes before", "10 menit sebelum")),
                                  ),
                                  DropdownMenuItem(
                                    value: 15,
                                    child: Text(L10n.tr("15 minutes before", "15 menit sebelum")),
                                  ),
                                  DropdownMenuItem(
                                    value: 30,
                                    child: Text(L10n.tr("30 minutes before", "30 menit sebelum")),
                                  ),
                                  DropdownMenuItem(
                                    value: 60,
                                    child: Text(L10n.tr("1 hour before", "1 jam sebelum")),
                                  ),
                                  DropdownMenuItem(
                                    value: 1440,
                                    child: Text(L10n.tr("1 day before", "1 hari sebelum")),
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
                      ] else ...[
                        // --- REPEATED TASK FIELDS ---
                        // 1. Repeat Frequency
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Repeat", "Ulang"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
                              ),
                            ),
                            DropdownButton<RepeatType>(
                              value: tempRepeatType == RepeatType.none ? RepeatType.daily : tempRepeatType,
                              dropdownColor: Colors.white,
                              style: TextStyle(color: AppColors.button),
                              items: [
                                DropdownMenuItem(
                                  value: RepeatType.daily,
                                  child: Text(L10n.tr("Every Day", "Setiap Hari")),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.selectedDays,
                                  child: Text(L10n.tr("Every Few Days", "Setiap Beberapa Hari")),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.weekly,
                                  child: Text(L10n.tr("Every Week", "Setiap Minggu")),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.monthly,
                                  child: Text(L10n.tr("Every Month", "Setiap Bulan")),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.yearly,
                                  child: Text(L10n.tr("Every Year", "Setiap Tahun")),
                                ),
                              ],
                              onChanged: (RepeatType? value) {
                                setModalState(() {
                                  tempRepeatType = value ?? RepeatType.daily;
                                });
                              },
                            ),
                          ],
                        ),
                        if (tempRepeatType == RepeatType.selectedDays) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:
                                [
                                  {"label": "Mon", "value": DateTime.monday},
                                  {"label": "Tue", "value": DateTime.tuesday},
                                  {"label": "Wed", "value": DateTime.wednesday},
                                  {"label": "Thu", "value": DateTime.thursday},
                                  {"label": "Fri", "value": DateTime.friday},
                                  {"label": "Sat", "value": DateTime.saturday},
                                  {"label": "Sun", "value": DateTime.sunday},
                                ].map((day) {
                                  final isSelected = tempSelectedWeekDays
                                      .contains(day["value"]);
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelectedWeekDays.remove(
                                            day["value"],
                                          );
                                        } else {
                                          tempSelectedWeekDays.add(
                                            day["value"] as int,
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.button
                                            : Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        L10n.tr(day["label"] as String),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // 2. Start Date (Tanggal Mulai)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Start Date", "Tanggal Mulai"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: tempStartDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    tempStartDate = picked;
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                tempStartDate == null
                                    ? L10n.tr("Today", "Hari Ini")
                                    : "${tempStartDate!.day}/${tempStartDate!.month}/${tempStartDate!.year}",
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
                        const SizedBox(height: 16),
                        // 3. Time (Jam Pelaksanaan)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Time", "Jam"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
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
                        // 4. Finish Date (Ulang Sampai)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Finish Date", "Ulang Sampai"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
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
                                      initialDate:
                                          tempFinishDate ?? (tempStartDate ?? DateTime.now()),
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
                                        ? L10n.tr(
                                            "Choose Date",
                                            "Pilih Tanggal",
                                          )
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
                        const SizedBox(height: 16),
                        // 5. Reminder
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.tr("Reminder", "Pengingat"),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.button,
                              ),
                            ),
                            DropdownButton<int?>(
                              value: tempReminderMinutes,
                              dropdownColor: Colors.white,
                              style: TextStyle(color: AppColors.button),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(L10n.tr("None", "Tidak Ada")),
                                ),
                                DropdownMenuItem(
                                  value: 0,
                                  child: Text(L10n.tr("At task time", "Pada jam tugas")),
                                ),
                                DropdownMenuItem(
                                  value: 5,
                                  child: Text(L10n.tr("5 minutes before", "5 menit sebelum")),
                                ),
                                DropdownMenuItem(
                                  value: 10,
                                  child: Text(L10n.tr("10 minutes before", "10 menit sebelum")),
                                ),
                                DropdownMenuItem(
                                  value: 15,
                                  child: Text(L10n.tr("15 minutes before", "15 menit sebelum")),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text(L10n.tr("30 minutes before", "30 menit sebelum")),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text(L10n.tr("1 hour before", "1 jam sebelum")),
                                ),
                                DropdownMenuItem(
                                  value: 1440,
                                  child: Text(L10n.tr("1 day before", "1 hari sebelum")),
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
                      // Energy Level Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Energy Level",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.button,
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
                      Text(
                        L10n.tr("Subtasks", "Sub-tugas"),
                        style: const TextStyle(
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
                                hintText: L10n.tr("Add new subtask...", "Tambah sub-tugas baru..."),
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
                          L10n.tr("No subtasks yet", "Belum ada sub-tugas"),
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
                                key: ValueKey(
                                  (sub["title"] ?? "") + index.toString(),
                                ),
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
                                        final editController =
                                            TextEditingController(
                                              text: sub["title"],
                                            );
                                        showDialog(
                                          context: context,
                                           builder: (context) => AlertDialog(
                                            title: Text(L10n.tr("Edit Subtask", "Ubah Sub-tugas")),
                                            content: TextField(
                                              controller: editController,
                                              decoration: InputDecoration(
                                                hintText: L10n.tr("Edit subtask title", "Ubah judul sub-tugas"),
                                              ),
                                              autofocus: true,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(L10n.tr("Cancel", "Batal")),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final text = editController
                                                      .text
                                                      .trim();
                                                  if (text.isNotEmpty) {
                                                    setModalState(() {
                                                      sub["title"] = text;
                                                    });
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                child: Text(L10n.tr("Save", "Simpan")),
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
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
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
                                L10n.tr("Cancel", "Batal"),
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
                                  task.startDate = tempStartDate ?? DateTime.now();
                                  task.dueDate = tempScheduleMode == 0
                                      ? tempDueDate
                                      : (tempStartDate ?? DateTime.now());
                                  task.dueTime = tempDueTime?.format(context);
                                  task.isCompleted = tempIsCompleted;
                                  task.subtasks =
                                      tempSubtasks; // Commit subtasks
                                  task.reminderMinutes = tempReminderMinutes;
                                  task.repeatType = tempScheduleMode == 0
                                      ? RepeatType.none
                                      : (tempRepeatType == RepeatType.none
                                          ? RepeatType.daily
                                          : tempRepeatType);
                                  task.selectedWeekDays = tempScheduleMode == 0
                                      ? []
                                      : tempSelectedWeekDays;
                                  task.finishDate = tempScheduleMode == 0
                                      ? null
                                      : tempFinishDate;
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
                              child: Text(
                                L10n.tr("Save", "Simpan"),
                                style: const TextStyle(color: Colors.white),
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
        return L10n.tr("High", "Tinggi");
      case 4:
        return L10n.tr("Mid-High", "Cukup Tinggi");
      case 3:
        return L10n.tr("Mid", "Sedang");
      case 2:
        return L10n.tr("Mid-Low", "Cukup Rendah");
      default:
        return L10n.tr("Low", "Rendah");
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
                      Text(L10n.tr("Tasks", "Tugas"), style: AppTextStyles.greeting),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Text(
                          L10n.tr("Organized around your energy", "Diorganisir berdasarkan energimu"),
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
              children: {
                1: Text(
                  L10n.tr("Energy", "Energi"),
                  style: TextStyle(
                    fontFamily: "Quicksand",
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selectedTab == 1 ? Colors.white : AppColors.button,
                  ),
                ),
                2: Text(
                  L10n.tr("Due Date", "Batas Waktu"),
                  style: TextStyle(
                    fontFamily: "Quicksand",
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selectedTab == 2 ? Colors.white : AppColors.button,
                  ),
                ),
                3: Text(
                  L10n.tr("Priority", "Prioritas"),
                  style: TextStyle(
                    fontFamily: "Quicksand",
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selectedTab == 3 ? Colors.white : AppColors.button,
                  ),
                ),
                4: Text(
                  L10n.tr("Calendar", "Kalender"),
                  style: TextStyle(
                    fontFamily: "Quicksand",
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selectedTab == 4 ? Colors.white : AppColors.button,
                  ),
                ),
              },
              onValueChanged: (value) {
                setState(() {
                  selectedTab = value;
                });
                if (value == 4) {
                  _loadGcalEvents(_calendarSelectedDate);
                }
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
                  : selectedTab == 3
                  ? PriorityView(
                      tasks: _tasks,
                      onEdit: _showEditTaskBottomSheet,
                    )
                  : CalendarTabView(
                      tasks: _tasks,
                      selectedDate: _calendarSelectedDate,
                      gcalEvents: _gcalEvents,
                      isLoadingGcal: _isLoadingGcal,
                      onDateSelected: (date) {
                        setState(() {
                          _calendarSelectedDate = date;
                        });
                        _loadGcalEvents(date);
                      },
                      onEdit: _showEditTaskBottomSheet,
                      onRefreshEvents: () =>
                          _loadGcalEvents(_calendarSelectedDate),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarTabView extends StatelessWidget {
  final List<TaskCard> tasks;
  final DateTime selectedDate;
  final List<CalendarEventItem> gcalEvents;
  final bool isLoadingGcal;
  final ValueChanged<DateTime> onDateSelected;
  final Function(TaskCard) onEdit;
  final VoidCallback onRefreshEvents;

  const CalendarTabView({
    super.key,
    required this.tasks,
    required this.selectedDate,
    required this.gcalEvents,
    required this.isLoadingGcal,
    required this.onDateSelected,
    required this.onEdit,
    required this.onRefreshEvents,
  });

  @override
  Widget build(BuildContext context) {
    final dayTasks = tasks.where((t) {
      if (t.isCompleted) return false;
      return RepeatTaskService.shouldShowTaskOnDate(t, selectedDate);
    }).toList();

    final completedTasks = tasks.where((t) {
      if (!t.isCompleted) return false;
      return RepeatTaskService.shouldShowTaskOnDate(t, selectedDate);
    }).toList();

    Widget buildTaskCard(TaskCard task) {
      task.onTap = () => onEdit(task);
      return task;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        KinDayCalendarWidget(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
          tasks: tasks,
          gcalEvents: gcalEvents,
          isMonthlyMode: true,
        ),
        const SizedBox(height: 16),

        // Google Calendar Section (if any events)
        if (gcalEvents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.event_note_rounded,
                  size: 16,
                  color: Color(0xFF4285F4),
                ),
                const SizedBox(width: 6),
                Text(
                  L10n.tr("Google Calendar Events", "Agenda Google Calendar"),
                  style: const TextStyle(
                    fontFamily: "Quicksand",
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ],
            ),
          ),
          ...gcalEvents.map((e) => CalendarEventCard(
                event: e,
                onConverted: onRefreshEvents,
              )),
          const SizedBox(height: 12),
        ],

        // KinDay Tasks for Selected Date
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: AppColors.button),
              const SizedBox(width: 6),
              Text(
                "${L10n.tr("Tasks for", "Tugas")} ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                style: TextStyle(
                  fontFamily: "Quicksand",
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.button,
                ),
              ),
              const Spacer(),
              Text(
                "${dayTasks.length} ${L10n.tr("tasks", "tugas")}",
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.button.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        if (dayTasks.isEmpty && gcalEvents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/lavender_bunny/Tidakadatugas.gif",
                    height: 90,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    L10n.tr(
                      "No tasks or events on this date!",
                      "Tidak ada tugas atau agenda di tanggal ini!",
                    ),
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 12,
                      color: AppColors.normaltext.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...dayTasks.map((t) => buildTaskCard(t)),

        if (completedTasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              L10n.tr("Completed", "Selesai"),
              style: TextStyle(
                fontFamily: "Quicksand",
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.button,
              ),
            ),
          ),
          ...completedTasks.map((t) => buildTaskCard(t)),
        ],
        const SizedBox(height: 30),
      ],
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeTasks = tasks
        .where(
          (t) =>
              !t.isCompleted &&
              RepeatTaskService.shouldShowTaskOnDate(t, today),
        )
        .toList();
    final recommendedTasks = activeTasks
        .where((t) => t.energylvl <= userEnergy)
        .toList();

    recommendedTasks.sort((a, b) {
      // 1. Closest effective due date and time first (ascending)
      final dtA = RepeatTaskService.getEffectiveDueDateTime(a, referenceDate: today);
      final dtB = RepeatTaskService.getEffectiveDueDateTime(b, referenceDate: today);
      final dtCompare = dtA.compareTo(dtB);
      if (dtCompare != 0) {
        return dtCompare;
      }

      // 2. Highest priority first (descending)
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

    Widget buildEmptyState(String message) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/lavender_bunny/Tidakadatugas.gif",
                height: 100,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 12,
                  color: AppColors.normaltext.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
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
                      L10n.tr("Recommended Task", "Tugas Disarankan"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (recommendedTasks.isEmpty)
                buildEmptyState(L10n.tr("No recommended tasks", "Tidak ada tugas disarankan"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: recommendedTasks.map(buildTaskCard).toList(),
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
                      L10n.tr("Low Energy Task", "Tugas Energi Rendah"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (lowEnergyTasks.isEmpty)
                buildEmptyState(L10n.tr("No low energy tasks", "Tidak ada tugas energi rendah"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: lowEnergyTasks.map(buildTaskCard).toList(),
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
                      L10n.tr("High Focus Task", "Tugas Fokus Tinggi"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (highFocusTasks.isEmpty)
                buildEmptyState(L10n.tr("No high focus tasks", "Tidak ada tugas fokus tinggi"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: highFocusTasks.map(buildTaskCard).toList(),
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
        final next = RepeatTaskService.getNextOccurrenceDate(
          t,
          fromDate: tomorrowDate.add(const Duration(days: 1)),
        );
        return next != null;
      }
      if (t.dueDate == null) return false;
      final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return d.isAfter(tomorrowDate);
    }).toList();

    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    Widget buildTaskCard(TaskCard task) {
      task.onTap = () => onEdit(task);
      return task;
    }

    Widget buildEmptyState(String message) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/lavender_bunny/Tidakadatugas.gif",
                height: 100,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 12,
                  color: AppColors.normaltext.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
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
                      L10n.tr("Today", "Hari Ini"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (todayTasks.isEmpty)
                buildEmptyState(L10n.tr("No tasks today", "Tidak ada tugas hari ini"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: todayTasks.map(buildTaskCard).toList(),
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
                      L10n.tr("Tomorrow", "Besok"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (tomorrowTasks.isEmpty)
                buildEmptyState(L10n.tr("No tasks tomorrow", "Tidak ada tugas besok"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: tomorrowTasks.map(buildTaskCard).toList(),
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
                      L10n.tr("Upcoming", "Mendatang"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (upcomingTasks.isEmpty)
                buildEmptyState(L10n.tr("No upcoming tasks", "Tidak ada tugas mendatang"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: upcomingTasks.map(buildTaskCard).toList(),
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
                      L10n.tr("Completed", "Selesai"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (completedTasks.isEmpty)
                buildEmptyState(L10n.tr("No completed tasks", "Tidak ada tugas diselesaikan"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: completedTasks.map(buildTaskCard).toList(),
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
        .where(
          (t) =>
              !t.isCompleted &&
              (t.repeatType == RepeatType.none ||
                  RepeatTaskService.shouldShowTaskOnDate(t, DateTime.now())),
        )
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

    Widget buildEmptyState(String message) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/lavender_bunny/Tidakadatugas.gif",
                height: 100,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 12,
                  color: AppColors.normaltext.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      children: [
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      L10n.tr("High Priority Tasks", "Tugas Prioritas Tinggi"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (highPriority.isEmpty)
                buildEmptyState(L10n.tr("No high priority tasks", "Tidak ada tugas prioritas tinggi"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: highPriority.map(buildTaskCard).toList(),
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
                    const Icon(Icons.flag, color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      L10n.tr("Medium Priority Tasks", "Tugas Prioritas Sedang"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (midPriority.isEmpty)
                buildEmptyState(L10n.tr("No medium priority tasks", "Tidak ada tugas prioritas sedang"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: midPriority.map(buildTaskCard).toList(),
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
                    const Icon(Icons.flag, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      L10n.tr("Low Priority Tasks", "Tugas Prioritas Rendah"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        color: AppColors.button,
                      ),
                    ),
                  ],
                ),
              ),
              if (lowPriority.isEmpty)
                buildEmptyState(L10n.tr("No low priority tasks", "Tidak ada tugas prioritas rendah"))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: lowPriority.map(buildTaskCard).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
