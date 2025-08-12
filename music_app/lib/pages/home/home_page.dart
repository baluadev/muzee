import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/components/widget_extension.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/pages/home/detail_mood.dart';
import 'package:muzee/services/ytb/ytb_service.dart';
import 'suggest_playlist_today.dart';

import 'home_appbar.dart';
import 'recently_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarHome(),
      body: Padding(
        padding: EdgeInsets.only(top: 16.h),
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _MoodHeaderDelegate(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 20,
              ),
            ),
            const SliverToBoxAdapter(
              child: RecentlyWidget(),
            ),
            SliverToBoxAdapter(
              child: context.read<AppCubit>().bannerWidget,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 16.w, top: 16.h),
                child: const SuggestPlaylistToday(),
              ),
            ),
            SliverToBoxAdapter(
              child: context.read<AppCubit>().bannerCollapWidget,
            ),
          ],
        ).attachPaddingBottom().attachPaddingIfPlaying(),
      ),
    );
  }
}

class _MoodHeaderDelegate extends SliverPersistentHeaderDelegate {
  // _MoodHeaderDelegate();
  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return FutureBuilder(
      future: YtbService.getMood(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return SizedBox(
            height: maxExtent,
          );
        }
        final list = snapshot.data!;
        return Container(
          alignment: Alignment.centerLeft,
          color: MyColors.background,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 16.w),
            itemCount: list.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                pushScreenWithNavBar(
                    context, DetailMood(categoryModel: list.elementAt(index)));
              },
              child: Container(
                margin: EdgeInsets.only(right: 12.w, bottom: 16.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: MyColors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.center,
                child: Text(
                  list[index].title ?? '',
                  style: const TextStyle(
                    color: MyColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_MoodHeaderDelegate oldDelegate) => false;
}
