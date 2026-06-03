import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';
import 'package:kinday/constant/app_widget.dart';
import 'package:kinday/pages/pleaceholderpage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BgContainer(
        child: Column(
          children: [
            // 1. Fixed Header Section (Does not scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Good Morning", style: AppTextStyles.greeting),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const Text(
                          "User",
                          style: AppTextStyles.username,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: const Text(
                          "You've done your best today!",
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
            // 2. Wrap the content Column in Expanded to take up remaining height
            Expanded(
              child: Column(
                children: [
                  Container3(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Image.asset(
                          AppImage.placeholder,
                          height: 50,
                          width: 50,
                        ),
                        SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Current Energy"),
                            Text("Medium", style: TextStyle(fontSize: 25)),
                            Text(
                              "Last Updated 12:05",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            print("tes log energy");
                          },
                          child: Row(
                            children: [
                              Text("Log Energy"),
                              SizedBox(width: 5),
                              Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container1(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 10, left: 10),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.container2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  width: 1,
                                  style: BorderStyle.solid,
                                  color: AppColors.containerline2,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  children: [
                                    Icon(Icons.star_border, size: 15),
                                    SizedBox(width: 10),
                                    Text(
                                      "Suggested for now",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15),

                            Row(
                              children: [
                                Image.asset(
                                  AppImage.placeholder,
                                  height: 80,
                                  width: 80,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Membuat Presentasi",
                                      style: AppTextStyles.greeting,
                                    ),
                                    Text("tes 1"),
                                    Text("tes 2"),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 15),

                            AccButton(
                              sign: "Start Focus Session",
                              warnaBox: AppColors.button,
                              destination: Pleaceholderpage(),
                              textbuttoncolor: Colors.white,
                              leadImage: AppImage.placeholder,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container2(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Image.asset(
                          AppImage.placeholder,
                          height: 50,
                          width: 50,
                        ),

                        SizedBox(width: 10),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Today's progress"),
                            Text("2 out of 7 tasks completed"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container3(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text("Breakdown a task with AI"),
                            Text("Turn big tasks into small, doable steps"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
