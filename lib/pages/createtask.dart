import 'dart:convert';

import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/database/notification_helper.dart';
import 'package:kinday/pages/dummy/pleaceholderpage.dart';
import 'package:kinday/widgets/speech_mic_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final energylvlController = DropdownController();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  List<Map<String, dynamic>> subtasks = [];

  String? selectedDropdown = "Mid priority";
  DateTime? selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  int? selectedReminderMinutes;
  int selectedIndex = 0;
  String selectedEnergy = "low";
  RepeatType _repeatType = RepeatType.none;
  List<int> _selectedWeekDays = [];
  DateTime? _finishDate;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListeningTitle = false;
  bool _isListeningDesc = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    titleController.addListener(_autosaveDraft);
    descController.addListener(_autosaveDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRestoreDraft();
    });
  }

  Future<void> _autosaveDraft() async {
    if (_isRestoring) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_task_title', titleController.text);
      await prefs.setString('draft_task_desc', descController.text);
      await prefs.setString(
        'draft_task_priority',
        selectedDropdown ?? "Mid priority",
      );
      await prefs.setString('draft_task_energy', selectedEnergy);
      await prefs.setString('draft_task_subtasks', jsonEncode(subtasks));
      await prefs.setString('draft_task_repeat_type', _repeatType.name);
      await prefs.setString(
        'draft_task_selected_weekdays',
        jsonEncode(_selectedWeekDays),
      );

      if (selectedDate != null) {
        await prefs.setString(
          'draft_task_due_date',
          selectedDate!.toIso8601String(),
        );
      } else {
        await prefs.remove('draft_task_due_date');
      }

      if (_finishDate != null) {
        await prefs.setString(
          'draft_task_finish_date',
          _finishDate!.toIso8601String(),
        );
      } else {
        await prefs.remove('draft_task_finish_date');
      }

      if (selectedTime != null) {
        await prefs.setString(
          'draft_task_due_time',
          '${selectedTime!.hour}:${selectedTime!.minute}',
        );
      } else {
        await prefs.remove('draft_task_due_time');
      }

      if (selectedReminderMinutes != null) {
        await prefs.setInt('draft_task_reminder', selectedReminderMinutes!);
      } else {
        await prefs.remove('draft_task_reminder');
      }
    } catch (e) {
      debugPrint("Error autosaving draft: $e");
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_task_title');
      await prefs.remove('draft_task_desc');
      await prefs.remove('draft_task_priority');
      await prefs.remove('draft_task_due_date');
      await prefs.remove('draft_task_finish_date');
      await prefs.remove('draft_task_due_time');
      await prefs.remove('draft_task_reminder');
      await prefs.remove('draft_task_energy');
      await prefs.remove('draft_task_subtasks');
      await prefs.remove('draft_task_repeat_type');
      await prefs.remove('draft_task_selected_weekdays');
    } catch (e) {
      debugPrint("Error clearing draft: $e");
    }
  }

  Future<void> _checkAndRestoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftTitle = prefs.getString('draft_task_title');
      final draftDesc = prefs.getString('draft_task_desc');

      if ((draftTitle != null && draftTitle.isNotEmpty) ||
          (draftDesc != null && draftDesc.isNotEmpty)) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                L10n.tr("Restore Draft?", "Pulihkan Draf?"),
                style: TextStyle(
                  fontFamily: "Quicksand",
                  fontWeight: FontWeight.bold,
                  color: AppColors.button,
                ),
              ),
              content: Text(
                L10n.tr(
                  "You have an unsaved task draft. Would you like to restore it?",
                  "Anda memiliki draf tugas yang belum disimpan. Apakah Anda ingin memulihkannya?",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearDraft();
                    Navigator.pop(context);
                  },
                  child: Text(
                    L10n.tr("Discard", "Buang"),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _restoreDraftValues(prefs);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    L10n.tr("Restore", "Pulihkan"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Error checking draft: $e");
    }
  }

  void _restoreDraftValues(SharedPreferences prefs) {
    setState(() {
      _isRestoring = true;
      titleController.text = prefs.getString('draft_task_title') ?? "";
      descController.text = prefs.getString('draft_task_desc') ?? "";
      selectedDropdown =
          prefs.getString('draft_task_priority') ?? "Mid priority";
      selectedEnergy = prefs.getString('draft_task_energy') ?? "low";

      final String? subtasksJson = prefs.getString('draft_task_subtasks');
      if (subtasksJson != null && subtasksJson.isNotEmpty) {
        try {
          final List decoded = jsonDecode(subtasksJson);
          subtasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          debugPrint("Error restoring subtasks: $e");
        }
      }

      final String? repeatTypeName = prefs.getString('draft_task_repeat_type');
      if (repeatTypeName != null) {
        _repeatType = RepeatType.values.firstWhere(
          (e) => e.name == repeatTypeName,
          orElse: () => RepeatType.none,
        );
      } else {
        _repeatType = RepeatType.none;
      }

      final String? weekDaysJson = prefs.getString(
        'draft_task_selected_weekdays',
      );
      if (weekDaysJson != null && weekDaysJson.isNotEmpty) {
        try {
          final List decoded = jsonDecode(weekDaysJson);
          _selectedWeekDays = decoded.cast<int>();
        } catch (e) {
          debugPrint("Error restoring weekdays: $e");
        }
      } else {
        _selectedWeekDays = [];
      }

      final String? finishDateStr = prefs.getString('draft_task_finish_date');
      if (finishDateStr != null) {
        _finishDate = DateTime.parse(finishDateStr);
      } else {
        _finishDate = null;
      }

      final String? dueDateStr = prefs.getString('draft_task_due_date');
      if (dueDateStr != null) {
        selectedDate = DateTime.parse(dueDateStr);
      } else {
        selectedDate = null;
      }

      final String? dueTimeStr = prefs.getString('draft_task_due_time');
      if (dueTimeStr != null) {
        final parts = dueTimeStr.split(':');
        if (parts.length == 2) {
          selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } else {
        selectedTime = null;
      }

      selectedReminderMinutes = prefs.getInt('draft_task_reminder');
      _isRestoring = false;
    });
  }

  void _listenForField(TextEditingController controller, bool isTitle) async {
    final messenger = ScaffoldMessenger.of(context);

    if (isTitle ? _isListeningTitle : _isListeningDesc) {
      await _speech.stop();
      setState(() {
        if (isTitle) {
          _isListeningTitle = false;
        } else {
          _isListeningDesc = false;
        }
      });
      return;
    }

    if (isTitle && _isListeningDesc) {
      await _speech.stop();
      setState(() {
        _isListeningDesc = false;
      });
    } else if (!isTitle && _isListeningTitle) {
      await _speech.stop();
      setState(() {
        _isListeningTitle = false;
      });
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('STT status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() {
            if (isTitle) {
              _isListeningTitle = false;
            } else {
              _isListeningDesc = false;
            }
          });
        }
      },
      onError: (error) {
        debugPrint('STT error: $error');
        if (!mounted) return;
        setState(() {
          if (isTitle) {
            _isListeningTitle = false;
          } else {
            _isListeningDesc = false;
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
      setState(() {
        if (isTitle) {
          _isListeningTitle = true;
        } else {
          _isListeningDesc = true;
        }
      });

      String baseText = controller.text;
      if (baseText.isNotEmpty && !baseText.endsWith(' ')) {
        baseText += ' ';
      }

      _speech.listen(
        onResult: (val) {
          setState(() {
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

  void _sortSubtasks(String criteria) {
    setState(() {
      if (criteria == 'A-Z') {
        subtasks.sort(
          (a, b) => (a['title'] as String).toLowerCase().compareTo(
            (b['title'] as String).toLowerCase(),
          ),
        );
      } else if (criteria == 'Z-A') {
        subtasks.sort(
          (a, b) => (b['title'] as String).toLowerCase().compareTo(
            (a['title'] as String).toLowerCase(),
          ),
        );
      } else if (criteria == 'Incomplete first') {
        subtasks.sort((a, b) {
          final aDone = a['isDone'] ?? false;
          final bDone = b['isDone'] ?? false;
          if (aDone == bDone) return 0;
          return aDone ? 1 : -1;
        });
      } else if (criteria == 'Completed first') {
        subtasks.sort((a, b) {
          final aDone = a['isDone'] ?? false;
          final bDone = b['isDone'] ?? false;
          if (aDone == bDone) return 0;
          return aDone ? -1 : 1;
        });
      }
    });
    _autosaveDraft();
  }

  @override
  void dispose() {
    _speech.stop();
    titleController.removeListener(_autosaveDraft);
    descController.removeListener(_autosaveDraft);
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: SingleChildScrollView(
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
                        Text("Create New Task", style: AppTextStyles.greeting),

                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: Text(
                            "Tiny progress is still progress",
                            style: AppTextStyles.affirmation,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Image.asset(AppImage.mascotlogin, height: 120),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 20.0,
                  left: 20,
                  right: 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 20,
                              color: AppColors.containerline1,
                            ),
                            const SizedBox(width: 10),
                            const Text("What do you want to do today?"),
                          ],
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: titleController,
                          maxLines: 2,
                          style: TextStyle(color: AppColors.button),
                          decoration: InputDecoration(
                            hintText: "eg. Study for Exam",
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
                                color: AppColors.background,
                                width: 1.5,
                              ),
                            ),

                            filled: true,
                            fillColor: Colors.grey.shade100,
                            suffixIcon: SpeechMicButton(
                              isListening: _isListeningTitle,
                              onTap: () =>
                                  _listenForField(titleController, true),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: AppColors.containerline1,
                            ),
                            const SizedBox(width: 10),
                            const Text("Description (Optional)"),
                          ],
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          style: TextStyle(color: AppColors.button),
                          decoration: InputDecoration(
                            hintText: "Add details about this task...",
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
                                color: AppColors.background,
                                width: 1.5,
                              ),
                            ),

                            filled: true,
                            fillColor: Colors.grey.shade100,
                            suffixIcon: SpeechMicButton(
                              isListening: _isListeningDesc,
                              onTap: () =>
                                  _listenForField(descController, false),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SmallButton(
                          sign: "Break down task",
                          warnaBox: AppColors.background,
                          destination: Pleaceholderpage(),
                          textbuttoncolor: Colors.white,
                          leadImage: AppImage.iconsubtask,
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(
                            thickness: 1,
                            color: AppColors.background,
                          ),
                        ),

                        Row(
                          children: [
                            Image.asset(
                              AppImage.iconduedate,
                              height: 20,
                              width: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text("Due Date"),
                            const Spacer(),

                            if (selectedDate != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedDate = null;
                                    selectedTime = null;
                                    selectedReminderMinutes = null;
                                  });
                                  _autosaveDraft();
                                },
                              ),

                            ElevatedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1990),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                  _autosaveDraft();
                                }
                              },
                              label: Text(
                                selectedDate == null
                                    ? L10n.tr("Choose Date", "Pilih Tanggal")
                                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                style: TextStyle(color: AppColors.button),
                              ),
                            ),
                          ],
                        ),

                        if (selectedDate != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Divider(
                              thickness: 1,
                              color: AppColors.background,
                            ),
                          ),
                          Row(
                            children: [
                              Image.asset(
                                AppImage.iconduetime,
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text("Due Time (Opt)"),
                              const Spacer(),
                              if (selectedTime != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedTime = null;
                                    });
                                    _autosaveDraft();
                                  },
                                ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final TimeOfDay? picked =
                                      await showTimePicker(
                                        context: context,
                                        initialTime:
                                            selectedTime ?? TimeOfDay.now(),
                                      );
                                  if (picked != null) {
                                    setState(() {
                                      selectedTime = picked;
                                    });
                                    _autosaveDraft();
                                  }
                                },
                                label: Text(
                                  selectedTime == null
                                      ? L10n.tr("Choose Time", "Pilih Jam")
                                      : selectedTime!.format(context),
                                  style: TextStyle(color: AppColors.button),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Divider(
                              thickness: 1,
                              color: AppColors.background,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 20,
                                color: AppColors.button,
                              ),
                              const SizedBox(width: 10),
                              const Text("Reminder"),
                              const Spacer(),
                              DropdownButton<int?>(
                                value: selectedReminderMinutes,
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
                                  setState(() {
                                    selectedReminderMinutes = value;
                                  });
                                  _autosaveDraft();
                                },
                              ),
                            ],
                          ),
                        ],

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(
                            thickness: 1,
                            color: AppColors.background,
                          ),
                        ),

                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              color: AppColors.button,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text("Repeat"),
                            const Spacer(),
                            DropdownButton<RepeatType>(
                              value: _repeatType,
                              dropdownColor: Colors.white,
                              style: TextStyle(color: AppColors.button),
                              items: const [
                                DropdownMenuItem(
                                  value: RepeatType.none,
                                  child: Text("None"),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.daily,
                                  child: Text("Every Day"),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.selectedDays,
                                  child: Text("Every Few Days"),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.weekly,
                                  child: Text("Every Week"),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.monthly,
                                  child: Text("Every Month"),
                                ),
                                DropdownMenuItem(
                                  value: RepeatType.yearly,
                                  child: Text("Every Year"),
                                ),
                              ],
                              onChanged: (RepeatType? value) {
                                setState(() {
                                  _repeatType = value ?? RepeatType.none;
                                });
                                _autosaveDraft();
                              },
                            ),
                          ],
                        ),

                        if (_repeatType == RepeatType.selectedDays) ...[
                          const SizedBox(height: 10),
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
                                  final isSelected = _selectedWeekDays.contains(
                                    day["value"],
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedWeekDays.remove(
                                            day["value"],
                                          );
                                        } else {
                                          _selectedWeekDays.add(
                                            day["value"] as int,
                                          );
                                        }
                                      });
                                      _autosaveDraft();
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
                                        day["label"] as String,
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

                        if (_repeatType != RepeatType.none) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Divider(
                              thickness: 1,
                              color: AppColors.background,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.event_busy,
                                color: AppColors.button,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text("Finish Date (optional)"),
                              const Spacer(),
                              if (_finishDate != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _finishDate = null;
                                    });
                                    _autosaveDraft();
                                  },
                                ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _finishDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _finishDate = picked;
                                    });
                                    _autosaveDraft();
                                  }
                                },
                                label: Text(
                                  _finishDate == null
                                      ? L10n.tr("Choose Date", "Pilih Tanggal")
                                      : "${_finishDate!.day}/${_finishDate!.month}/${_finishDate!.year}",
                                  style: TextStyle(color: AppColors.button),
                                ),
                              ),
                            ],
                          ),
                        ],

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(
                            thickness: 1,
                            color: AppColors.background,
                          ),
                        ),

                        Row(
                          children: [
                            Image.asset(
                              AppImage.iconpriority,
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 10),
                            Text("Priority"),

                            Spacer(),

                            DropdownButton<String>(
                              value: selectedDropdown,
                              dropdownColor: Colors.white,

                              iconEnabledColor: Colors.black,

                              style: TextStyle(color: AppColors.button),
                              items:
                                  [
                                    "Low priority",
                                    "Mid priority",
                                    "High priority",
                                  ].map((String val) {
                                    return DropdownMenuItem(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedDropdown = value;
                                });
                                _autosaveDraft();
                              },
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(
                            thickness: 1,
                            color: AppColors.background,
                          ),
                        ),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              AppImage.iconenergylvl,
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Energy level required"),
                                  SizedBox(height: 5),
                                  CoolDropdown(
                                    controller: energylvlController,
                                    dropdownList: energylvl,
                                    defaultItem: energylvl.first,
                                    resultOptions: const ResultOptions(
                                      width: 200,
                                      render: ResultRender.all,
                                    ),
                                    dropdownOptions: const DropdownOptions(
                                      width: 200,
                                    ),
                                    onChange: (value) {
                                      setState(() {
                                        selectedEnergy = value;
                                      });
                                      _autosaveDraft();
                                    },
                                    dropdownItemOptions:
                                        const DropdownItemOptions(
                                          render: DropdownItemRender.reverse,
                                          alignment: Alignment.centerLeft,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(
                            thickness: 1,
                            color: AppColors.background,
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset(
                              AppImage.iconsubtask,
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 10),
                            Text("Subtasks"),

                            Spacer(),

                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.sort,
                                size: 20,
                                color: AppColors.button,
                              ),
                              tooltip: "Sort subtasks",
                              onSelected: _sortSubtasks,
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'A-Z',
                                      child: Text('Alphabetical (A-Z)'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Z-A',
                                      child: Text('Alphabetical (Z-A)'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Incomplete first',
                                      child: Text('Incomplete first'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Completed first',
                                      child: Text('Completed first'),
                                    ),
                                  ],
                            ),

                            TextButton.icon(
                              onPressed: _showAddSubtaskDialog,
                              icon: Icon(Icons.add),
                              label: Text("Add subtask"),
                            ),
                          ],
                        ),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.background,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: subtasks.isEmpty
                              ? Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 60,
                                      color: AppColors.normaltext,
                                    ),

                                    SizedBox(height: 12),

                                    Text(
                                      "No subtasks yet",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.normaltext,
                                      ),
                                    ),

                                    SizedBox(height: 6),

                                    Text(
                                      "Break this task down or keep it simple!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : ReorderableListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  buildDefaultDragHandles: false,
                                  itemCount: subtasks.length,
                                  onReorder: (oldIndex, newIndex) {
                                    setState(() {
                                      if (oldIndex < newIndex) {
                                        newIndex -= 1;
                                      }
                                      final item = subtasks.removeAt(oldIndex);
                                      subtasks.insert(newIndex, item);
                                    });
                                    _autosaveDraft();
                                  },
                                  itemBuilder: (context, index) {
                                    final sub = subtasks[index];
                                    return ListTile(
                                      key: ValueKey(
                                        (sub["title"] ?? "") + index.toString(),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                      leading: Checkbox(
                                        activeColor: AppColors.button,
                                        value: sub["isDone"] ?? false,
                                        onChanged: (value) {
                                          setState(() {
                                            sub["isDone"] = value;
                                          });
                                          _autosaveDraft();
                                        },
                                      ),
                                      title: Text(
                                        sub["title"] ?? "",
                                        style: TextStyle(
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
                                            ),
                                            onPressed: () {
                                              final editController =
                                                  TextEditingController(
                                                    text: sub["title"],
                                                  );
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    "Edit Subtask",
                                                  ),
                                                  content: TextField(
                                                    controller: editController,
                                                    decoration:
                                                        const InputDecoration(
                                                          hintText:
                                                              "Edit subtask title",
                                                        ),
                                                    autofocus: true,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        "Cancel",
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        final text =
                                                            editController.text
                                                                .trim();
                                                        if (text.isNotEmpty) {
                                                          setState(() {
                                                            sub["title"] = text;
                                                          });
                                                          _autosaveDraft();
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
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                subtasks.removeAt(index);
                                              });
                                              _autosaveDraft();
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
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  bottom: 50.0,
                  left: 20,
                  right: 20,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Task title cannot be empty"),
                          ),
                        );
                        return;
                      }

                      // Convert string priority to int
                      int priorityVal = 1; // Default low
                      if (selectedDropdown == "Mid priority") {
                        priorityVal = 2;
                      } else if (selectedDropdown == "High priority") {
                        priorityVal = 3;
                      }

                      // Convert string energy to int (1-5)
                      int energyVal = 1; // Default low energy
                      if (selectedEnergy == "low") {
                        energyVal = 1;
                      } else if (selectedEnergy == "midlow") {
                        energyVal = 2;
                      } else if (selectedEnergy == "mid") {
                        energyVal = 3;
                      } else if (selectedEnergy == "midhigh") {
                        energyVal = 4;
                      } else if (selectedEnergy == "high") {
                        energyVal = 5;
                      }

                      final newTask = TaskCard(
                        title: title,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        energylvl: energyVal,
                        prioritytask: priorityVal,
                        dueDate: selectedDate,
                        dueTime: selectedTime?.format(context),
                        subtasks: subtasks,
                        reminderMinutes: selectedReminderMinutes,
                        repeatType: _repeatType,
                        selectedWeekDays: _selectedWeekDays,
                        finishDate: _finishDate,
                        createdAt: DateTime.now(),
                      );

                      final navigator = Navigator.of(context);
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('user_id') ?? 1;

                      final insertedId = await DBHelper().insertTask(
                        newTask,
                        userId,
                      );
                      newTask.id = insertedId;

                      if (selectedReminderMinutes != null) {
                        await NotificationHelper().scheduleTaskNotification(
                          newTask,
                        );
                      }

                      await _clearDraft();

                      navigator.pop(); // Go back to the previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text(
                      "Save Task",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubtaskDialog() {
    TextEditingController subtaskcontroller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Subtask"),

        content: TextField(
          controller: subtaskcontroller,
          decoration: InputDecoration(hintText: "Eg. Read Chapter 1"),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              if (subtaskcontroller.text.trim().isNotEmpty) {
                setState(() {
                  subtasks.add({
                    "title": subtaskcontroller.text.trim(),
                    "isDone": false,
                  });
                });
                _autosaveDraft();
              }

              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  final List<CoolDropdownItem<String>> energylvl = [
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.elvllow, height: 25, width: 25),
      label: 'Low Energy',
      value: 'low',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.elvlmidlo, height: 25, width: 25),
      label: 'Mid-Low Energy',
      value: 'midlow',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.elvlmid, height: 25, width: 25),
      label: 'Medium Energy',
      value: 'mid',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.elvlmidhi, height: 25, width: 25),
      label: 'Mid-High Energy',
      value: 'midhigh',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.elvlhi, height: 25, width: 25),
      label: 'High Energy',
      value: 'high',
    ),
    // {'label': 'Low Energy', 'value': 'low', 'icon': Icons.water_drop},
    // {'label': 'Mid-Low Energy', 'value': 'midlow', 'icon': Icons.park},
    // {'label': 'Medium Energy', 'value': 'mid', 'icon': Icons.waves},
    // {'label': 'Mid-High Energy', 'value': 'midhigh', 'icon': Icons.coffee},
    // {'label': 'High Energy', 'value': 'high', 'icon': Icons.coffee},
  ];
}
