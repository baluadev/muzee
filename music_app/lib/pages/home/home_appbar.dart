import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/auth/auth_cubit.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/database/local_store.dart';
import 'package:muzee/views/profile_view/profile_view.dart';

const FlutterAppAuth appAuth = FlutterAppAuth();

class AppBarHome extends StatelessWidget implements PreferredSizeWidget {
  const AppBarHome({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return SafeArea(
          child: Row(
            children: [
              SizedBox(width: 16.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "👋 ${state.user?.name ?? 'Hey you'},",
                    style: const TextStyle(
                      fontSize: 16,
                      // color: MyColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "How are you?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: MyColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () async {
                    pushScreenWithNavBar(context, const ProfileView());
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CachedNetworkImage(
                          width: 48.w,
                          height: 48.w,
                          imageUrl: state.user?.picture ?? '',
                          errorWidget: (context, url, error) => Container(
                            color: MyColors.primary,
                            child: const Icon(FlutterRemix.user_line),
                          ),
                        ),
                        if (LocalStore.inst.adsRemoved)
                          Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Assets.images.verify.image(
                              width: 20.w,
                              height: 20.w,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
