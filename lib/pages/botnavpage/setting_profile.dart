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
import 'package:kinday/database/notification_helper.dart';
import 'package:kinday/database/preference_handler.dart';
import 'package:kinday/models/user_model_sql.dart';
import 'package:kinday/pages/additional/about.dart';
import 'package:kinday/pages/additional/changepass.dart';
import 'package:kinday/pages/additional/faq.dart';
import 'package:kinday/pages/auth/login.dart';
import 'package:kinday/pages/db_viewer_page.dart';
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
  final String _lastBackupTime = "Never";

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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Quicksand",
            fontSize: 18,
            fontWeight: FontWeight.bold,
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
                      Text("Settings & Profile", style: AppTextStyles.greeting),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Text(
                          "Customize your Kinday experience",
                          style: AppTextStyles.affirmation,
                        ),
                      ),
                    ],
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
                                    radius: 36,
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
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: "Quicksand",
                                            ),
                                          )
                                        : null,
                                  ),
                                  GestureDetector(
                                    onTap: _showEditProfileDialog,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        Icons.edit,
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
                                      style: const TextStyle(
                                        fontFamily: "Nunito",
                                        fontSize: 14,
                                        color: Colors.black54,
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
                                  Icons.chevron_right,
                                  color: AppColors.button,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1),
                          ),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                "$_completedTasksCount",
                                "Completed",
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              _buildStatItem("$_streakDays Days", "Streak"),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              _buildStatItem(
                                _formatFocusTime(_totalFocusMinutes),
                                "Focus Time",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _buildSectionHeader("App Preferences"),

                    // Preferences Container (Container 3: Leaning pink/purple)
                    Container3(
                      width: double.infinity,
                      child: Column(
                        children: [
                          // Notifications Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Enable Notifications",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _notificationsEnabled,
                                activeTrackColor: AppColors.button,
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
                                  "Send Test Notification",
                                  style: TextStyle(
                                    color: AppColors.button,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.button),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Divider(height: 1, color: AppColors.containerline1),
                          const SizedBox(height: 8),
                          // Theme Selector Dropdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.palette,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "App Theme",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<String>(
                                value: _currentTheme,
                                dropdownColor: Colors.white,
                                iconEnabledColor: AppColors.button,
                                style: TextStyle(
                                  color: AppColors.button,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: const SizedBox(),
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
                                        child: Text("$emoji $name"),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(height: 1, color: AppColors.containerline1),
                          const SizedBox(height: 8),
                          // AI Breakdown Detail
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "AI Breakdown Level",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<String>(
                                value: _aiBreakdownLevel,
                                dropdownColor: Colors.white,
                                iconEnabledColor: AppColors.button,
                                style: TextStyle(
                                  color: AppColors.button,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: const SizedBox(),
                                items: const ["Simple", "Balanced", "Detailed"]
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text(val),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _aiBreakdownLevel = value;
                                    });
                                    _saveSetting('ai_breakdown_level', value);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(height: 1, color: AppColors.containerline1),
                          const SizedBox(height: 8),
                          // App Language selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.language,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "App Language",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<String>(
                                value: L10n.lang == "en"
                                    ? "English"
                                    : "Bahasa Indonesia",
                                dropdownColor: Colors.white,
                                iconEnabledColor: AppColors.button,
                                style: TextStyle(
                                  color: AppColors.button,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: const SizedBox(),
                                items: const ["English", "Bahasa Indonesia"]
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text(val),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    L10n.setLanguage(
                                      value == "English" ? "en" : "id",
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _buildSectionHeader("Account & Info"),

                    // Info Container (Container 1: White/Grey card style)
                    Container1(
                      width: double.infinity,
                      child: Column(
                        children: [
                          _buildListTile(
                            icon: Icons.lock_outline,
                            title: "Change Password",
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
                            icon: Icons.help_outline,
                            title: "Help & FAQ",
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
                            icon: Icons.info_outline,
                            title: "About Kinday",
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

                    _buildSectionHeader("Data Backup & Restore"),

                    // Data Backup & Restore Container
                    Container2(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.backup,
                                color: AppColors.button,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Last Backup",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.button,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _lastBackupTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.button,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(height: 1, color: AppColors.containerline2),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // ignore: avoid_print
                                    print("successfully backed up");
                                    _clickBackupText();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          L10n.tr(
                                            "Successfully backed up!",
                                            "Berhasil di backup!",
                                          ),
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.cloud_upload,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    "Backup",
                                    style: TextStyle(
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
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // ignore: avoid_print
                                    print("successfully restored");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          L10n.tr(
                                            "Successfully restored!",
                                            "Berhasil di restore!",
                                          ),
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.cloud_download,
                                    color: AppColors.button,
                                    size: 16,
                                  ),
                                  label: Text(
                                    "Restore",
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Logout Button Section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Log Out",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Quicksand",
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DatabaseViewerPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.storage, color: AppColors.button),
                        label: Text(
                          "View Database (Temp)",
                          style: TextStyle(
                            color: AppColors.button,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Quicksand",
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
