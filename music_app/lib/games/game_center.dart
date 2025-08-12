import 'package:flutter/material.dart';
import 'package:flutter_2048/main_2048.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/admob/native_admanager.dart';
import 'package:sudoku/sudoku_entry.dart';

import 'game_info.dart';

class GameCenter extends StatefulWidget {
  const GameCenter({super.key});

  @override
  State<GameCenter> createState() => _GameCenterState();
}

class _GameCenterState extends State<GameCenter> {
  final List<GameInfo> games = [
    GameInfo(
      title: '2048',
      subtitle:
          'Slide and merge tiles with powers of two until you create the 2048 tile.',
      logo: 'assets/icons/icon_2048.png',
      color: const Color(0xFFedc22e),
      screen: buildGame2048(const NativeAdManager(
        templateType: TemplateType.small,
      )),
    ),
    GameInfo(
      title: 'Sudoku',
      subtitle:
          'Fill the 9x9 grid so each row, column, and box has all digits from 1 to 9.',
      logo: 'assets/icons/icon_sudoku.png',
      color: Colors.blueAccent,
      screen: Scaffold(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(hasBack: false, title: 'Game Center'),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(games.length, (index) {
            final item = games.elementAt(index);
            Widget screen = item.screen;
            return GestureDetector(
              onTap: () async {
                if (item.title == '2048') {
                  await initGame2048();
                } else if (item.title == 'Sudoku') {
                  final state = await loadSudokuState();
                  screen = buildSudokuApp(state: state);
                }
                // ignore: use_build_context_synchronously
                pushScreenWithNavBar(context, screen);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.black.withOpacity(0.12)
                    ],
                  ),
                ),
                height: 100,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        color: item.color,
                      ),
                      child: Image.asset(item.logo, color: MyColors.white),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Text(item.subtitle,
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
