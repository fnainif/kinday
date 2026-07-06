import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/database/firebase_auth_service.dart';
import 'package:kinday/models/user_model_firebase.dart';
import 'package:kinday/models/user_model_sql.dart';
import 'package:kinday/pages/auth/login.dart';
import 'package:kinday/pages/auth/verify_email.dart';
import 'package:shared_preferences/shared_preferences.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final dbHelper = DBHelper();
    final authService = FirebaseAuthService();

    try {
      // 1. Register in Firebase Auth & Firestore
      final firebaseUser = UserModelFirebase(
        username: username,
        email: email,
        password: password,
      );
      final firebaseSuccess = await authService.registerUser(firebaseUser);

      if (firebaseSuccess) {
        // 2. Also register in SQLite to maintain local database compatibility
        final sqlUser = UserModelSql(
          username: username,
          email: email,
          password: password,
        );
        final sqlSuccess = await dbHelper.registerUser(sqlUser);

        if (sqlSuccess) {
          final registeredUser = await dbHelper.getUserByEmail(email);
          final registeredFirebaseUser = await authService.getUserByEmail(email);

          if (registeredUser != null && registeredUser.id != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', registeredUser.id!);
            await prefs.setString('user_name', registeredUser.username);
            await prefs.setString('user_email', registeredUser.email);
            
            if (registeredFirebaseUser != null && registeredFirebaseUser.uid != null) {
              await prefs.setString('user_id_firebase', registeredFirebaseUser.uid!);
            }
            
            // Do NOT set login = true yet — the user must verify their email first.

            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
                (route) => false,
              );
            }
            return;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Error fetching user after registration."),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Local database registration failed."),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration failed. Please try again."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: BgContainer(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImage.logoSplashscreen,
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  color: AppColors.button,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "name",
                                style: TextStyle(
                                  color: AppColors.button,
                                  fontFamily: "Nunito",
                                ),
                              ),
                            ],
                          ),
                          InputField(
                            hint: "your name",
                            icon: Icons.person,
                            controller: _usernameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter your name";
                              }
                              if (value.length > 10 || value.trim().isEmpty) {
                                return "Name has to be up to 10 letters";
                              }
                              return null;
                            },
                          ),
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
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
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
                            controller: _confirmPasswordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please retype your password";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords do not match!";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20),

                          AccButton(
                            sign: "Register",
                            warnaBox: AppColors.button,
                            destination: const SizedBox(),
                            textbuttoncolor: Colors.white,
                            onPressed: _handleRegister,
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
                                              const LoginPage(),
                                        ),
                                      );
                                    },
                                  style: const TextStyle(color: Colors.blue),
                                  text: " Login",
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
