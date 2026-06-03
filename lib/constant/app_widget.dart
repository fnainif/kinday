import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';

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
    return TextField(
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
        color: const Color.fromARGB(255, 236, 233, 222),
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
