import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/database/preference_handler.dart';
import 'package:kinday/database/notification_helper.dart';
import 'package:kinday/pages/auth/forgotpass.dart';
import 'package:kinday/pages/auth/register.dart';
import 'package:kinday/pages/dummy/pleaceholderpage.dart';
import 'package:kinday/pages/mainpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHelper().requestPermissions();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final dbHelper = DBHelper();
    final user = await dbHelper.loginUser(email, password);

    if (user != null && user.id != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id!);
      await prefs.setString('user_name', user.username);
      await prefs.setString('user_email', user.email);
      await PreferenceHandler.setLogin(true);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Login successful!")));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Mainpage()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password.")),
        );
      }
    }
  }

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
                    child: Form(
                      key: _formKey,
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
                          InputField(
                            hint: "your email",
                            icon: Icons.email,
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter your email";
                              }
                              final emailRegex = RegExp(
                                r'^[^@]+@[^@]+\.[^@]+$',
                              );
                              if (!emailRegex.hasMatch(value.trim())) {
                                return "Please enter a valid email address";
                              }
                              return null;
                            },
                          ),
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
                            controller: _passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your password";
                              }
                              return null;
                            },
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordPage(),
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
                            destination: const Pleaceholderpage(),
                            textbuttoncolor: Colors.white,
                            onPressed: _handleLogin,
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
                                sign: "Google",
                                warnaBox: AppColors.background,
                                destination: const Pleaceholderpage(),
                                textbuttoncolor: AppColors.button,
                                leadImage: AppImage.icongoogle,
                              ),
                              AccButton(
                                sign: "Facebook",
                                warnaBox: AppColors.background,
                                destination: const Pleaceholderpage(),
                                textbuttoncolor: AppColors.button,
                                leadImage: AppImage.iconfacebook,
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
                                              const RegisterPage(),
                                        ),
                                      );
                                    },
                                  style: const TextStyle(color: Colors.blue),
                                  text: " Create an account",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
