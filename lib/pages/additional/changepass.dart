import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/models/user_model_sql.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kinday/database/firebase_auth_service.dart';

class ChangePassPage extends StatefulWidget {
  const ChangePassPage({super.key});

  @override
  State<ChangePassPage> createState() => _ChangePassPageState();
}

class _ChangePassPageState extends State<ChangePassPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      
      if (email == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.tr("User session not found.", "Sesi pengguna tidak ditemukan.")),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final dbHelper = DBHelper();
      final user = await dbHelper.getUserByEmail(email);

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.tr("User account not found.", "Akun pengguna tidak ditemukan.")),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // 1. Change password in Firebase (reauthenticates & updates Auth & Firestore)
      final firebaseSuccess = await FirebaseAuthService().changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (firebaseSuccess) {
        // 2. Sync password change to SQLite
        final updatedUser = UserModelSql(
          id: user.id,
          username: user.username,
          email: user.email,
          password: _newPasswordController.text,
        );

        final success = await dbHelper.updateUser(updatedUser);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10n.tr("Password updated successfully!", "Kata sandi berhasil diperbarui!")),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10n.tr("Failed to sync SQLite password.", "Gagal menyinkronkan kata sandi SQLite.")),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.tr("Failed to update password in Firebase.", "Gagal memperbarui kata sandi di Firebase.")),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '');
      if (e.toString().contains("wrong-password") || e.toString().contains("invalid-credential")) {
        errorMessage = L10n.tr("Incorrect current password.", "Kata sandi saat ini salah.");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.tr("An error occurred: $errorMessage", "Terjadi kesalahan: $errorMessage")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required IconData prefixIcon,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.button,
            fontFamily: "Nunito",
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF5852A0)),
          obscureText: isObscured,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: Icon(prefixIcon, color: AppColors.background),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off : Icons.visibility,
                color: AppColors.background,
              ),
              onPressed: onToggleObscure,
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
              borderSide: BorderSide(color: AppColors.containerline1, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.button),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          L10n.tr("Change Password", "Ubah Kata Sandi"),
          style: TextStyle(
            fontFamily: "Quicksand",
            fontWeight: FontWeight.bold,
            color: AppColors.button,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: BgContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Image.asset(
                    AppImage.mascotlogin,
                    height: 180,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    L10n.tr("Secure Your Account", "Amankan Akun Anda"),
                    style: TextStyle(
                      color: AppColors.button,
                      fontFamily: "Super",
                      fontSize: 24,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    L10n.tr("Update your password regularly for better security", "Perbarui kata sandi Anda secara berkala agar lebih aman"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 14,
                      color: AppColors.button,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container1(
                    width: double.infinity,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPasswordField(
                            label: L10n.tr("Current Password", "Kata Sandi Saat Ini"),
                            hint: L10n.tr("Enter current password", "Masukkan kata sandi saat ini"),
                            prefixIcon: Icons.lock_open,
                            controller: _currentPasswordController,
                            isObscured: _obscureCurrent,
                            onToggleObscure: () {
                              setState(() {
                                _obscureCurrent = !_obscureCurrent;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                  return L10n.tr("Please enter your current password", "Silakan masukkan kata sandi saat ini");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            label: L10n.tr("New Password", "Kata Sandi Baru"),
                            hint: L10n.tr("Minimum 6 characters", "Minimal 6 karakter"),
                            prefixIcon: Icons.lock_outline,
                            controller: _newPasswordController,
                            isObscured: _obscureNew,
                            onToggleObscure: () {
                              setState(() {
                                _obscureNew = !_obscureNew;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return L10n.tr("Please enter a new password", "Silakan masukkan kata sandi baru");
                              }
                              if (value.length < 6) {
                                return L10n.tr("Password must be at least 6 characters", "Kata sandi harus minimal 6 karakter");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            label: L10n.tr("Confirm New Password", "Konfirmasi Kata Sandi Baru"),
                            hint: L10n.tr("Retype new password", "Ketik ulang kata sandi baru"),
                            prefixIcon: Icons.lock,
                            controller: _confirmPasswordController,
                            isObscured: _obscureConfirm,
                            onToggleObscure: () {
                              setState(() {
                                _obscureConfirm = !_obscureConfirm;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return L10n.tr("Please confirm your new password", "Silakan konfirmasi kata sandi baru");
                              }
                              if (value != _newPasswordController.text) {
                                return L10n.tr("Passwords do not match!", "Kata sandi tidak cocok!");
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.button,
                                    ),
                                  ),
                                )
                              : AccButton(
                                  sign: L10n.tr("Update Password", "Perbarui Kata Sandi"),
                                  warnaBox: AppColors.button,
                                  destination: const SizedBox(), // Unused since we override onPressed
                                  textbuttoncolor: Colors.white,
                                  onPressed: _changePassword,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
