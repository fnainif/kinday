import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EnergyPage extends StatefulWidget {
  const EnergyPage({super.key});

  @override
  State<EnergyPage> createState() => _EnergyPageState();
}

class EnergyLogData {
  final int energy;
  final double hour;

  EnergyLogData({required this.energy, required this.hour});
}

class _EnergyPageState extends State<EnergyPage> {
  int? _userId;
  int _currentEnergyLvl = 3;
  List<EnergyLogData> chartData = [];

  // Insight computed states
  String _highestEnergyHourStr = "09:00";
  String _lowestEnergyHourStr = "15:00";
  String _productivityDropDay = "Jumat";
  double _avgEnergyThisWeek = 3.6;
  double _avgEnergyLastWeek = 3.2;
  String _energyComparisonStr = "stabil";

  @override
  void initState() {
    super.initState();
    _loadEnergyLogs();
  }

  Future<void> _loadEnergyLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;

    final dbHelper = DBHelper();
    final latestEnergy = await dbHelper.getLatestEnergyForUser(userId);
    final dbLogs = await dbHelper.getEnergyLogsForUser(userId);

    final List<EnergyLogData> loadedLogs = [];
    for (var log in dbLogs) {
      try {
        final timestampStr = log['timestamp'] as String;
        final dt = DateTime.parse(timestampStr);
        final hourDouble = dt.hour + (dt.minute / 60.0);
        loadedLogs.add(
          EnergyLogData(
            energy: log['energy'] as int,
            hour: double.parse(hourDouble.toStringAsFixed(2)),
          ),
        );
      } catch (e) {
        debugPrint("Error parsing energy log timestamp: $e");
      }
    }

    // --- 1. Peak & Valley Hours calculation ---
    String highestHourStr = "09:00";
    String lowestHourStr = "15:00";

    if (dbLogs.isNotEmpty) {
      final Map<int, List<int>> energyByHour = {};
      for (var log in dbLogs) {
        try {
          final timestampStr = log['timestamp'] as String;
          final dt = DateTime.parse(timestampStr);
          final hour = dt.hour;
          final energy = log['energy'] as int;
          energyByHour.putIfAbsent(hour, () => []).add(energy);
        } catch (_) {}
      }

      if (energyByHour.isNotEmpty) {
        int maxHour = -1;
        double maxAvg = -1.0;
        int minHour = -1;
        double minAvg = 99.0;

        energyByHour.forEach((hour, list) {
          final double avg = list.reduce((a, b) => a + b) / list.length;
          if (avg > maxAvg) {
            maxAvg = avg;
            maxHour = hour;
          }
          if (avg < minAvg) {
            minAvg = avg;
            minHour = hour;
          }
        });

        if (maxHour != -1) {
          highestHourStr = "${maxHour.toString().padLeft(2, '0')}:00";
        }
        if (minHour != -1) {
          lowestHourStr = "${minHour.toString().padLeft(2, '0')}:00";
        }
      }
    }

    // --- 2. Productivity drop day calculation ---
    final dbTasks = await dbHelper.getTasksForUser(userId);
    String worstProductivityDay = "Jumat";
    if (dbTasks.isNotEmpty) {
      final Map<int, List<TaskCard>> tasksByDay = {};
      for (var task in dbTasks) {
        if (task.dueDate != null) {
          final dayOfWeek = task.dueDate!.weekday; // 1 = Monday, 7 = Sunday
          tasksByDay.putIfAbsent(dayOfWeek, () => []).add(task);
        }
      }

      if (tasksByDay.isNotEmpty) {
        int worstDay = -1;
        double lowestRate = 2.0;

        tasksByDay.forEach((day, list) {
          final int completed = list.where((t) => t.isCompleted).length;
          final double rate = completed / list.length;
          if (rate < lowestRate) {
            lowestRate = rate;
            worstDay = day;
          }
        });

        if (worstDay != -1) {
          const dayNames = {
            1: "Senin",
            2: "Selasa",
            3: "Rabu",
            4: "Kamis",
            5: "Jumat",
            6: "Sabtu",
            7: "Minggu",
          };
          worstProductivityDay = dayNames[worstDay] ?? "Jumat";
        }
      }
    }

    // --- 3. Week-over-week comparison calculation ---
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfThisWeekDate = DateTime(
      startOfThisWeek.year,
      startOfThisWeek.month,
      startOfThisWeek.day,
    );
    final startOfLastWeekDate = startOfThisWeekDate.subtract(
      const Duration(days: 7),
    );

    final List<int> energyThisWeekList = [];
    final List<int> energyLastWeekList = [];

    for (var log in dbLogs) {
      try {
        final timestampStr = log['timestamp'] as String;
        final dt = DateTime.parse(timestampStr);
        final energy = log['energy'] as int;
        if (dt.isAfter(startOfThisWeekDate) ||
            dt.isAtSameMomentAs(startOfThisWeekDate)) {
          energyThisWeekList.add(energy);
        } else if (dt.isAfter(startOfLastWeekDate) &&
            dt.isBefore(startOfThisWeekDate)) {
          energyLastWeekList.add(energy);
        }
      } catch (_) {}
    }

    double thisWeekAvg = 3.6;
    double lastWeekAvg = 3.2;

    if (energyThisWeekList.isNotEmpty) {
      thisWeekAvg =
          energyThisWeekList.reduce((a, b) => a + b) /
          energyThisWeekList.length;
    }
    if (energyLastWeekList.isNotEmpty) {
      lastWeekAvg =
          energyLastWeekList.reduce((a, b) => a + b) /
          energyLastWeekList.length;
    }

    final double diff = thisWeekAvg - lastWeekAvg;
    String comparisonStr = "stabil";
    if (diff > 0) {
      comparisonStr =
          "naik ${diff.toStringAsFixed(1)} tingkat dari minggu lalu";
    } else if (diff < 0) {
      comparisonStr =
          "turun ${diff.abs().toStringAsFixed(1)} tingkat dari minggu lalu";
    } else {
      comparisonStr = "stabil sama dengan minggu lalu";
    }

    setState(() {
      _userId = userId;
      if (latestEnergy != null) {
        _currentEnergyLvl = latestEnergy;
      }
      chartData = loadedLogs;
      _highestEnergyHourStr = highestHourStr;
      _lowestEnergyHourStr = lowestHourStr;
      _productivityDropDay = worstProductivityDay;
      _avgEnergyThisWeek = thisWeekAvg;
      _avgEnergyLastWeek = lastWeekAvg;
      _energyComparisonStr = comparisonStr;
    });
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 5:
        return "High";
      case 4:
        return "Mid-High";
      case 3:
        return "Medium";
      case 2:
        return "Mid-Low";
      default:
        return "Low";
    }
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.button,
                  fontFamily: "Quicksand",
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontFamily: "Nunito",
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Energy Log", style: AppTextStyles.greeting),

                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: const Text(
                            "Understand your rhythm",
                            style: AppTextStyles.affirmation,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Image.asset(AppImage.mascotlogin, height: 120),
                  ],
                ),
              ),

              Container3(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Energy"),
                    Text(
                      _getEnergyLabel(_currentEnergyLvl),
                      style: const TextStyle(fontSize: 25),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: EnergyIndicator(level: _currentEnergyLvl),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        int tempEnergyLvl =
                            _currentEnergyLvl; // Set to current selection
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                "What's your energy level?",
                                style: TextStyle(
                                  fontFamily: "Quicksand",
                                  color: AppColors.button,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: StatefulBuilder(
                                  builder: (context, setModalState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(5, (index) {
                                            final lvl = index + 1;
                                            final isActive =
                                                tempEnergyLvl >= lvl;
                                            return IconButton(
                                              icon: Icon(
                                                Icons.energy_savings_leaf,
                                                color: isActive
                                                    ? AppColors.button
                                                    : Colors.grey.shade300,
                                              ),
                                              onPressed: () {
                                                setModalState(() {
                                                  tempEnergyLvl = lvl;
                                                });
                                              },
                                            );
                                          }),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_userId != null) {
                                      await DBHelper().insertEnergyLog(
                                        _userId!,
                                        tempEnergyLvl,
                                        DateTime.now().toIso8601String(),
                                      );
                                      await _loadEnergyLogs();
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.button,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    "Save",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 5),
                          Text("Update Energy Log"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SfCartesianChart(
                    primaryXAxis: const NumericAxis(
                      minimum: 0,
                      maximum: 24,
                      interval: 2,
                    ),

                    primaryYAxis: NumericAxis(
                      minimum: 1,
                      maximum: 5,
                      interval: 1,
                      axisLabelFormatter: (args) {
                        String label = '';

                        switch (args.value.toInt()) {
                          case 1:
                            label = 'Low';
                            break;
                          case 2:
                            label = 'Mid-Low';
                            break;
                          case 3:
                            label = 'Medium';
                            break;
                          case 4:
                            label = 'Mid-High';
                            break;
                          case 5:
                            label = 'High';
                            break;
                        }

                        return ChartAxisLabel(
                          label,
                          const TextStyle(fontSize: 12),
                        );
                      },
                    ),

                    series: <ScatterSeries<EnergyLogData, double>>[
                      ScatterSeries<EnergyLogData, double>(
                        dataSource: chartData,
                        xValueMapper: (data, _) => data.hour,
                        yValueMapper: (data, _) => data.energy,
                      ),
                    ],
                  ),
                ),
              ),

              Container2(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.insights, color: AppColors.button, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Energy & Productivity Insights",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.button,
                            fontFamily: "Quicksand",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInsightRow(
                      icon: Icons.access_time_filled,
                      iconColor: Colors.orangeAccent,
                      title: "Jam Energi Tertinggi & Terendah",
                      description:
                          "Energi Anda cenderung berada di puncak pada pukul $_highestEnergyHourStr dan di titik terendah pada pukul $_lowestEnergyHourStr.",
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: AppColors.containerline2.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    _buildInsightRow(
                      icon: Icons.trending_down,
                      iconColor: Colors.redAccent,
                      title: "Penurunan Produktivitas",
                      description:
                          "Berdasarkan tingkat penyelesaian tugas harian, produktivitas Anda cenderung menurun pada hari $_productivityDropDay.",
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: AppColors.containerline2.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    _buildInsightRow(
                      icon: Icons.compare_arrows_rounded,
                      iconColor: Colors.blueAccent,
                      title: "Tren Energi Mingguan",
                      description:
                          "Rata-rata level energi Anda minggu ini (${_avgEnergyThisWeek.toStringAsFixed(1)}) $_energyComparisonStr dibanding minggu lalu (${_avgEnergyLastWeek.toStringAsFixed(1)}).",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
