import 'package:flutter/material.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/database/notification_helper.dart';
import 'package:kinday/database/preference_handler.dart';
import 'package:kinday/pages/auth/login.dart';
import 'package:kinday/pages/mainpage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Safely initialize configurations in the background while splash is showing
    try {
      await PreferenceHandler.init();
      final notificationHelper = NotificationHelper();
      await notificationHelper.init();
    } catch (e) {
      debugPrint("Error initializing configuration/plugins: $e");
    }

    // 2. Allow splash screen to show for a brief moment
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // 3. Navigate to appropriate page
    bool isLoggedIn = false;
    try {
      isLoggedIn = PreferenceHandler.isLogin;
    } catch (e) {
      debugPrint("Failed to read login preference: $e");
    }

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Mainpage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: BgContainer(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset(AppImage.mascotlogin),
              ),
            ),
          ),

          // kIsWeb
          //     ? SizedBox(
          //         width: MediaQuery.of(context).size.width > 1000
          //             ? 500
          //             : double.infinity,
          //         child: TextField(),
          //       )
          //     : TextField(),
          // ElevatedButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => Tugas10Pendaftaran()),
          //     );
          //   },
          //   child: Text("Ke halaman login"),
          // ),
        ],
      ),
    );
  }
}
