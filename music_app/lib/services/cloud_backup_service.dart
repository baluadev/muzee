import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:muzee/main.dart' show logger;
import 'package:muzee/services/data_manager.dart';
import 'package:muzee/services/library_store.dart';

/// Backs the library up to Firestore under the signed-in Google account, as
/// Muzee 1.x did (`users/{email}`). Each `user` box key is its own document
/// in `backup_v2`, which keeps documents under Firestore's 1 MiB limit.
///
/// Muzee 1.x backups (`users/{email}/backup`) are not read: they held the
/// Isar tables without playlist contents. The data that matters moves over
/// on the device instead (see legacy_migration.dart).
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  CollectionReference<Map<String, dynamic>> _backup(String email) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('backup_v2');

  Future<void> backup(String email) async {
    final user = Hive.box('user');
    final batch = FirebaseFirestore.instance.batch();
    for (final key in libraryKeys) {
      batch.set(_backup(email).doc(key), {
        'data': toJsonSafe(user.get(key, defaultValue: [])),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// When the last backup was made, or null if there is none.
  Future<DateTime?> lastBackupTime(String email) async {
    final doc = await _backup(email).doc(libraryKeys.first).get();
    final at = doc.data()?['updatedAt'];
    return at is Timestamp ? at.toDate() : null;
  }

  /// Replaces the library with the backup. Returns false if there is none.
  Future<bool> restore(String email) async {
    final snapshot = await _backup(email).get();
    final docs = {for (final d in snapshot.docs) d.id: d.data()};
    if (docs.isEmpty) return false;
    for (final key in libraryKeys) {
      final data = docs[key]?['data'];
      if (data is List) {
        await addOrUpdateData('user', key, data);
      } else {
        logger.log('Cloud backup has no "$key"; keeping the local one');
      }
    }
    reloadLibraryFromStorage();
    return true;
  }
}
