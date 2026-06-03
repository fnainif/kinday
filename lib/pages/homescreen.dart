import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';
import 'package:kinday/constant/app_container.dart';
import 'package:kinday/constant/app_image.dart';
import 'package:kinday/constant/app_textstyle.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 40, left: 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Good Morning",
                      style: AppTextStyles.greeting, //greeting Textstyle
                    ),

                    Transform.translate(
                      offset: Offset(0, -10),
                      child: Text(
                        "User",
                        style: AppTextStyles.username, //greeting Textstyle
                      ),
                    ),

                    Transform.translate(
                      offset: Offset(0, -10),
                      child: Text(
                        "You've done your best today!",
                        style: AppTextStyles
                            .affirmation, //greeting affirmation textstyle
                      ),
                    ),
                  ],
                ),
                Spacer(), //greetin column
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Image.asset(AppImage.placeholder, height: 150),
                ),
              ],
            ),
          ), // greeting row
          SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container1(
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
                ),

                Expanded(
                  flex: 5,
                  child: Container2(
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container3(
                              height: 30,
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

                            ElevatedButton(
                              onPressed: () {
                                print("tes nav start focus");
                              },
                              child: Row(
                                children: [
                                  Text("Start focus session"),
                                  SizedBox(width: 5),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Container1(
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
                ),

                Expanded(
                  flex: 4,
                  child: Container1(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
