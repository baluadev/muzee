import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/gen/colors.gen.dart';
import 'package:muzee/main.dart';
import 'package:muzee/models/song_model.dart';

class LikedWidget extends StatefulWidget {
  const LikedWidget({super.key});

  @override
  State<LikedWidget> createState() => _LikedWidgetState();
}

class _LikedWidgetState extends State<LikedWidget> {
  StreamSubscription? _likedStreamSubscription;
  StreamSubscription? _mediaItemSub;
  LibraryCubit? _libraryCubit;
  bool isLiked = false;
  SongModel? song;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _libraryCubit = context.read<LibraryCubit>();
      _likedStreamSubscription = _libraryCubit!.stream.listen((event) {
        exist();
      });
      _mediaItemSub = myPlayerService.mediaItem.listen((curSong) {
        song = myPlayerService.currentSong;
        exist();
      });
    });
  }

  Future exist() async {
    if (song == null) return;
    isLiked = await _libraryCubit!.isLiked(song!.songId);
    reloadView();
  }

  reloadView() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _likedStreamSubscription?.cancel();
    _mediaItemSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (song == null) return;
        if (isLiked) {
          _libraryCubit!.removeFromLiked(song!.songId);
        } else {
          _libraryCubit!.addToLiked(song!);
        }
      },
      child: Icon(
        isLiked ? FlutterRemix.heart_fill : FlutterRemix.heart_line,
        color: MyColors.primary,
      ),
    );
  }
}
