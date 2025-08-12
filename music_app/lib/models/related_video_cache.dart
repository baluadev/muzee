import 'package:isar/isar.dart';

part 'related_video_cache.g.dart';

@collection
class RelatedVideoCache {
  Id id = Isar.autoIncrement;

  late String videoId;
  late String userId;
  late DateTime cachedAt;
  late String relatedVideosJson;

  // 👉 Constructor mặc định
  RelatedVideoCache();

  // 👉 Named constructor nếu muốn khởi tạo tiện hơn
  RelatedVideoCache.withParams({
    required this.videoId,
    required this.userId,
    required this.cachedAt,
    required this.relatedVideosJson,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'cachedAt': cachedAt.toIso8601String(),
      'relatedVideosJson': relatedVideosJson,
    };
  }

  factory RelatedVideoCache.fromJson(Map<String, dynamic> json) {
    return RelatedVideoCache()
      ..id = json['id'] ?? Isar.autoIncrement
      ..videoId = json['videoId'] ?? ''
      ..userId = json['userId'] ?? ''
      ..cachedAt = json['cachedAt'] != null
          ? DateTime.tryParse(json['cachedAt']) ?? DateTime.now()
          : DateTime.now()
      ..relatedVideosJson = json['relatedVideosJson'] ?? '';
  }
}
