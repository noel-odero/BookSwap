// dart:io intentionally not imported here to keep web compatibility; StorageService handles platform specifics
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// BooksProvider manages book listings state
/// Handles CRUD operations and real-time updates
class BooksProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<Book> _allBooks = [];
  List<Book> _userBooks = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Book> get allBooks => _allBooks;
  List<Book> get userBooks => _userBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get books available for browsing (excluding user's own books)
  List<Book> getBrowseBooks(String currentUserId) {
    return _allBooks
        .where(
          (book) =>
              book.ownerId != currentUserId &&
              book.status == SwapStatus.available,
        )
        .toList();
  }

  /// Listen to all books stream
  /// StreamSubscription automatically updates _allBooks when Firestore changes
  void listenToAllBooks() {
    _firestoreService.getAllBooks().listen(
      (books) {
        _allBooks = books;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load books: $error';
        notifyListeners();
      },
    );
  }

  /// Listen to user's own books
  void listenToUserBooks(String userId) {
    _firestoreService
        .getUserBooks(userId)
        .listen(
          (books) {
            _userBooks = books;
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load your books: $error';
            notifyListeners();
          },
        );
  }

  /// CREATE: Add new book listing
  Future<bool> addBook({
    required String title,
    required String author,
    required String swapFor,
    required BookCondition condition,
    required String ownerId,
    required String ownerName,
    dynamic imageFile,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // If an image is provided, encode it as a base64 data URL and store
      // directly in the Firestore document. This lets the app work without
      // Firebase Storage configured.
      String? imageUrl;
      if (imageFile != null) {
        Uint8List bytes;
        if (imageFile is XFile) {
          bytes = await imageFile.readAsBytes();
        } else if (imageFile is Uint8List) {
          bytes = imageFile;
        } else {
          // Try to call readAsBytes if available (duck typing)
          try {
            final dynamic f = imageFile;
            final result = await f.readAsBytes();
            if (result is Uint8List) {
              bytes = result;
            } else {
              throw ArgumentError('Unsupported image bytes result');
            }
          } catch (e) {
            throw ArgumentError(
              'Unsupported image type: ${imageFile.runtimeType}',
            );
          }
        }

        final base64Str = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64Str';
      }

      // Create book object
      Book book = Book(
        title: title,
        author: author,
        swapFor: swapFor,
        condition: condition,
        imageUrl: imageUrl,
        ownerId: ownerId,
        ownerName: ownerName,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestoreService.createBook(book);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// UPDATE: Edit existing book
  Future<bool> updateBook({
    required String bookId,
    required String title,
    required String author,
    required String swapFor,
    required BookCondition condition,
    dynamic newImageFile,
    String? existingImageUrl,
    required String ownerId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      String? imageUrl = existingImageUrl;

      // If new image provided, encode to base64 and replace. If existing
      // image was stored in Cloud Storage (non-data URL), attempt deletion.
      if (newImageFile != null) {
        // Delete old image from storage ONLY if it looks like a remote URL
        if (existingImageUrl != null && !existingImageUrl.startsWith('data:')) {
          try {
            await _storageService.deleteImageByUrl(existingImageUrl);
          } catch (_) {
            // ignore delete failures; we still proceed to replace image
          }
        }

        Uint8List bytes;
        if (newImageFile is XFile) {
          bytes = await newImageFile.readAsBytes();
        } else if (newImageFile is Uint8List) {
          bytes = newImageFile;
        } else {
          try {
            final dynamic f = newImageFile;
            final result = await f.readAsBytes();
            if (result is Uint8List) {
              bytes = result;
            } else {
              throw ArgumentError('Unsupported image bytes result');
            }
          } catch (e) {
            throw ArgumentError(
              'Unsupported image type: ${newImageFile.runtimeType}',
            );
          }
        }

        final base64Str = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64Str';
      }

      // Update Firestore document
      Map<String, dynamic> updates = {
        'title': title,
        'author': author,
        'swapFor': swapFor,
        'condition': condition.label,
        'imageUrl': imageUrl,
      };

      await _firestoreService.updateBook(bookId, updates);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// DELETE: Remove book listing
  Future<bool> deleteBook(String bookId, String? imageUrl) async {
    _setLoading(true);
    _error = null;

    try {
      // Delete image from Storage if exists and looks like a remote URL
      if (imageUrl != null && !imageUrl.startsWith('data:')) {
        try {
          await _storageService.deleteImageByUrl(imageUrl);
        } catch (_) {
          // ignore failures
        }
      }

      // Delete from Firestore
      await _firestoreService.deleteBook(bookId);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
