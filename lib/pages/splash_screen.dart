import 'package:flutter/material.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
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
    await Future.delayed(Duration(seconds: 3));
    print("STATUS LOGIN:");
    print(PreferenceHandler.isLogin);
    if (!mounted) return;
    if (PreferenceHandler.isLogin) {
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
