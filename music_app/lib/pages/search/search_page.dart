import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/components/widget_extension.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/admob/native_admanager.dart';

import '../../views/search_view/search_view.dart';
import 'browse_widget.dart';
import 'trending_artist.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: GestureDetector(
          onTap: () {
            pushScreenWithNavBar(context, const SearchView());
          },
          child: Container(
            height: 40.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: MyColors.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: EdgeInsets.only(left: 16.w),
            child: Row(
              children: [
                Icon(
                  FlutterRemix.search_line,
                  color: MyColors.black.withOpacity(0.75),
                ),
                SizedBox(width: 8.w),
                Text(
                  locale.search,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: MyColors.black.withOpacity(0.75),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 28.h),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TrendingArtists(),
              const NativeAdManager(
                templateType: TemplateType.medium,
              ),
              const BrowseWidget(),
              SizedBox(height: 32.h),
            ],
          ).attachPaddingBottom().attachPaddingIfPlaying(),
        ),
      ),
    );
  }
}
