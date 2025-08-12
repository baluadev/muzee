part of 'muzee_player_cubit.dart';

enum PlayerStatus { playing, paused, stopped }

class MuzeePlayerState extends Equatable {
  final SongModel? currentSong;
  final int currentIndex;
  final List<SongModel> queue;
  final Duration position;
  final Duration duration;
  final PlayerStatus status;
  final bool isShuffle;
  final bool showQueue;
  final bool showFullPlayer;
  final AudioServiceRepeatMode repeatMode;

  const MuzeePlayerState({
    required this.currentSong,
    required this.currentIndex,
    required this.queue,
    required this.position,
    required this.duration,
    required this.status,
    required this.showQueue,
    required this.isShuffle,
    this.showFullPlayer = false,
    required this.repeatMode,
  });

  factory MuzeePlayerState.initial() => const MuzeePlayerState(
      currentSong: null,
      currentIndex: 0,
      queue: [],
      position: Duration.zero,
      duration: Duration.zero,
      status: PlayerStatus.stopped,
      isShuffle: false,
      showQueue: false,
      showFullPlayer: false,
      repeatMode: AudioServiceRepeatMode.none);

  MuzeePlayerState copyWith({
    SongModel? currentSong,
    int? currentIndex,
    List<SongModel>? queue,
    Duration? position,
    Duration? duration,
    PlayerStatus? status,
    bool? isShuffle,
    bool? showQueue,
    bool? showFullPlayer,
   AudioServiceRepeatMode? repeatMode,
  }) {
    return MuzeePlayerState(
      currentSong: currentSong ?? this.currentSong,
      currentIndex: currentIndex ?? this.currentIndex,
      queue: queue ?? this.queue,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      isShuffle: isShuffle ?? this.isShuffle,
      showQueue: showQueue ?? this.showQueue,
      showFullPlayer: showFullPlayer ?? this.showFullPlayer,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }

  @override
  List<Object?> get props => [
        currentSong,
        currentIndex,
        queue,
        position,
        duration,
        status,
        showQueue,
        showFullPlayer,
        repeatMode,
        isShuffle,
      ];
}
