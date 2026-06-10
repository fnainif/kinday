import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/pages/botnavpage/energylog.dart';
import 'package:kinday/pages/botnavpage/homepage.dart';
import 'package:kinday/pages/botnavpage/pomodoropage.dart';
import 'package:kinday/pages/botnavpage/setting_profile.dart';
import 'package:kinday/pages/botnavpage/tasklistpage.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => MainpageState();
}

class MainpageState extends State<Mainpage> {
  int selectedIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  void changeTab(int index) {
    setState(() {
      selectedIndex = index;
    });
    final CurvedNavigationBarState? navBarState = _bottomNavigationKey.currentState;
    navBarState?.setPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Homepage(),
      Tasklistpage(),
      Pomodoropage(),
      EnergyPage(),
      SettingProfile(),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: selectedIndex,
        backgroundColor: AppColors.button,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: AppColors.button),
          Icon(Icons.task_alt, size: 30, color: AppColors.button),
          Icon(Icons.timer, size: 30, color: AppColors.button),
          Icon(Icons.electric_bolt_rounded, size: 30, color: AppColors.button),
          Icon(Icons.person, size: 30, color: AppColors.button),
        ],
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
