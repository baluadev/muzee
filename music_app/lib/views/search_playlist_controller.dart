import 'package:flutter/material.dart';
import 'package:muzee/models/playlist_model.dart';

class SearchPlaylistController extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;
  List<PlaylistModel> _items = [];
  List<PlaylistModel> get items => _items;

  ///
  ///
  ///

  void editing(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }

  void filterItems(List<PlaylistModel> items) {
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