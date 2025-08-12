import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import 'package:muzee/models/artist_model.dart';
import 'package:muzee/models/playlist_model.dart';
import 'package:muzee/models/related_video_cache.dart';
import 'package:muzee/models/search_history_model.dart';
import 'package:muzee/models/song_model.dart';
import 'package:muzee/services/database/db_service.dart';

class FirestoreService {
  static final FirestoreService inst = FirestoreService._internal();
  FirestoreService._internal();

  final _firestore = FirebaseFirestore.instance;

  // Tạo user nếu chưa tồn tại
  Future<void> createUserIfNotExist(String email) async {
    final docRef = _firestore.collection('users').doc(email);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Tạo document placeholder hợp lệ
      await docRef
          .collection('playlists')
          .doc('placeholder')
          .set({'created': true});
      await docRef
          .collection('songs')
          .doc('placeholder')
          .set({'created': true});
    }
  }

  // Helper: Lưu dữ liệu dạng danh sách json vào Firestore
  Future<void> _saveBackup(
      String email, String key, List<Map<String, dynamic>> data) async {
    await _firestore
        .collection('users')
        .doc(email)
        .collection('backup')
        .doc(key)
        .set({
      'data': data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Helper: Tải dữ liệu dạng danh sách json từ Firestore
  Future<List<Map<String, dynamic>>> _loadBackup(
      String email, String key) async {
    final snap = await _firestore
        .collection('users')
        .doc(email)
        .collection('backup')
        .doc(key)
        .get();

    final data = snap.data()?['data'];
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      return [];
    }
  }

  // Backup toàn bộ dữ liệu từ Isar lên Firestore
  Future<void> backupAllToFirestore(String email) async {
    final isar = DBService.inst.isar;

    final playlists = await isar.playlistModels.where().findAll();
    final songs = await isar.songModels.where().findAll();
    final artists = await DBService.inst.getAllArtists();
    final searches = await DBService.inst.getRecentSearches(limit: 1000);
    final caches = await isar.relatedVideoCaches.where().findAll();

    await _saveBackup(
        email, 'playlist_models', playlists.map((e) => e.toJson()).toList());
    await _saveBackup(
        email, 'song_models', songs.map((e) => e.toJson()).toList());
    await _saveBackup(
        email, 'artist_models', artists.map((e) => e.toJson()).toList());
    await _saveBackup(email, 'search_history_models',
        searches.map((e) => e.toJson()).toList());
    await _saveBackup(
        email, 'related_video_caches', caches.map((e) => e.toJson()).toList());
  }

  // Restore dữ liệu từ Firestore về Isar
  Future<void> restoreAllFromFirestore(String email) async {
    final isar = DBService.inst.isar;

    final playlists = await _loadBackup(email, 'playlist_models');
    final songs = await _loadBackup(email, 'song_models');
    final artists = await _loadBackup(email, 'artist_models');
    final searches = await _loadBackup(email, 'search_history_models');
    final caches = await _loadBackup(email, 'related_video_caches');

    await isar.writeTxn(() async {
      await isar.playlistModels.clear();
      await isar.songModels.clear();
      await isar.artistModels.clear();
      await isar.searchHistoryModels.clear();
      await isar.relatedVideoCaches.clear();

      for (var json in playlists) {
        await isar.playlistModels.put(PlaylistModel.fromJson(json));
      }
      for (var json in songs) {
        await isar.songModels.put(SongModel.fromJson(json));
      }
      for (var json in artists) {
        await isar.artistModels.put(ArtistModel.fromJson2(json));
      }
      for (var json in searches) {
        await isar.searchHistoryModels.put(SearchHistoryModel.fromJson(json));
      }
      for (var json in caches) {
        await isar.relatedVideoCaches.put(RelatedVideoCache.fromJson(json));
      }
    });
  }
}
