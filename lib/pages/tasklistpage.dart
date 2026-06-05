import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/datadummy.dart';

class Tasklistpage extends StatefulWidget {
  const Tasklistpage({super.key});

  @override
  State<Tasklistpage> createState() => _TasklistpageState();
}

class _TasklistpageState extends State<Tasklistpage> {
  int selectedTab = 1;
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
                        const Text("Tasks", style: AppTextStyles.greeting),

                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: const Text(
                            "Organized around your energy",
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

              if (selectedTab == 1)
                EnergyLevelView(tasks: dummydata)
              else if (selectedTab == 2)
                DueDateView(tasks: dummydata)
              else
                PriorityView(tasks: dummydata),
            ],
          ),
        ),
      ),
    );
  }
}

//Category Task berdasarkan Energy Level
class EnergyLevelView extends StatelessWidget {
  const EnergyLevelView({super.key, required this.tasks});
  final List<TaskCard> tasks;

  @override
  Widget build(BuildContext context) {
    final recommendedTasks = tasks.where((t) => t.energylvl >= 3).toList();
    final lowEnergyTasks = tasks.where((t) => t.energylvl <= 2).toList();
    final highFocusTasks = tasks.where((t) => t.energylvl >= 4).toList()
      ..sort(
        (a, b) => b.energylvl.compareTo(a.energylvl),
      ); // Sort dari energi terbesar

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.recommend, size: 20),
                    SizedBox(width: 10),
                    Text("Recommended Task", style: TextStyle(fontSize: 15)),
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
                      ...recommendedTasks,
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
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 10),
                    Text("Low Energy Task", style: TextStyle(fontSize: 15)),
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
                      ...lowEnergyTasks,
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
                    Icon(Icons.local_fire_department, size: 20),
                    SizedBox(width: 10),
                    Text("High Focus Task", style: TextStyle(fontSize: 15)),
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
                      ...highFocusTasks,
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
  const DueDateView({super.key, required this.tasks});
  final List<TaskCard> tasks;

  @override
  Widget build(BuildContext context) {
    final todayTasks = tasks.sublist(0, 4);
    final tomorrowTasks = tasks.sublist(4, 8);
    final upcomingTasks = tasks.sublist(8, 12);
    final completedTasks = tasks.sublist(12);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Icon(Icons.recommend, size: 20),
                    SizedBox(width: 10),
                    Text("Today", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: todayTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : todayTasks,
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
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 10),
                    Text("Tomorrow", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tomorrowTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : tomorrowTasks,
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
                    Icon(Icons.local_fire_department, size: 20),
                    SizedBox(width: 10),
                    Text("Upcoming", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: upcomingTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : upcomingTasks,
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
                    Icon(Icons.local_fire_department, size: 20),
                    SizedBox(width: 10),
                    Text("Completed", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: completedTasks.isEmpty
                      ? [const Text("Tidak ada tugas")]
                      : completedTasks,
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
  const PriorityView({super.key, required this.tasks});
  final List<TaskCard> tasks;

  @override
  Widget build(BuildContext context) {
    final highPriority = tasks.where((t) => t.prioritytask == 3).toList();
    final midPriority = tasks.where((t) => t.prioritytask == 2).toList();
    final lowPriority = tasks
        .where((t) => t.prioritytask == 1 || t.prioritytask == 0)
        .toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container1(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
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
                      ...highPriority,
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
                      ...midPriority,
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
                      ...lowPriority,
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
