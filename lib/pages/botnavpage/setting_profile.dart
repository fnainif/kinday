import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/constant/l10n.dart';
import 'package:kinday/database/preference_handler.dart';
import 'package:kinday/database/notification_helper.dart';
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

  // Setting states
  bool _notificationsEnabled = true;
  String _currentTheme = "Lavender Dreams";
  String _aiBreakdownLevel = "Balanced";
  final String _lastBackupTime = "Never";

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _clickBackupText();
    _loadSettings();
  }

  void _clickBackupText() {
    // DIUBAH
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _name = prefs.getString('user_name') ?? "User";
        _email = prefs.getString('user_email') ?? "user@kinday.com";

        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _currentTheme = prefs.getString('app_theme') ?? "Lavender Dreams";
        _aiBreakdownLevel = prefs.getString('ai_breakdown_level') ?? "Balanced";
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading settings: $e");
      setState(() {
        _isLoading = false;
      });
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Edit Profile",
            style: TextStyle(
              fontFamily: "Quicksand",
              fontWeight: FontWeight.bold,
              color: AppColors.button,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _name = nameController.text.trim();
                  _email = emailController.text.trim();
                });
                _saveSetting('user_name', _name);
                _saveSetting('user_email', _email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile updated successfully!"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
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
                      Text(
                        "Settings & Profile",
                        style: AppTextStyles.greeting,
                      ),
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
                                    child: Text(
                                      _name.isNotEmpty
                                          ? _name[0].toUpperCase()
                                          : "U",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Quicksand",
                                      ),
                                    ),
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
                              _buildStatItem("12", "Completed"),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              _buildStatItem("5 Days", "Streak"),
                              Container(
                                width: 1,
                                height: 30,
                                color: AppColors.background.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              _buildStatItem("120m", "Focus Time"),
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
                                  await NotificationHelper().showInstantNotification(
                                    id: 9999,
                                    title: "Test Notification",
                                    body: "If you see this, notifications are working perfectly!",
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
                          Divider(
                            height: 1,
                            color: AppColors.containerline1,
                          ),
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
                                items: const [
                                  "Lavender Dreams",
                                  "Sakura Bloom",
                                  "Matcha Garden",
                                  "Sky Blue",
                                  "Peach Cream",
                                  "Moonlight Lavender",
                                  "Twilight Blue",
                                  "Midnight Forest"
                                ].map((String name) {
                                  String emoji = "";
                                  switch (name) {
                                    case "Lavender Dreams": emoji = "💜"; break;
                                    case "Sakura Bloom": emoji = "🌸"; break;
                                    case "Matcha Garden": emoji = "🌿"; break;
                                    case "Sky Blue": emoji = "☁️"; break;
                                    case "Peach Cream": emoji = "🍑"; break;
                                    case "Moonlight Lavender": emoji = "🌙"; break;
                                    case "Twilight Blue": emoji = "🌌"; break;
                                    case "Midnight Forest": emoji = "🌲"; break;
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
                          Divider(
                            height: 1,
                            color: AppColors.containerline1,
                          ),
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
                          Divider(
                            height: 1,
                            color: AppColors.containerline1,
                          ),
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
                          Divider(
                            height: 1,
                            color: AppColors.containerline2,
                          ),
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
                                    side: BorderSide(
                                      color: AppColors.button,
                                    ),
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

                    // SizedBox(height: 20),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const DatabaseViewerPage(),
                    //       ),
                    //     );
                    //   },
                    //   child: const Text("Database"),
                    // ),
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
