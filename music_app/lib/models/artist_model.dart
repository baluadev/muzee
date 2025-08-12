import 'package:isar/isar.dart';
part 'artist_model.g.dart';

@collection
class ArtistModel {
  Id id = Isar.autoIncrement;
  final String? country;
  final String? name;
  final String? imgPath;
  final String? channelId;
  final String? subscriberCount;
  final String? videoCount;

  /// Thời điểm cập nhật lần cuối
  DateTime? updatedAt;
  ArtistModel({
    this.country,
    this.name,
    this.imgPath,
    this.channelId,
    this.subscriberCount,
    this.videoCount,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'name': name,
      'imgPath': imgPath,
      'channelId': channelId,
      'subscriberCount': subscriberCount,
      'videoCount': videoCount,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ArtistModel.fromJson2(Map<String, dynamic> json) {
    return ArtistModel(
      country: json['country'] as String?,
      name: json['name'] as String?,
      imgPath: json['imgPath'] as String?, // lưu đúng tên trường
      channelId: json['channelId'] as String?,
      subscriberCount: json['subscriberCount'] as String?,
      videoCount: json['videoCount'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    )..id = json['id'] ?? Isar.autoIncrement;
  }

  factory ArtistModel.fromJson(Map json) {
    return ArtistModel(
      country: json['country'] as String,
      name: json['name'] as String,
      imgPath: json['img'] as String,
      channelId: json['channel_id'],
    );
  }
}
