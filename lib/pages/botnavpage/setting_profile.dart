import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/constant/task_notifier.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:kinday/database/firebase_auth_service.dart';
import 'package:kinday/database/firebase_backup_service.dart';
import 'package:kinday/database/notification_helper.dart';
import 'package:kinday/database/preference_handler.dart';
import 'package:kinday/models/user_model_sql.dart';
import 'package:kinday/pages/additional/about.dart';
import 'package:kinday/pages/additional/changepass.dart';
import 'package:kinday/pages/additional/faq.dart';
import 'package:kinday/pages/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingProfile extends StatefulWidget {
  const SettingProfile({super.key});

  @override
  State<SettingProfile> createState() => _SettingProfileState();
}

class _SettingProfileState extends State<SettingProfile> {
  // User info state
  String _name = "User";
  String _email = "user@kinday.com";
  String _avatarKey = "letter";
  String? _avatarPath;

  // Setting states
  bool _notificationsEnabled = true;
  String _currentTheme = "Lavender Dreams";
  String _aiBreakdownLevel = "Balanced";
  String _lastBackupTime = "Never";

  // Statistics states
  int _completedTasksCount = 0;
  int _streakDays = 0;
  int _totalFocusMinutes = 0;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _clickBackupText();
    _loadSettings();
    TaskNotifier.taskUpdated.addListener(_loadSettings);
  }

  @override
  void dispose() {
    TaskNotifier.taskUpdated.removeListener(_loadSettings);
    super.dispose();
  }

  void _clickBackupText() {
    // DIUBAH
  }

  Future<void> _handleBackup() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final success = await FirebaseBackupService().backupData(userId);
    if (success) {
      await _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr("Successfully backed up!", "Berhasil di backup!"),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr(
                "Backup failed! Make sure you are logged in to Firebase.",
                "Gagal mencadangkan! Pastikan Anda masuk ke Firebase.",
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final success = await FirebaseBackupService().restoreData(userId);
    if (success) {
      await _loadSettings();
      TaskNotifier.taskUpdated.value = !TaskNotifier.taskUpdated.value;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr("Successfully restored!", "Berhasil di restore!"),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr(
                "Restore failed! No backup found or not logged in.",
                "Gagal memulihkan! Pencadangan tidak ditemukan atau belum masuk.",
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  String _getAvatarAssetPath(String key) {
    switch (key) {
      case 'login':
        return AppImage.mascotlogin;
      case 'task':
        return AppImage.mascottask;
      case 'focus':
        return AppImage.mascotfocus;
      case 'star':
        return AppImage.mascotstar;
      default:
        return "";
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      final dbTasks = await DBHelper().getTasksForUser(userId);
      final completedCount = dbTasks.where((t) => t.isCompleted).length;

      // Calculate streak
      final creationDays = dbTasks.map((t) => t.createdAt).toList();
      final streak = _calculateStreak(creationDays);

      // Get focus time
      final totalFocus = await DBHelper().getTotalFocusMinutesForUser(userId);

      setState(() {
        _name = prefs.getString('user_name') ?? "User";
        _email = prefs.getString('user_email') ?? "user@kinday.com";
        _avatarKey = prefs.getString('user_avatar') ?? "letter";
        _avatarPath = prefs.getString('user_avatar_path');

        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _currentTheme = prefs.getString('app_theme') ?? "Lavender Dreams";
        _aiBreakdownLevel = prefs.getString('ai_breakdown_level') ?? "Balanced";

        _completedTasksCount = completedCount;
        _streakDays = streak;
        _totalFocusMinutes = totalFocus;

        final lastBackupStr = prefs.getString('last_backup_time');
        String lastBackupTimeStr = "Never";
        if (lastBackupStr != null) {
          try {
            final dt = DateTime.parse(lastBackupStr);
            lastBackupTimeStr =
                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          } catch (_) {}
        }
        _lastBackupTime = lastBackupTimeStr;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading settings: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateStreak(List<DateTime> creationDays) {
    if (creationDays.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final uniqueDays = creationDays
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    if (!uniqueDays.contains(today) && !uniqueDays.contains(yesterday)) {
      return 0;
    }

    DateTime checkDay = uniqueDays.contains(today) ? today : yesterday;
    int streak = 0;

    while (uniqueDays.contains(checkDay)) {
      streak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes < 60) {
      return "$totalMinutes min";
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      if (mins == 0) {
        return "${hours}h";
      }
      return "${hours}h ${mins}m";
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      }
    } catch (e) {
      debugPrint("Error saving setting: $e");
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    String dialogAvatarKey = _avatarKey;
    String? dialogAvatarPath = _avatarPath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildAvatarOption(String key, Widget child) {
              final isSelected = dialogAvatarKey == key;
              return GestureDetector(
                onTap: () {
                  setDialogState(() {
                    dialogAvatarKey = key;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.button : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.background.withValues(
                      alpha: 0.2,
                    ),
                    child: child,
                  ),
                ),
              );
            }

            Widget buildCustomAvatarOption() {
              final isSelected = dialogAvatarKey == 'custom';
              final hasImage =
                  dialogAvatarPath != null && dialogAvatarPath!.isNotEmpty;

              return GestureDetector(
                onTap: () async {
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 512,
                      maxHeight: 512,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      setDialogState(() {
                        dialogAvatarPath = image.path;
                        dialogAvatarKey = 'custom';
                      });
                    } else if (hasImage) {
                      setDialogState(() {
                        dialogAvatarKey = 'custom';
                      });
                    }
                  } catch (e) {
                    debugPrint("Error picking image: $e");
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.button : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.background.withValues(
                      alpha: 0.2,
                    ),
                    backgroundImage: hasImage
                        ? FileImage(File(dialogAvatarPath!))
                        : null,
                    child: !hasImage
                        ? Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.button,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                L10n.tr("Edit Profile", "Ubah Profil"),
                style: TextStyle(
                  fontFamily: "Quicksand",
                  fontWeight: FontWeight.bold,
                  color: AppColors.button,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: L10n.tr("Name", "Nama"),
                        labelStyle: TextStyle(color: AppColors.button),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.background),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.button),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: AppColors.button),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.background),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.button),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      L10n.tr("Choose Avatar", "Pilih Avatar"),
                      style: TextStyle(
                        fontFamily: "Quicksand",
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.button,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        buildAvatarOption(
                          'letter',
                          Text(
                            nameController.text.isNotEmpty
                                ? nameController.text[0].toUpperCase()
                                : "U",
                            style: TextStyle(
                              color: AppColors.button,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        buildAvatarOption(
                          'login',
                          ClipOval(
                            child: Image.asset(
                              AppImage.mascotlogin,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                            ),
                          ),
                        ),
                        buildAvatarOption(
                          'task',
                          ClipOval(
                            child: Image.asset(
                              AppImage.mascottask,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                            ),
                          ),
                        ),
                        buildAvatarOption(
                          'focus',
                          ClipOval(
                            child: Image.asset(
                              AppImage.mascotfocus,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                            ),
                          ),
                        ),
                        buildAvatarOption(
                          'star',
                          ClipOval(
                            child: Image.asset(
                              AppImage.mascotstar,
                              fit: BoxFit.cover,
                              width: 44,
                              height: 44,
                            ),
                          ),
                        ),
                        buildCustomAvatarOption(),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    L10n.tr("Cancel", "Batal"),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            L10n.tr(
                              "Name cannot be empty.",
                              "Nama tidak boleh kosong.",
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            L10n.tr(
                              "Email cannot be empty.",
                              "Email tidak boleh kosong.",
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            L10n.tr(
                              "Please enter a valid email.",
                              "Silakan masukkan email yang valid.",
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    final dbHelper = DBHelper();
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getInt('user_id') ?? 1;

                    // Unique email check
                    final isTaken = await dbHelper.isEmailRegistered(
                      email,
                      excludeUserId: userId,
                    );
                    if (isTaken) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.tr(
                                "Email is already taken by another account.",
                                "Email sudah digunakan oleh akun lain.",
                              ),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                      return;
                    }

                    // Retrieve current password to update profile
                    final user = await dbHelper.getUserById(userId);
                    final password = user?.password ?? "";

                    final updatedUser = UserModelSql(
                      id: userId,
                      username: name,
                      email: email,
                      password: password,
                    );

                    final success = await dbHelper.updateUser(updatedUser);

                    if (success) {
                      await prefs.setString('user_name', name);
                      await prefs.setString('user_email', email);
                      await prefs.setString('user_avatar', dialogAvatarKey);
                      if (dialogAvatarPath != null) {
                        await prefs.setString(
                          'user_avatar_path',
                          dialogAvatarPath!,
                        );
                      } else {
                        await prefs.remove('user_avatar_path');
                      }

                      setState(() {
                        _name = name;
                        _email = email;
                        _avatarKey = dialogAvatarKey;
                        _avatarPath = dialogAvatarPath;
                      });

                      // Trigger updates across tabs
                      TaskNotifier.notify();

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.tr(
                                "Profile updated successfully!",
                                "Profil berhasil diperbarui!",
                              ),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              L10n.tr(
                                "Failed to update profile.",
                                "Gagal memperbarui profil.",
                              ),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.button,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    L10n.tr("Save", "Simpan"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Log Out",
            style: TextStyle(
              fontFamily: "Quicksand",
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: const Text("Are you sure you want to log out from Kinday?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await PreferenceHandler.logOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully!")),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    bool isDeleteEnabled = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                L10n.tr("Delete Account?", "Hapus Akun?"),
                style: const TextStyle(
                  fontFamily: "Quicksand",
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.tr(
                      "This action is permanent and cannot be undone. To confirm, please type \"DELETE\" below:",
                      "Tindakan ini permanen dan tidak dapat dibatalkan. Untuk mengonfirmasi, silakan ketik \"DELETE\" di bawah:",
                    ),
                    style: const TextStyle(fontFamily: "Nunito"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "DELETE",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        isDeleteEnabled = val == "DELETE";
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    L10n.tr("Cancel", "Batal"),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleteEnabled
                      ? () async {
                          Navigator.pop(context);
                          await _handleDeleteAccount();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    L10n.tr("Delete Permanently", "Hapus Permanen"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      final firebaseUid = prefs.getString('user_id_firebase');

      // 1. Delete from Firebase
      if (firebaseUid != null) {
        final authService = FirebaseAuthService();
        await authService.deleteUser(firebaseUid);
      }

      // 2. Delete from SQLite
      final dbHelper = DBHelper();
      await dbHelper.deleteUser(userId);

      // 3. Clear preferences & log out
      await PreferenceHandler.logOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr(
                "Account deleted successfully.",
                "Akun berhasil dihapus.",
              ),
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll(RegExp(r'\[.*?\]'), '');
        if (e.toString().contains("requires-recent-login")) {
          errorMsg = L10n.tr(
            "This action is sensitive and requires recent authentication. Please log out, log back in, and try again.",
            "Tindakan ini sensitif dan memerlukan autentikasi baru. Silakan keluar, masuk kembali, dan coba lagi.",
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.tr("Delete failed: $errorMsg", "Gagal menghapus: $errorMsg"),
            ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Quicksand",
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.button,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.button)),
      );
    }

    return Scaffold(
      body: BgContainer(
        child: Column(
          children: [
            // Fixed Header Area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        L10n.tr("Settings & Profile", "Pengaturan & Profil"),
                        style: AppTextStyles.greeting,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Text(
                          L10n.tr(
                            "Customize your Kinday experience",
                            "Sesuaikan pengalaman Kinday-mu",
                          ),
                          style: AppTextStyles.affirmation,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showLogoutDialog,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: AppColors.button,
                      size: 24,
                    ),
                    tooltip: L10n.tr("Log Out", "Keluar"),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Info Header Card
                    Container1(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppColors.button,
                                    backgroundImage:
                                        _avatarKey == 'custom' &&
                                            _avatarPath != null &&
                                            _avatarPath!.isNotEmpty
                                        ? FileImage(File(_avatarPath!))
                                        : (_avatarKey != 'letter' &&
                                                  _avatarKey.isNotEmpty
                                              ? AssetImage(
                                                  _getAvatarAssetPath(
                                                    _avatarKey,
                                                  ),
                                                )
                                              : null),
                                    child:
                                        (_avatarKey == 'letter' ||
                                            _avatarKey.isEmpty)
                                        ? Text(
                                            _name.isNotEmpty
                                                ? _name[0].toUpperCase()
                                                : "U",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: "Quicksand",
                                            ),
                                          )
                                        : null,
                                  ),
                                  GestureDetector(
                                    onTap: _showEditProfileDialog,
                                    child: CircleAvatar(
                                      radius: 13,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: AppColors.button,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _name,
                                      style: TextStyle(
                                        fontFamily: "Quicksand",
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.button,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _email,
                                      style: TextStyle(
                                        fontFamily: "Nunito",
                                        fontSize: 14,
                                        color: AppColors.button.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _showEditProfileDialog,
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.button,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Divider(height: 1),
                          ),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                "$_completedTasksCount",
                                L10n.tr("Completed", "Selesai"),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.background.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              _buildStatItem(
                                L10n.tr(
                                  "$_streakDays Days",
                                  "$_streakDays Hari",
                                ),
                                L10n.tr("Streak", "Beruntun"),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.background.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              _buildStatItem(
                                _formatFocusTime(_totalFocusMinutes),
                                L10n.tr("Focus Time", "Waktu Fokus"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _buildSectionHeader(
                      L10n.tr("App Preferences", "Preferensi Aplikasi"),
                    ),

                    // Preferences Container (Container 3: Leaning pink/purple)
                    Container3(
                      width: double.infinity,
                      child: Column(
                        children: [
                          // Notifications Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_active_rounded,
                                      color: AppColors.button,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        L10n.tr(
                                          "Enable Notifications",
                                          "Aktifkan Notifikasi",
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.button,
                                          fontFamily: "Quicksand",
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _notificationsEnabled,
                                activeColor: AppColors.button,
                                activeTrackColor: AppColors.button.withValues(
                                  alpha: 0.5,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _notificationsEnabled = val;
                                  });
                                  _saveSetting('notifications_enabled', val);
                                },
                              ),
                            ],
                          ),
                          if (_notificationsEnabled) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await NotificationHelper()
                                      .showInstantNotification(
                                        id: 9999,
                                        title: "Test Notification",
                                        body:
                                            "If you see this, notifications are working perfectly!",
                                      );
                                },
                                icon: Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16,
                                  color: AppColors.button,
                                ),
                                label: Text(
                                  L10n.tr(
                                    "Send Test Notification",
                                    "Kirim Notifikasi Uji",
                                  ),
                                  style: TextStyle(
                                    color: AppColors.button,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Quicksand",
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.button),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: AppColors.containerline1.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Theme Selector Dropdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.palette_rounded,
                                      color: AppColors.button,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        L10n.tr("App Theme", "Tema Aplikasi"),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.button,
                                          fontFamily: "Quicksand",
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.containerline1
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _currentTheme,
                                      dropdownColor: Colors.white,
                                      iconEnabledColor: AppColors.button,
                                      style: TextStyle(
                                        color: AppColors.button,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Quicksand",
                                        fontSize: 13,
                                      ),
                                      items:
                                          const [
                                            "Lavender Dreams",
                                            "Sakura Bloom",
                                            "Matcha Garden",
                                            "Sky Blue",
                                            "Peach Cream",
                                            "Moonlight Lavender",
                                            "Twilight Blue",
                                            "Midnight Forest",
                                          ].map((String name) {
                                            String emoji = "";
                                            switch (name) {
                                              case "Lavender Dreams":
                                                emoji = "💜";
                                                break;
                                              case "Sakura Bloom":
                                                emoji = "🌸";
                                                break;
                                              case "Matcha Garden":
                                                emoji = "🌿";
                                                break;
                                              case "Sky Blue":
                                                emoji = "☁️";
                                                break;
                                              case "Peach Cream":
                                                emoji = "🍑";
                                                break;
                                              case "Moonlight Lavender":
                                                emoji = "🌙";
                                                break;
                                              case "Twilight Blue":
                                                emoji = "🌌";
                                                break;
                                              case "Midnight Forest":
                                                emoji = "🌲";
                                                break;
                                            }
                                            return DropdownMenuItem<String>(
                                              value: name,
                                              child: Text(
                                                "$emoji $name",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _currentTheme = value;
                                          });
                                          AppColors.setTheme(value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: AppColors.containerline1.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // App Language selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.language_rounded,
                                      color: AppColors.button,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        L10n.tr(
                                          "App Language",
                                          "Bahasa Aplikasi",
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.button,
                                          fontFamily: "Quicksand",
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.containerline1
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: L10n.lang == "en"
                                          ? "English"
                                          : L10n.lang == "id"
                                              ? "Bahasa Indonesia"
                                              : "Japanese",
                                      dropdownColor: Colors.white,
                                      iconEnabledColor: AppColors.button,
                                      style: TextStyle(
                                        color: AppColors.button,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Quicksand",
                                        fontSize: 13,
                                      ),
                                      items:
                                          const ["English", "Bahasa Indonesia", "Japanese"]
                                              .map(
                                                (val) => DropdownMenuItem(
                                                  value: val,
                                                  child: Text(
                                                    val,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            L10n.setLanguage(
                                              value == "English"
                                                  ? "en"
                                                  : value == "Bahasa Indonesia"
                                                      ? "id"
                                                      : "ja",
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _buildSectionHeader(
                      L10n.tr("Account & Info", "Akun & Info"),
                    ),

                    // Info Container (Container 1: White/Grey card style)
                    Container1(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.lock_outline_rounded,
                            title: L10n.tr(
                              "Change Password",
                              "Ubah Kata Sandi",
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePassPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildListTile(
                            icon: Icons.help_outline_rounded,
                            title: L10n.tr("Help & FAQ", "Bantuan & FAQ"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FaqPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildListTile(
                            icon: Icons.info_outline_rounded,
                            title: L10n.tr("About Kinday", "Tentang Kinday"),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AboutPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    _buildSectionHeader(
                      L10n.tr(
                        "Data Backup & Restore",
                        "Cadangkan & Pulihkan Data",
                      ),
                    ),

                    // Data Backup & Restore Container
                    Container2(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.backup_rounded,
                                color: AppColors.button,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                L10n.tr("Last Backup", "Pencadangan Terakhir"),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.button,
                                  fontFamily: "Quicksand",
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _lastBackupTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.button,
                                  fontFamily: "Nunito",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: AppColors.containerline2.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _handleBackup,
                                  icon: const Icon(
                                    Icons.cloud_upload_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  label: Text(
                                    L10n.tr("Backup", "Cadangkan"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _handleRestore,
                                  icon: Icon(
                                    Icons.cloud_download_rounded,
                                    color: AppColors.button,
                                    size: 16,
                                  ),
                                  label: Text(
                                    L10n.tr("Restore", "Pulihkan"),
                                    style: TextStyle(
                                      color: AppColors.button,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.button),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete Account Button Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showDeleteAccountDialog,
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                          ),
                          label: Text(
                            L10n.tr("Delete Account", "Hapus Akun"),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Quicksand",
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),


                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: "Quicksand",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.button,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Nunito",
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.button, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: "Quicksand",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.button,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: "Nunito",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.button),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: "Quicksand",
          fontWeight: FontWeight.bold,
          color: AppColors.button,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.button),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
