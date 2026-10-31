// Muzee 1.x Isar model, kept only so the 2.x migration can read the old
// database (legacy_migration.dart). Don't change it: the schema has to match
// what 1.x wrote. The .g.dart next to it is 1.x's generated code.

import 'package:isar_community/isar.dart';

part 'search_history_model.g.dart';

@collection
class SearchHistoryModel {
  Id id = Isar.autoIncrement;
  late String keyword;
  late String type;
  DateTime createdAt = DateTime.now();
  int searchCount = 1;

  // 👉 Constructor mặc định
  SearchHistoryModel();

  // Optional: constructor có params nếu muốn
  SearchHistoryModel.withParams({
    required this.keyword,
    required this.type,
    DateTime? createdAt,
    this.searchCount = 1,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'searchCount': searchCount,
    };
  }

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) {
    return SearchHistoryModel()
      ..id = json['id'] ?? Isar.autoIncrement
      ..keyword = json['keyword'] ?? ''
      ..type = json['type'] ?? ''
      ..createdAt = json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now()
      ..searchCount = json['searchCount'] ?? 1;
  }
}
