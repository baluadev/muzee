class CategoryModel {
  CategoryModel({
    this.name,
    this.code,
    this.thumb,
    this.params,
    this.title,
  });

  CategoryModel.fromJson(Map json) {
    name = json['name'];
    code = json['code'];
    thumb = json['thumb'];
    params = json['params'];
    title = json['title'];
  }
  CategoryModel.fromMood(Map json) {
    name = json['name'];
    code = json['code'];
    thumb = json['thumbnails'] != null ? json['thumbnails'][0]['url'] : null;
    params = json['params'];
    title = json['title'];
  }

  String? name;
  String? code;
  String? thumb;
  String? params;
  String? title;
  static List<CategoryModel>? parses(List list) =>
      list.map((f) => CategoryModel.fromMood(f)).toList();
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['name'] = name;
    data['code'] = code;
    data['thumb'] = thumb;
    data['params'] = params;
    data['title'] = title;
    return data;
  }
}
