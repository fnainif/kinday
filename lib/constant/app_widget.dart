import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_textstyle.dart';

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
  });

  final String hint;
  final IconData icon;
  final bool pwhide;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: TextStyle(color: Color(0xFF5852A0)),
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

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    this.description,
    required this.energylvl,
    this.prioritytask = 1,
  });

  final String title;
  final String? description;
  final int energylvl;
  final int prioritytask;

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
    return Container(
      width: 200,
      height: 150,
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            description ?? "",
            style: AppTextStyles.bodytext.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Spacer(),
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

                child: Center(child: PriorityIndicator(priority: prioritytask)),
              ),
            ],
          ),
        ],
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
