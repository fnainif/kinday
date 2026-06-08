import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/pleaceholderpage.dart';
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
  int _focusDuration = 25;
  String _focusSound = "None";
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _aiBreakdownLevel = "Balanced";

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _name = prefs.getString('user_name') ?? "User";
        _email = prefs.getString('user_email') ?? "user@kinday.com";
        _focusDuration = prefs.getInt('focus_duration') ?? 25;
        _focusSound = prefs.getString('focus_sound') ?? "None";
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
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
          title: const Text(
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
                    labelStyle: const TextStyle(color: AppColors.button),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.background),
                    ),
                    focusedBorder: const UnderlineInputBorder(
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
                    labelStyle: const TextStyle(color: AppColors.button),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.background),
                    ),
                    focusedBorder: const UnderlineInputBorder(
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
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logged out successfully!")),
                );
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
          style: const TextStyle(
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
      return const Scaffold(
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
                      const Text(
                        "Settings & Profile",
                        style: AppTextStyles.greeting,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: const Text(
                          "Customize your Kinday experience",
                          style: AppTextStyles.affirmation,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.settings, color: AppColors.button, size: 28),
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
                                    child: const CircleAvatar(
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
                                      style: const TextStyle(
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
                                icon: const Icon(
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

                    _buildSectionHeader("Focus Settings"),

                    // Focus Settings Container (Container 2: Leaning blue/purple)
                    Container2(
                      width: double.infinity,
                      child: Column(
                        children: [
                          // Focus Session Slider
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.timer,
                                        color: AppColors.button,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Focus Session Duration",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.button,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "$_focusDuration mins",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppColors.button,
                                  inactiveTrackColor: AppColors.containerline2
                                      .withValues(alpha: 0.3),
                                  thumbColor: AppColors.button,
                                  overlayColor: AppColors.button.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                                child: Slider(
                                  value: _focusDuration.toDouble(),
                                  min: 10,
                                  max: 60,
                                  divisions: 10,
                                  onChanged: (val) {
                                    setState(() {
                                      _focusDuration = val.round();
                                    });
                                  },
                                  onChangeEnd: (val) {
                                    _saveSetting('focus_duration', val.round());
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                            height: 1,
                            color: AppColors.containerline2,
                          ),
                          const SizedBox(height: 12),
                          // Focus Sound Selection
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.volume_up,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Background Sound",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<String>(
                                value: _focusSound,
                                dropdownColor: Colors.white,
                                iconEnabledColor: AppColors.button,
                                style: const TextStyle(
                                  color: AppColors.button,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: const SizedBox(),
                                items:
                                    const [
                                          "None",
                                          "Rain",
                                          "Forest",
                                          "White Noise",
                                        ]
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
                                      _focusSound = value;
                                    });
                                    _saveSetting('focus_sound', value);
                                  }
                                },
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
                                children: const [
                                  Icon(
                                    Icons.notifications_active,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
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
                          const SizedBox(height: 8),
                          const Divider(
                            height: 1,
                            color: AppColors.containerline1,
                          ),
                          const SizedBox(height: 8),
                          // Dark Mode Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.dark_mode,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Dark Mode",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.button,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _darkModeEnabled,
                                activeTrackColor: AppColors.button,
                                onChanged: (val) {
                                  setState(() {
                                    _darkModeEnabled = val;
                                  });
                                  _saveSetting('dark_mode_enabled', val);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(
                            height: 1,
                            color: AppColors.containerline1,
                          ),
                          const SizedBox(height: 8),
                          // AI Breakdown Detail
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.psychology,
                                    color: AppColors.button,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
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
                                style: const TextStyle(
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
                                  builder: (context) =>
                                      const Pleaceholderpage(),
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
                                  builder: (context) =>
                                      const Pleaceholderpage(),
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
                                  builder: (context) =>
                                      const Pleaceholderpage(),
                                ),
                              );
                            },
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
          style: const TextStyle(
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
        style: const TextStyle(
          fontFamily: "Quicksand",
          fontWeight: FontWeight.bold,
          color: AppColors.button,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.button),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
