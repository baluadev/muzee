import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/extensions.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';

class AddSongPlaylist extends StatefulWidget {
  final SongModel song;
  const AddSongPlaylist({super.key, required this.song});

  @override
  State<AddSongPlaylist> createState() => _AddSongPlaylistState();
}

class _AddSongPlaylistState extends State<AddSongPlaylist> {
  @override
  Widget build(BuildContext context) {
    List<PlaylistModel> playlists = [];
    final cubit = context.read<LibraryCubit>();
    return BlocBuilder<LibraryCubit, LibraryState>(
      bloc: cubit..getAllPlaylist(),
      builder: (context, state) {
        if (state is PlaylistListUpdate) {
          playlists = state.playlists ?? [];
        }
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: playlists.length,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemBuilder: (context, index) {
                  final playlist = playlists.elementAt(index);
                  return FutureBuilder(
                      future: cubit.existSongInPlaylist(
                          playlist.id, widget.song.songId),
                      builder: (context, snapshot) {
                        final exist = snapshot.data ?? false;
                        return GestureDetector(
                          onTap: () {
                            if (exist) {
                              cubit.removeSongFromPlaylist(
                                  playlist, widget.song);
                            } else {
                              cubit.addSongFromPlaylist(playlist, widget.song);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: Row(
                              children: [
                                const Icon(
                                  FlutterRemix.play_list_line,
                                  color: MyColors.primary,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  playlist.title ?? '',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                Icon(
                                  exist
                                      ? FlutterRemix.checkbox_circle_line
                                      : FlutterRemix.checkbox_blank_circle_line,
                                  color: MyColors.primary,
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                },
              ),
            ),
            GestureDetector(
              onTap: () {
                DialogHelper.showCreateOrEditPlaylistDialog();
              },
              child: Container(
                height: 52.h,
                alignment: Alignment.center,
                margin: EdgeInsets.only(top: 16.h),
                decoration: const BoxDecoration(
                  color: MyColors.primary,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FlutterRemix.add_line,
                      color: MyColors.inputText,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      locale.createPlaylist.capitalize(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: MyColors.inputText),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}
