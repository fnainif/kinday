import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/pleaceholderpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                  "Welcome Back",
                  style: TextStyle(
                    color: AppColors.button,
                    fontFamily: "Super",
                    fontSize: 30,
                    letterSpacing: 5,
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
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Pleaceholderpage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Forgot Password ?",
                                style: TextStyle(
                                  color: AppColors.button,
                                  fontFamily: "Nunito",
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        AccButton(
                          sign: "Sign In",
                          warnaBox: AppColors.button,
                          destination: Pleaceholderpage(),
                          textbuttoncolor: Colors.white,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 2,
                                  color: AppColors.background,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  "or continue with",
                                  style: TextStyle(
                                    color: AppColors.background,
                                    fontFamily: "Nunito",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 2,
                                  color: AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AccButton(
                              sign: "Gmail",
                              warnaBox: AppColors.background,
                              destination: Pleaceholderpage(),
                              textbuttoncolor: AppColors.button,
                              leadImage: AppImage.placeholder,
                            ),
                            AccButton(
                              sign: "Facebook",
                              warnaBox: AppColors.background,
                              destination: Pleaceholderpage(),
                              textbuttoncolor: AppColors.button,
                              leadImage: AppImage.placeholder,
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Text.rich(
                          TextSpan(
                            text: "New here ?",
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
                                text: " Create an account",
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
