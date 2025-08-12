import 'dart:convert';

extension StringExtension on String {
  String get toDotEnd => '${substring(0, length - 4)}***';
  Map<String, dynamic> get toMap => jsonDecode(this);
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String formatLicensePlate() {
    if (length < 5) {
      return this; // Biển số 4 số giữ nguyên
    } else if (length == 5) {
      return '${substring(0, 3)}.${substring(3)}'; // Chèn dấu '.'
    } else {
      return ''; // Nếu không phải 4 hoặc 5 số
    }
  }
}

extension MapUtils on Map {
  String get toText => jsonEncode(this);
}
