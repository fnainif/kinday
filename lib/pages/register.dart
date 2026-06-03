import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/pleaceholderpage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Image(image: AssetImage(AppImage.mascotlogin), height: 300),

                Text(
                  "Welcome",
                  style: TextStyle(
                    color: AppColors.button,
                    fontFamily: "Super",
                    fontSize: 30,
                    letterSpacing: 8,
                  ),
                ),
                Text(
                  "Let's make today manageable",
                  style: TextStyle(color: AppColors.button, letterSpacing: 2),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Username",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                              ),
                            ),
                          ],
                        ),
                        InputField(hint: "your username", icon: Icons.person),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              "Email",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                              ),
                            ),
                          ],
                        ),
                        InputField(hint: "your email", icon: Icons.email),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              "Password",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                              ),
                            ),
                          ],
                        ),
                        InputField(
                          hint: "your password",
                          icon: Icons.key,
                          pwhide: true,
                        ),

                        SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              "Password Confirmation",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                              ),
                            ),
                          ],
                        ),
                        InputField(
                          hint: "retype your password",
                          icon: Icons.key,
                          pwhide: true,
                        ),

                        SizedBox(height: 20),

                        AccButton(
                          sign: "Register",
                          warnaBox: AppColors.button,
                          destination: Pleaceholderpage(),
                          textbuttoncolor: Colors.white,
                        ),

                        SizedBox(height: 20),

                        Text.rich(
                          TextSpan(
                            text: "Already have an account?",
                            style: TextStyle(
                              color: AppColors.button,
                              fontFamily: "Nunito",
                            ),
                            children: [
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            Pleaceholderpage(),
                                      ),
                                    );
                                  },
                                style: TextStyle(color: Colors.blue),
                                text: " Login",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
