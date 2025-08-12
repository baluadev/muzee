import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/core/locale_support.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/custom_popup_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/packages/bottom_nav_bar/persistent_bottom_nav_bar_v2.dart';
import 'package:muzee/services/ytb/ytb_service.dart';
import 'package:muzee/views/artist/artist_view.dart';
import 'package:muzee/views/dialogs/dialog_helper.dart';

class OptionMenu extends StatefulWidget {
  final SongModel? song;
  final PlaylistModel? playlist;
  final bool isFavourite;

  const OptionMenu({
    super.key,
    this.song,
    this.playlist,
    this.isFavourite = false,
  });

  @override
  State<StatefulWidget> createState() => _OptionMenuState();
}

class _OptionMenuState extends State<OptionMenu> {
  late LibraryCubit cubit;
  @override
  void initState() {
    super.initState();
    cubit = BlocProvider.of<LibraryCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.song != null
          ? Stream.fromFuture(BlocProvider.of<LibraryCubit>(context)
              .existSongInLikedPlaylist(widget.song!.songId))
          : Stream.value(false),
      builder: (_, snapshot) {
        final favourite = (snapshot.data ?? false);

        List<CustomPopupModel> choices = [];

        if (widget.playlist != null && widget.song != null) {
          choices = [
            CustomPopupModel(
              id: 0,
              title: locale.remove,
              icon: FlutterRemix.delete_bin_line,
            ),
            CustomPopupModel(
              id: 3,
              title: locale.viewArtist,
              icon: FlutterRemix.user_line,
            ),
          ];
        } else if (widget.playlist != null) {
          // choices = [
          //   CustomPopupModel(
          //       id: 0, title: locale.deleted, icon: AppIcons.icTrash),
          //   CustomPopupModel(
          //       id: 1, title: locale.rename, icon: AppIcons.icEdit),
          // ];
        } else if (widget.song != null) {
          choices = [
            CustomPopupModel(
              id: 1,
              title: locale.addToPlaylist,
              icon: FlutterRemix.add_line,
            ),
            CustomPopupModel(
              id: 4,
              title: locale.addToQueue,
              icon: FlutterRemix.play_list_2_line,
            ),
            CustomPopupModel(
              id: 3,
              title: locale.viewArtist,
              icon: FlutterRemix.user_line,
            ),
          ];
        }

        if (widget.isFavourite) {
          // choices = [
          //   CustomPopupModel(
          //       id: 0, title: locale.deleted, icon: AppIcons.icTrash),
          //   CustomPopupModel(
          //       id: 1, title: locale.addSongToPlaylist, icon: AppIcons.icPlus),
          //   // CustomPopupModel(id: 2, title:share.tr(), icon: AppIcons.ic_share),
          //   CustomPopupModel(
          //       id: 3, title: locale.viewartist, icon: AppIcons.icUser),
          // ];
        }

        return PopupMenuButton(
          color: MyColors.background,
          padding: EdgeInsets.zero,
          surfaceTintColor: Colors.white,
          onSelected: (value) {
            _onSelected(context, value, favourite);
          },
          itemBuilder: (BuildContext context) {
            return choices.map(
              (choice) {
                return PopupMenuItem(
                  height: ScreenUtil().setHeight(50),
                  value: choice,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          choice.icon,
                          size: 24,
                          color: MyColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: ScreenUtil().setWidth(5),
                      ),
                      Text(choice.title?.toString() ?? '',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                );
              },
            ).toList();
          },
          child: const Icon(
            FlutterRemix.more_2_line,
            size: 24,
            color: MyColors.primary,
          ),
        );
      },
    );
  }

  void _onSelected(BuildContext context, value, bool favourite) {
    final id = value.id as int;
    if (widget.isFavourite) {
      switch (id) {
        case 0:
          {
            // BlocProvider.of<PlaylistCubit>(context)
            //     .removeSongFromPlaylist(widget.playlist, widget.song);
          }
          break;
        case 1:
          {
            DialogHelper.addSongToPlaylists(widget.song!);
          }
          break;
        case 2:
          _onShare(context);
          break;
        case 3:
          _onChannel(context);
          break;
      }
      return;
    }

    if (widget.playlist != null && widget.song != null) {
      switch (id) {
        case 0:
          {
            cubit.removeSongFromPlaylist(widget.playlist!, widget.song!);
          }
          break;
        case 1:
          {
            // if (favourite) {
            //   BlocProvider.of<PlaylistCubit>(context)
            //       .removeSongToFavourite(widget.song);
            // } else {
            //   BlocProvider.of<PlaylistCubit>(context)
            //       .addSongToFavourite(widget.song);
            // }
          }
          break;
        case 2:
          _onShare(context);
          break;
        case 3:
          _onChannel(context);
          break;
      }
    }
    if (widget.playlist != null && widget.song == null) {
      switch (id) {
        case 0:
          {
            // BlocProvider.of<PlaylistCubit>(context)
            //     .deletePlaylist(widget.playlist?.playlistId);
          }
          break;
        case 1:
          {
            // showDialog(
            //     context: context,
            //     builder: (_) {
            //       return Padding(
            //         padding: EdgeInsets.symmetric(
            //           horizontal:
            //               ScreenUtil().setWidth(Const.paddingHorizon * 2),
            //         ),
            //         child: PlaylistDialog(
            //           title: 'Rename playlist',
            //           hintText: 'Enter the name of the playlist',
            //           initText: widget.playlist?.title,
            //           titleButton: 'Submit',
            //           onSubmit: (text) {
            //             BlocProvider.of<PlaylistCubit>(context)
            //                 .editPlaylistName(widget.playlist?.playlistId ?? '',
            //                     title: text, thum: widget.playlist?.thumb);
            //           },
            //         ),
            //       );
            //     });
          }
          break;
      }
    } else if (widget.song != null && widget.playlist == null) {
      switch (id) {
        case 0:
          // if (favourite) {
          //   BlocProvider.of<PlaylistCubit>(context)
          //       .removeSongToFavourite(widget.song);
          // } else {
          //   BlocProvider.of<PlaylistCubit>(context)
          //       .addSongToFavourite(widget.song);
          // }
          break;
        case 1:
          {
            DialogHelper.addSongToPlaylists(widget.song!);
          }
          break;
        case 2:
          _onShare(context);
          break;
        case 3:
          _onChannel(context);
          break;
        case 4:
          myPlayerService.insertToQueue([widget.song!]);
          break;
      }
    }
  }

  void _onShare(BuildContext context) {}

  Future<void> _onChannel(BuildContext context) async {
    final artist = await YtbService.getInfoArtist(songId: widget.song?.songId);
    if (mounted) {
      // ignore: use_build_context_synchronously
      pushScreenWithNavBar(context, ArtistView(artistModel: artist));
    }
  }
}
