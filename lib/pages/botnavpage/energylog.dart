import 'package:flutter/material.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
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
  final List<EnergyLogData> chartData = [
    EnergyLogData(energy: 1, hour: 8),
    EnergyLogData(energy: 2, hour: 10),
    EnergyLogData(energy: 3, hour: 12),
    EnergyLogData(energy: 4, hour: 17),
    EnergyLogData(energy: 5, hour: 20),
  ];

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
                    Text("Current Energy"),
                    Text("Medium", style: TextStyle(fontSize: 25)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: EnergyIndicator(level: 3),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        print("tes log energy di Energy page");
                      },
                      child: Row(
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
                    primaryXAxis: NumericAxis(
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
                            label = 'Mid';
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

              Container2(child: Image.asset(AppImage.placeholder)),
            ],
          ),
        ),
      ),
    );
  }
}
