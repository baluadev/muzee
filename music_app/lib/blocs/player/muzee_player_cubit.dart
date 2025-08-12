import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzee/blocs/library/library_cubit.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/player_service.dart';

part 'muzee_player_state.dart';

class MuzeePlayerCubit extends Cubit<MuzeePlayerState> {
  final LibraryCubit _libraryCubit;
  final PlayerService _playerService;
  late final StreamSubscription _mediaItemSub;
  late final StreamSubscription _playbackSub;
  late final StreamSubscription _queueSub;
  late final StreamSubscription _finishSub;

  MuzeePlayerCubit(this._playerService, this._libraryCubit)
      : super(MuzeePlayerState.initial()) {
    _mediaItemSub = _playerService.mediaItem.listen(_onMediaItemChanged);
    _playbackSub = _playerService.playbackState.listen(_onPlaybackChanged);
    _queueSub = _playerService.queueStream.listen(_onQueueChanged);
    _finishSub = _playerService.finishStream.listen(_onFinished);
  }

  void _onMediaItemChanged(MediaItem? item) {
    final currentIndex =
        _playerService.currentQueue.indexWhere((s) => s.songId == item?.id);
    if (_playerService.currentSong != null) {
      _libraryCubit.addSongRecently(_playerService.currentSong!);
      // Update the state with the current song and index
      emit(state.copyWith(
        currentSong: _playerService.currentSong,
        currentIndex: currentIndex,
        queue: _playerService.currentQueue,
        showFullPlayer: true,
      ));
    }
  }

  void _onFinished(({SongModel song, int position, int duration}) data) {
    final song = data.song;
    final position = data.position;
    final duration = data.duration;
    // Add the current song to the recently played list
    final fixSong = song.copyWith(duration: duration);
    _libraryCubit.addSongRecently(fixSong, listenedSeconds: position);
  }

  void _onPlaybackChanged(PlaybackState playbackState) {
    emit(state.copyWith(
      status:
          playbackState.playing ? PlayerStatus.playing : PlayerStatus.paused,
    ));
  }

  void _onQueueChanged(List<SongModel> queue) {
    emit(state.copyWith(queue: queue));
  }

  void hideOrShowFullPlayer(bool show) {
    emit(state.copyWith(showFullPlayer: show));
  }

  Future<void> play() => _playerService.play();
  Future<void> pause() => _playerService.pause();
  Future<void> skipToNext() => _playerService.skipToNext();
  Future<void> skipToPrevious() => _playerService.skipToPrevious();
  Future<void> seek(Duration position) => _playerService.seek(position);
  void toogleRepeatMode() {
    _playerService.toggleRepeatMode();
    final repeatMode = _playerService.repeatMode;
    emit(state.copyWith(repeatMode: repeatMode));
  }

  void toogleShuffle() {
    _playerService.toggleShuffle();
    final isShuffle = _playerService.isShuffle;
    emit(state.copyWith(isShuffle: isShuffle));
  }

  void showQueue() => emit(state.copyWith(showQueue: !state.showQueue));

  @override
  Future<void> close() {
    _mediaItemSub.cancel();
    _playbackSub.cancel();
    _queueSub.cancel();
    _finishSub.cancel();
    return super.close();
  }
}
