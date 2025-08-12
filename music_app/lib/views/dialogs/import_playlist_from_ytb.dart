import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/services/ytb/ytb_helper.dart';

class ImportPlaylistFromYoutube extends StatefulWidget {
  const ImportPlaylistFromYoutube({super.key});

  @override
  State<ImportPlaylistFromYoutube> createState() =>
      _ImportPlaylistFromYoutubeState();
}

class _ImportPlaylistFromYoutubeState extends State<ImportPlaylistFromYoutube> {
  String errorMessage = '';

  late LibraryCubit libraryCubit;
  @override
  void initState() {
    super.initState();
    libraryCubit = context.read<LibraryCubit>();
  }

  void _onSubmitted(String value) async {
    final name = value.trim();
    //editname
    if (name.isEmpty) return;

    final id = YtHelper.getIdPlaylistFromUrl(name);
    print(id);
    if (id.isEmpty) {
      errorMessage = 'Url is invalid';
      reloadView();
      return;
    }
    await libraryCubit.importYtbPlaylistFromId(id);
    if (mounted) Navigator.of(context).pop();
  }

  void reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: MyColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    locale.importPlaylistYtb,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Assets.icons.icClose.svg(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 52.h,
              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16.w),
              child: TextField(
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: MyColors.inputText),
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                cursorColor: MyColors.inputText,
                onSubmitted: _onSubmitted,
                decoration: InputDecoration(
                  fillColor: MyColors.primary,
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
