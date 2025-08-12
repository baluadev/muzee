import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muzee/blocs/player/muzee_player_cubit.dart';
import 'package:muzee/components/image_song_widget.dart';
import 'package:muzee/components/option_menu.dart';
import 'package:muzee/components/song_horiz_widget.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';

class NowPlaying extends StatefulWidget {
  final VoidCallback onBack;
  const NowPlaying({super.key, required this.onBack});

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MuzeePlayerCubit, MuzeePlayerState>(
      builder: (context, state) {
        return Container(
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: Colors.blue,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ImageSongWidget(
                      id: state.currentSong?.songId ?? '',
                      width: MediaQuery.of(context).size.width,
                      height: 72.h,
                      radius: 0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: MyColors.primary,
                              size: 40.w,
                            ),
                            onPressed: widget.onBack,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Now Playing",
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                              SizedBox(height: 4.h),
                              Text(
                                '"${state.currentSong?.title}" – ${state.currentSong?.artist}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Text('In Queue',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              Expanded(
                // height: 380.h,
                child: ReorderableListView.builder(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  itemCount: state.queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    myPlayerService.changeQueuePosition(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final song = state.queue[index];
                    return Container(
                      key: ValueKey('${song.songId}_$index'),
                      color: Colors.black,
                      child: SongHorizWidget(
                        song: song,
                        optionMenu: OptionMenu(song: song),
                      ),
                    );
                  },
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Text(
              //         'Auto-recommendations',
              //         style: Theme.of(context).textTheme.headlineSmall,
              //       ),
              //       Switch(value: true, onChanged: (value){})
              //     ],
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}
