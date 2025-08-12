import 'package:flutter/material.dart';
import 'package:muzee/models/song_model.dart';

class SearchSongModel extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;
  List<SongModel> _items = [];
  List<SongModel> get items => _items;

  ///
  ///
  ///

  void editing(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }

  void filterItems(List<SongModel> items) {
    _items = items;
    notifyListeners();
  }

  void reversedItems() {
    _items = _items.reversed.toList();
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
  }
}