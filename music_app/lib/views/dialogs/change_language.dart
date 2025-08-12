import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/app/app_cubit.dart';
import 'package:muzee/configs/const.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/services/database/local_store.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  late String curLanguageCode = LocalStore.inst.getLanguageCode;
  late AppCubit appCubit;
  late final StreamSubscription _appSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      appCubit = context.read<AppCubit>();
      _appSub = appCubit.stream.listen((state) {
        if (state is AppUpdateLanguage) {
          curLanguageCode = state.languageCode;
          reloadView();
        }
      });
    });
  }

  void reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  String toNameLocale(Locale loc) {
    String name = '';
    if (loc.languageCode == 'vi') {
      name = locale.vi;
    } else if (loc.languageCode == 'en') {
      name = locale.en;
    } else if (loc.languageCode == 'es') {
      name = locale.es;
    } else if (loc.languageCode == 'pt') {
      name = locale.pt;
    } else if (loc.languageCode == 'fr') {
      name = locale.fr;
    }
    return name;
  }

  @override
  void dispose() {
    _appSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          children: List.generate(Const.supportedLocales.length, (index) {
            final loc = Const.supportedLocales.elementAt(index);
            final selected = loc.languageCode == curLanguageCode;
            return GestureDetector(
              onTap: () {
                curLanguageCode = loc.languageCode;
                reloadView();
                // context.read<AppCubit>().changeLanguage(loc);
              },
              child: Container(
                width: 156.w,
                height: 52.h,
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                decoration: BoxDecoration(
                  color: selected
                      ? MyColors.white.withOpacity(0.12)
                      : MyColors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selected)
                      Padding(
                        padding: EdgeInsets.only(right: 16.w),
                        child: const Icon(
                          FlutterRemix.check_line,
                          color: MyColors.primary,
                          size: 24,
                        ),
                      ),
                    Text(
                      toNameLocale(loc),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: MyColors.primary,
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
        ),
        GestureDetector(
          onTap: () async {
            await appCubit
                .changeLanguage(curLanguageCode)
                .then((value) => null);
            if (mounted) {
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            }
          },
          child: Container(
            height: 52.h,
            width: double.infinity,
            margin: EdgeInsets.only(top: 16.h),
            color: MyColors.primary,
            alignment: Alignment.center,
            child: Text(
              'Done',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: MyColors.inputText),
            ),
          ),
        ),
      ],
    );
  }
}
