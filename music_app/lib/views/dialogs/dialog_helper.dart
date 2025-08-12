import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/core/navigation_service.dart';
import 'package:muzee/gen/assets.gen.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/views/dialogs/add_song_playlist.dart';
import 'package:muzee/views/dialogs/change_language.dart';
import 'package:muzee/views/dialogs/create_or_edit_playlist.dart';

import 'force_update.dart';
import 'import_playlist_from_ytb.dart';
import 'suggest_login.dart';
import 'loading.dart';

class DialogHelper {
  static dynamic _showGeneralDialog(
    Widget child, {
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: NavigationService.inst.curContext,
      builder: (c) {
        return Material(
          color: Colors.transparent,
          child: Dialog(
            insetPadding: EdgeInsets.zero,
            child: child,
          ),
        );
      },
    );
  }

  static void showLoading({String? title}) {
    _showGeneralDialog(
      Loading(title: title),
      barrierDismissible: false,
    );
  }

  static void hideLoading() {
    back();
  }

  static void back() {
    Navigator.maybePop(NavigationService.inst.curContext);
  }

  static showCreateOrEditPlaylistDialog({PlaylistModel? playlist}) async {
    return showModalBottomSheet(
      context: NavigationService.inst.curContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CreateOrEditPlaylist(
          playlist: playlist,
        ),
      ),
    );
  }

  static showImportPlaylistYtbDialog() async {
    return showModalBottomSheet(
      context: NavigationService.inst.curContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const ImportPlaylistFromYoutube(),
      ),
    );
  }

  static showSuggesstLoginGoogle() {
    showCustomDialog(const SuggestLogin());
  }

  static showChangeLanguage() {
    showCustomDialog(
      title: locale.chooseLanguage,
      const ChangeLanguage(),
    );
  }

  static addSongToPlaylists(SongModel song) {
    showCustomDialog(
      title: locale.addToPlaylist,
      AddSongPlaylist(song: song),
    );
  }

  static showUpdateDialog(
    bool forceUpdate,
    String latestVersion,
    String updateUrl,
  ) {
    showDialog(
      barrierDismissible: !forceUpdate,
      context: NavigationService.inst.curContext,
      builder: (_) => ForceUpdateDialog(
        newVersion: latestVersion,
        updateUrl: updateUrl,
        forceUpdate: forceUpdate,
      ),
    );
  }

  ///
  ///BASE
  ///

  static showCustomDialog(
    Widget child, {
    String title = 'Thông báo',
    String titleButton = 'Done',
    VoidCallback? onDone,
  }) {
    final context = NavigationService.inst.curContext;
    _showGeneralDialog(
      Container(
        color: MyColors.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: MyColors.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Assets.icons.icClose.svg(),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static showCustomModelBottomSheet({
    required String title,
    required String tittleButton,
    required VoidCallback onPressed,
    required Widget child,
    double height = 0.8,
    Color? color,
    bool? isDismissible = false,
  }) {
    final context = NavigationService.inst.curContext;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: isDismissible ?? false,
      elevation: 0,
      builder: (context) {
        return Stack(
          children: [
            if (isDismissible!)
              GestureDetector(
                onTap: Navigator.of(context).pop,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            DraggableScrollableSheet(
              initialChildSize: height, // Chiều cao ban đầu
              minChildSize: 0.4, // Chiều cao tối thiểu
              maxChildSize: 1, // Chiều cao tối đa
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: color ?? MyColors.background,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Assets.icons.icClose.svg(),
                        ],
                      ),
                      child,
                      Container(
                        height: 52.h,
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        color: MyColors.primary,
                        child: Text(
                          tittleButton,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: MyColors.inputText),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  static void showNotificationPermissionPopup() {
    final context = NavigationService.inst.curContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active,
                    size: 48, color: Colors.deepPurple),
                const SizedBox(height: 12),
                Text(
                  "Cho phép gửi thông báo?",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Text(
                  "Muzee sẽ gửi thông báo khi có playlist mới hoặc gợi ý nhạc phù hợp với bạn.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      child: Text("Để sau"),
                      onPressed: () {
                        Navigator.of(context).pop(); // đóng popup
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Đồng ý"),
                      onPressed: () async {
                        Navigator.of(context).pop(); // đóng popup
                        await AwesomeNotifications()
                            .requestPermissionToSendNotifications();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
