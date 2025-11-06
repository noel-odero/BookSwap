import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
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
      // If Storage is not available (no bucket / CORS / emulator not running),
      // fallback to encoding the image as a base64 data URL and return that
      // so the app can still persist images without Cloud Storage.
      try {
        Uint8List bytes;
        if (imageFile is XFile) {
          bytes = await imageFile.readAsBytes();
        } else if (imageFile is File) {
          bytes = await imageFile.readAsBytes();
        } else if (imageFile is Uint8List) {
          bytes = imageFile;
        } else {
          throw Exception(
            'Unsupported image type for fallback: ${imageFile.runtimeType}',
          );
        }

        final base64Str = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64Str';
        return dataUrl;
      } catch (_) {
        throw Exception(
          'Storage upload failed: ${e.message ?? e.code}. Also failed to fallback to base64 encoding.',
        );
      }
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
