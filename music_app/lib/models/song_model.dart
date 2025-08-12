import 'package:audio_service/audio_service.dart';
import 'package:isar/isar.dart';
import 'package:muzee/core/utils.dart';
part 'song_model.g.dart';

@collection
class SongModel {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  late String songId;

  String? title;
  String? thumbnailUrl;
  int? duration;
  String? artist;
  String? artistId;
  // lịch sử nghe
  int playCount = 0;
  int totalListenSeconds = 0;
  String? keyword; //từ mục tìm kiếm chặng hạn
  DateTime? lastPlayedAt;

  SongModel({
    required this.songId,
    this.title,
    this.thumbnailUrl,
    this.duration = 0,
    this.artist,
    this.artistId,
    this.keyword,
  });

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'artist': artist,
      'artistId': artistId,
      'playCount': playCount,
      'totalListenSeconds': totalListenSeconds,
      'keyword': keyword,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      songId: json['songId'],
      title: json['title'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'] ?? 0,
      artist: json['artist'],
      artistId: json['artistId'],
      keyword: json['keyword'],
    )
      ..playCount = json['playCount'] ?? 0
      ..totalListenSeconds = json['totalListenSeconds'] ?? 0
      ..lastPlayedAt = json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt'])
          : null;
  }

  Map<String, String?> toJson2() {
    return {
      'songId': songId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'duration': '$duration',
      'artist': artist,
      'artistId': artistId,
      'playCount': '$playCount',
      'totalListenSeconds': '$totalListenSeconds',
      'keyword': keyword,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }

  factory SongModel.fromJson2(Map<String, String?> json) {
    return SongModel(
      songId: json['songId']!,
      title: json['title'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: int.parse(json['duration'] ?? '0'),
      artist: json['artist'],
      artistId: json['artistId'],
      keyword: json['keyword'],
    )
      ..playCount = int.parse(json['playCount'] ?? '0')
      ..totalListenSeconds = int.parse(json['totalListenSeconds'] ?? '0')
      ..lastPlayedAt = json['lastPlayedAt'] != null
          ? DateTime.tryParse(json['lastPlayedAt']!)
          : null;
  }

  SongModel copyWith({
    String? keyword,
    int? duration,
  }) {
    return SongModel(
      songId: songId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      duration: duration ?? this.duration,
      artist: artist,
      keyword: this.keyword,
    );
  }

  MediaItem toMediaItem() => MediaItem(
        id: songId,
        title: title ?? '',
        artist: artist,
        artUri: Uri.parse(thumbnailUrl ?? Utils.thumbD(songId)),
      );

  factory SongModel.fromMood(Map json) {
    final String songId = json['videoId'] ?? '';
    return SongModel(
      songId: songId,
      title: json['title'] ?? '',
      artist: json['artists'] != null ? json['artists'][0]['name'] : null,
      thumbnailUrl:
          json['thumbnails'] != null ? json['thumbnails'][0]['url'] : null,
    );
  }
  static List<SongModel>? parses(List list) =>
      list.map((f) => SongModel.fromMood(f)).toList();
}
