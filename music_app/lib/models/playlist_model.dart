import 'package:isar/isar.dart';

import 'song_model.dart';

part 'playlist_model.g.dart';

@collection
class PlaylistModel {
  Id id = Isar.autoIncrement;

  String? title;
  String? playlistId;
  String? thumbnailUrl;
  String? artist;
  bool isYoutube;
  late DateTime createdAt;

  final songs = IsarLinks<SongModel>();
  // Field tạm không lưu vào Isar
  @ignore
  List<SongModel> tempSongs = [];

  PlaylistModel({
    this.title,
    this.playlistId,
    this.thumbnailUrl,
    this.artist,
    this.isYoutube = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'playlistId': playlistId,
      'thumbnailUrl': thumbnailUrl,
      'artist': artist,
      'isYoutube': isYoutube,
      'createdAt': createdAt.toIso8601String(),
      // Không serialize 'songs' vì IsarLinks không hỗ trợ
    };
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      title: json['title'],
      playlistId: json['playlistId'],
      thumbnailUrl: json['thumbnailUrl'],
      artist: json['artist'],
      isYoutube: json['isYoutube'] ?? false,
    )
      ..id = json['id']
      ..createdAt =
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now();
  }

  factory PlaylistModel.fromMood(Map json) {
    return PlaylistModel(
      playlistId: json['playlistId'],
      title: json['title'],
      thumbnailUrl:
          json['thumbnails'] != null ? json['thumbnails'][0]['url'] : null,
    );
  }

  static List<PlaylistModel>? parses(List list) =>
      list.map((f) => PlaylistModel.fromMood(f)).toList();
}
