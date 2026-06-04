import 'package:cool_dropdown/cool_dropdown.dart';
import 'package:cool_dropdown/models/cool_dropdown_item.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/pleaceholderpage.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final energylvlController = DropdownController();
  List<Map<String, dynamic>> subtasks = [];

  String? selectedDropdown;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int selectedIndex = 0;
  String selectedEnergy = "mid";

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
                            Icon(Icons.star_border),
                            SizedBox(width: 10),
                            Text("What do you want to do today?"),
                          ],
                        ),
                        SizedBox(height: 5),
                        TextFormField(
                          maxLines: 2,
                          style: TextStyle(color: Color(0xFF5852A0)),
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
                                color: Colors.indigo.shade200,
                                width: 1.5,
                              ),
                            ),

                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        SizedBox(height: 10),

                        // ElevatedButton(
                        //   onPressed: () {
                        //     print("tes task breakdown");
                        //   },
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.star_border),
                        //       SizedBox(width: 5),
                        //       Text("Break down task"),
                        //     ],
                        //   ),
                        // ),
                        SmallButton(
                          sign: "Break down task",
                          warnaBox: AppColors.background,
                          destination: Pleaceholderpage(),
                          textbuttoncolor: Colors.white,
                          leadImage: AppImage.placeholder,
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
                              AppImage.placeholder,
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 10),
                            Text("Due Date"),
                            Spacer(),

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
                              AppImage.placeholder,
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
                              AppImage.placeholder,
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
                              AppImage.placeholder,
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
                child: AccButton(
                  sign: "Save Task",
                  warnaBox: AppColors.button,
                  destination: Pleaceholderpage(),
                  textbuttoncolor: Colors.white,
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
      icon: Image.asset(AppImage.placeholder, height: 25, width: 25),
      label: 'Low Energy',
      value: 'low',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.placeholder, height: 25, width: 25),
      label: 'Mid-Low Energy',
      value: 'midlow',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.placeholder, height: 25, width: 25),
      label: 'Medium Energy',
      value: 'mid',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.placeholder, height: 25, width: 25),
      label: 'Mid-High Energy',
      value: 'midhigh',
    ),
    CoolDropdownItem<String>(
      icon: Image.asset(AppImage.placeholder, height: 25, width: 25),
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
