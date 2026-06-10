import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/pages/botnavpage/pomodoropage.dart';
import 'package:kinday/pages/mainpage.dart';

// Gradient BG
class BgContainer extends StatelessWidget {
  const BgContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Colors.white],
        ),
      ),
      // height: double.infinity,
      // width: double.infinity,
      child: child,
    );
  }
}

// Dark Purple Button
class AccButton extends StatelessWidget {
  const AccButton({
    super.key,
    required this.sign,
    required this.warnaBox,
    required this.destination,
    this.leadImage,
    this.buttonSize = 16,
    required this.textbuttoncolor,
    this.onPressed,
  });

  final String sign;
  final Color warnaBox;
  final Color textbuttoncolor;
  final double buttonSize;
  final Widget destination;
  final String? leadImage;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: warnaBox,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadImage != null) ...[
              Image.asset(leadImage!, width: 24, height: 24),
              const SizedBox(width: 10),
            ],
            Text(
              sign,
              style: TextStyle(color: textbuttoncolor, fontSize: buttonSize),
            ),
          ],
        ),
      ),
    );
  }
}

// small button
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.sign,
    required this.warnaBox,
    required this.destination,
    this.leadImage,
    this.buttonSize = 16,
    required this.textbuttoncolor,
  });

  final String sign;
  final Color warnaBox;
  final Color textbuttoncolor;
  final double buttonSize;
  final Widget destination;
  final String? leadImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: warnaBox,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadImage != null) ...[
              Image.asset(leadImage!, width: 24, height: 24),
              const SizedBox(width: 10),
            ],
            Text(
              sign,
              style: TextStyle(color: textbuttoncolor, fontSize: buttonSize),
            ),
          ],
        ),
      ),
    );
  }
}

//form field login. register
class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.hint,
    required this.icon,
    this.pwhide = false,
    this.controller,
    this.validator,
  });

  final String hint;
  final IconData icon;
  final bool pwhide;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFF5852A0)),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Icon(icon, color: AppColors.background),
        ),
        hintText: hint,
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
          borderSide: BorderSide(color: Colors.indigo.shade200, width: 1.5),
        ),

        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      obscureText: pwhide,
      validator: validator,
    );
  }
}

// Container white
class Container1 extends StatelessWidget {
  const Container1({super.key, this.height, this.width, required this.child});

  final double? height;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10, right: 20, left: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          style: BorderStyle.solid,
          color: AppColors.background,
        ),
      ),
      height: height,
      child: child,
    );
  }
}

//container leaning blue
class Container2 extends StatelessWidget {
  const Container2({super.key, this.height, this.width, required this.child});

  final double? height;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10, right: 20, left: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.container2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          style: BorderStyle.solid,
          color: AppColors.containerline2,
        ),
      ),
      height: height,
      child: child,
    );
  }
}

//container leaning pink
class Container3 extends StatelessWidget {
  const Container3({super.key, this.height, this.width, required this.child});

  final double? height;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10, right: 20, left: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.container1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          style: BorderStyle.solid,
          color: AppColors.containerline1,
        ),
      ),
      height: height,
      child: child,
    );
  }
}

//Energy Indicator
class EnergyIndicator extends StatelessWidget {
  final int level;

  const EnergyIndicator({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            width: 12,
            height: 10,
            decoration: BoxDecoration(
              color: index < level ? AppColors.button : Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class TaskCard extends StatelessWidget {
  TaskCard({
    super.key,
    this.id,
    required this.title,
    this.description,
    required this.energylvl,
    this.prioritytask = 1,
    this.dueDate,
    this.dueTime,
    this.onTap,
    this.isCompleted = false,
    this.maxlinesdesc = 1,
    this.maxlinestitle = 2,
    List<Map<String, dynamic>>? subtasks,
  }) : subtasks = subtasks ?? [];

  static TaskCard? activePomodoroTask;

  int? id;
  String title;
  String? description;
  int energylvl;
  int prioritytask;
  DateTime? dueDate;
  String? dueTime;
  VoidCallback? onTap;
  bool isCompleted;
  int maxlinesdesc;
  int maxlinestitle;
  List<Map<String, dynamic>> subtasks;

  String get _energyLabel {
    switch (energylvl) {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        height: 240,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 1,
            style: BorderStyle.solid,
            color: AppColors.background,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (dueDate != null) ...[
                  Icon(Icons.calendar_today, size: 11, color: AppColors.button),
                  const SizedBox(width: 3),
                  Text(
                    dueTime != null && dueTime!.isNotEmpty
                        ? "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}  $dueTime"
                        : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.button,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: maxlinestitle,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              description ?? "",
              style: AppTextStyles.bodytext.copyWith(fontSize: 13),
              maxLines: maxlinesdesc,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Spacer(),

            Row(
              children: [
                Icon(
                  Icons.energy_savings_leaf,
                  size: 15,
                  color: AppColors.button,
                ),
                const SizedBox(width: 4),
                Text(_energyLabel, style: const TextStyle(fontSize: 12)),
                Spacer(),
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.button,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: PriorityIndicator(priority: prioritytask),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.button,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                ),
                onPressed: () {
                  TaskCard.activePomodoroTask = this;
                  final mainState = context.findAncestorStateOfType<MainpageState>();
                  if (mainState != null) {
                    mainState.changeTab(2);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Pomodoropage(task: this),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Start Focus",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriorityIndicator extends StatelessWidget {
  final int priority;

  const PriorityIndicator({super.key, required this.priority});

  Color flagColor() {
    switch (priority) {
      case 3:
        return Colors.red; // High
      case 2:
        return Colors.orange; // Medium
      default:
        return Colors.green; // Low
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        priority,
        (index) => Icon(Icons.flag, size: 15, color: flagColor()),
      ),
    );
  }
}

class EnergyLevel extends StatelessWidget {
  final int energy;

  const EnergyLevel({super.key, required this.energy});

  String energyConvert() {
    switch (energy) {
      case 5:
        return "High";
      case 4:
        return "Mid-High";
      case 3:
        return "Mid";
      case 2:
        return "Mid-Low";
      case 1:
        return "Low";
      default:
        return "Low";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(Icons.energy_savings_leaf), Text(energyConvert())],
    );
  }
}
