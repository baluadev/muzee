import 'package:isar/isar.dart';
part 'user.g.dart';

@collection
class User {
  Id? id = Isar.autoIncrement;
  String? name;
  String? picture;
  String? email;
  String? phone;
  String? accessToken;
  String? refreshToken;

  User({
    this.id,
    this.name,
    this.picture,
    this.email,
    this.phone,
    this.accessToken,
    this.refreshToken,
  });

  User copyWith({
    String? name,
    String? picture,
    String? email,
    String? phone,
    String? accessToken,
    String? refreshToken,
  }) {
    return User(
      email: email ?? this.email,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      phone: phone ?? this.phone,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      id: id, // Keep the same ID if not provided
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      picture: json['picture'],
      email: json['email'],
      phone: json['phone'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'picture': picture,
      'email': email,
      'phone': phone,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
