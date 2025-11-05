import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file for a book and returns its download URL
  /// Accepts a [File] (mobile) or [XFile] (web) or raw bytes.
  Future<String?> uploadBookImage({
    required dynamic imageFile,
    required String userId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('books').child(userId).child(fileName);

    try {
      if (kIsWeb) {
        // On web, imageFile is expected to be an XFile or Uint8List
        if (imageFile is XFile) {
          final bytes = await imageFile.readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else if (imageFile is Uint8List) {
          await ref.putData(
            imageFile,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          throw ArgumentError(
            'Unsupported image type for web: ${imageFile.runtimeType}',
          );
        }
      } else {
        // Mobile/desktop: accept dart:io File or XFile
        if (imageFile is File) {
          await ref.putFile(imageFile);
        } else if (imageFile is XFile) {
          final file = File(imageFile.path);
          await ref.putFile(file);
        } else if (imageFile is Uint8List) {
          await ref.putData(
            imageFile,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          throw ArgumentError(
            'Unsupported image type: ${imageFile.runtimeType}',
          );
        }
      }

      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      // Common failure on web: CORS/preflight blocked by the storage service.
      // Surface a clearer message so the UI can display guidance to the developer/user.
      throw Exception(
        'Storage upload failed: ${e.message ?? e.code}. If you are running on web, this is often caused by missing CORS configuration on your Cloud Storage bucket. See https://cloud.google.com/storage/docs/configuring-cors',
      );
    } catch (e) {
      throw Exception(e.toString());
    }
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
