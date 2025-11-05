import 'dart:io';
import 'package:flutter/foundation.dart';
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
    File? imageFile,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadBookImage(
          imageFile: imageFile,
          userId: ownerId,
        );
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
    File? newImageFile,
    String? existingImageUrl,
    required String ownerId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      String? imageUrl = existingImageUrl;

      // If new image provided, upload it
      if (newImageFile != null) {
        // Delete old image if exists
        if (existingImageUrl != null) {
          await _storageService.deleteImageByUrl(existingImageUrl);
        }

        // Upload new image
        imageUrl = await _storageService.uploadBookImage(
          imageFile: newImageFile,
          userId: ownerId,
        );
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
      // Delete image from Storage if exists
      if (imageUrl != null) {
        await _storageService.deleteImageByUrl(imageUrl);
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
