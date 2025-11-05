import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file for a book and returns its download URL
  Future<String?> uploadBookImage({
    required File imageFile,
    required String userId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('books').child(userId).child(fileName);
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();
    return url;
  }

  /// Delete an image given its full download URL
  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // ignore errors for now (e.g., already deleted)
    }
  }
}
