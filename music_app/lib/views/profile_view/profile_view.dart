import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/components/custom_appbar.dart';
import 'package:muzee/configs/const.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/utils.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/database/local_store.dart';
// import 'package:muzee/services/firebase/firestore_service.dart';
import 'package:muzee/services/firebase/remote_service.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';
import 'package:muzee/views/profile_view/sleep_time.dart';

import 'chose_country.dart';
import 'item_artists.dart';
import 'item_liked_playlist.dart';
import 'item_playlists.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: locale.myProfile,
            showCrown: true,
            trailing: state.isLoggedIn
                ? GestureDetector(
                    onTap: () => context.read<AuthCubit>().signOut(),
                    child: const Icon(
                      FlutterRemix.logout_box_r_line,
                      color: MyColors.primary,
                      size: 24,
                    ),
                  )
                : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                !state.isLoggedIn
                    ? Center(
                        child: GestureDetector(
                          onTap: () {
                            context.read<AuthCubit>().signInWithGoogle();
                            // FirebaseAnalyticsService.inst
                            //     .logScreenEvent('Login_Google');

                            // FirestoreService.inst
                            //     .backupAllToFirestore('nexstudio.up@gmail.com');
                          },
                          child: RMConfigService.inst.loginGoogle
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8,
                                  ),
                                  margin: EdgeInsets.symmetric(
                                    vertical: 32.h,
                                    horizontal: 32.w,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: MyColors.primary,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    locale.loginGoogle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: MyColors.black
                                                .withOpacity(0.75)),
                                  ),
                                )
                              :  SizedBox(height: 16.h),
                        ),
                      )
                    : Container(
                        color: MyColors.black.withOpacity(0.12),
                        padding: EdgeInsets.only(
                          left: 16.w,
                          top: 32.h,
                          right: 16.w,
                          bottom: 16.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: CachedNetworkImage(
                                  width: 88.w,
                                  height: 88.w,
                                  imageUrl: state.user?.picture ?? '',
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: MyColors.primary,
                                    child: const Icon(FlutterRemix.user_line),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Center(
                              child: Text(
                                state.user?.name ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: 32.h),
                            Text(
                              locale.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: MyColors.white),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              state.user?.email ?? '----',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              locale.phone,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: MyColors.white),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              state.user?.phone ?? '----',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                Container(
                  color: MyColors.black.withOpacity(0.12),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ItemLikedPlaylist(),
                      ItemPlaylist(),
                      ItemArtist(),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locale.settings,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 16.h),
                      GestureDetector(
                        onTap: () {
                          DialogHelper.showChangeLanguage();
                        },
                        child: _settingCell(locale.language, locale.en),
                      ),
                      StreamBuilder(
                        stream: context.read<AppCubit>().sleepTimerStream,
                        builder: (context, snapshot) {
                          String reTime = 'None';
                          if (snapshot.hasData) {
                            reTime = Utils.formatDuration(
                                snapshot.data ?? Duration.zero);
                          }

                          return GestureDetector(
                            onTap: () {
                              pushScreenWithNavBar(
                                  context, const SleepTimerView());
                            },
                            child: _settingCell(locale.sleepTimer, reTime),
                          );
                        },
                      ),
                      // _settingCell('Phản hồi', '>'),
                      // _settingCell('Đánh giá', '>'),
                      GestureDetector(
                        onTap: () {
                          pushScreenWithNavBar(context, const ChooseCountry());
                        },
                        child: BlocBuilder<AppCubit, AppState>(
                          buildWhen: (previous, current) =>
                              current is AppUpdateCountry,
                          builder: (context, state) {
                            final countryCode = LocalStore.inst.getCountryCode;
                            final nameCountry = Const.supportRegions.firstWhere(
                                (e) => e['code'] == countryCode)['name'];
                            return _settingCell(
                              'Thịnh hành',
                              nameCountry ?? '',
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        child: _settingCell('Chính sách - điều khoản', '>'),
                        onTap: () {
                          Utils.openUrl(Const.urlPolicy);
                        },
                      ),
                      FutureBuilder(
                        future: context.read<AuthCubit>().getAccessToken(),
                        builder: (context, snapshot) {
                          if (snapshot.data == null) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: () =>
                                context.read<AuthCubit>().revokeGoogleAccess(),
                            child: Container(
                              height: 45,
                              width: double.infinity,
                              margin: EdgeInsets.only(top: 30.h),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Xóa tài khoản',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: Colors.white.withOpacity(0.75)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: kBottomNavigationBarHeight * 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingCell(String title, String subText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: MyColors.primary,
              ),
            ),
          ),
          Text(
            subText,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: MyColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
