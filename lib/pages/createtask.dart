import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
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

  String? selectedDropdown;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int? selectedReminderMinutes;
  int selectedIndex = 0;
  String selectedEnergy = "low";

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListeningTitle = false;
  bool _isListeningDesc = false;

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

  @override
  void dispose() {
    _speech.stop();
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
                        const Text(
                          "Create New Task",
                          style: AppTextStyles.greeting,
                        ),

                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: const Text(
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
                            const Icon(
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
                          style: const TextStyle(color: Color(0xFF5852A0)),
                          decoration: InputDecoration(
                            hintText: "eg. Study for Exam",
                            hintStyle: const TextStyle(
                              color: AppColors.background,
                            ),

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
                            const Icon(
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
                          style: const TextStyle(color: Color(0xFF5852A0)),
                          decoration: InputDecoration(
                            hintText: "Add details about this task...",
                            hintStyle: const TextStyle(
                              color: AppColors.background,
                            ),

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
                                }
                              },
                              label: Text(
                                selectedDate == null
                                    ? "Pilih Tanggal"
                                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                style: const TextStyle(color: AppColors.button),
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
                                  }
                                },
                                label: Text(
                                  selectedTime == null
                                      ? "Pilih Jam"
                                      : selectedTime!.format(context),
                                  style: const TextStyle(
                                    color: AppColors.button,
                                  ),
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
                              const Icon(
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
                                style: const TextStyle(color: AppColors.button),
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text("No reminder"),
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
                              color: Colors.deepPurple.shade100,
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
                                      color: Colors.deepPurple.shade100,
                                    ),

                                    SizedBox(height: 12),

                                    Text(
                                      "No subtasks yet",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
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
                              : Column(
                                  children: List.generate(subtasks.length, (
                                    index,
                                  ) {
                                    return CheckboxListTile(
                                      value: subtasks[index]["isDone"],

                                      onChanged: (value) {
                                        setState(() {
                                          subtasks[index]["isDone"] = value;
                                        });
                                      },

                                      title: Text(
                                        subtasks[index]["title"],
                                        style: TextStyle(
                                          decoration: subtasks[index]["isDone"]
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),

                                      secondary: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),

                                        onPressed: () {
                                          setState(() {
                                            subtasks.removeAt(index);
                                          });
                                        },
                                      ),
                                    );
                                  }),
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
