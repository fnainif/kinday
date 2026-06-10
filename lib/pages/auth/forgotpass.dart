import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/models/user_model_sql.dart';
import 'package:kinday/pages/auth/login.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEmailVerified = false;
  UserModelSql? _verifiedUser;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final dbHelper = DBHelper();

    try {
      final user = await dbHelper.getUserByEmail(email);

      if (user != null) {
        setState(() {
          _isEmailVerified = true;
          _verifiedUser = user;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email verified. Please set your new password."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No account found with this email address."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error checking email: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_verifiedUser == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final newPassword = _passwordController.text;
    final dbHelper = DBHelper();

    final updatedUser = UserModelSql(
      id: _verifiedUser!.id,
      username: _verifiedUser!.username,
      email: _verifiedUser!.email,
      password: newPassword,
    );

    try {
      final success = await dbHelper.updateUser(updatedUser);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password updated successfully! Please login."),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to update password. Please try again."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating password: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                const SizedBox(height: 20),
                Image(image: AssetImage(AppImage.mascotlogin), height: 280),
                Text(
                  "Reset Password",
                  style: TextStyle(
                    color: AppColors.button,
                    fontFamily: "Super",
                    fontSize: 28,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  _isEmailVerified
                      ? "Create a secure new password"
                      : "Find your Kinday account",
                  style: TextStyle(
                    color: AppColors.button.withAlpha(204),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(35.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isEmailVerified) ...[
                            Text(
                              "Email Address",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InputField(
                              hint: "Enter your email",
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
                            const SizedBox(height: 30),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.button,
                                      ),
                                    ),
                                  )
                                : AccButton(
                                    sign: "Verify Email",
                                    warnaBox: AppColors.button,
                                    destination: const LoginPage(),
                                    textbuttoncolor: Colors.white,
                                    onPressed: _verifyEmail,
                                  ),
                          ] else ...[
                            Text(
                              "New Password",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InputField(
                              hint: "Minimum 6 characters",
                              icon: Icons.key,
                              pwhide: true,
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your new password";
                                }
                                if (value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Confirm New Password",
                              style: TextStyle(
                                color: AppColors.button,
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InputField(
                              hint: "Retype new password",
                              icon: Icons.key_off,
                              pwhide: true,
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please confirm your new password";
                                }
                                if (value != _passwordController.text) {
                                  return "Passwords do not match!";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.button,
                                      ),
                                    ),
                                  )
                                : AccButton(
                                    sign: "Reset Password",
                                    warnaBox: AppColors.button,
                                    destination: const LoginPage(),
                                    textbuttoncolor: Colors.white,
                                    onPressed: _resetPassword,
                                  ),
                          ],
                          const SizedBox(height: 25),
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: "Remembered your password? ",
                                style: TextStyle(
                                  color: AppColors.button,
                                  fontFamily: "Nunito",
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    text: "Login",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
