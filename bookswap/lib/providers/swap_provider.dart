import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';

/// SwapProvider manages swap offer state and operations
/// Handles the swap offer lifecycle: initiate, accept, reject
class SwapProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Book> _myOffers = []; // Offers I've made or received
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Book> get myOffers => _myOffers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get offers sent by current user
  List<Book> getSentOffers(String userId) {
    return _myOffers.where((book) => book.offeredBy == userId).toList();
  }

  /// Get offers received by current user
  List<Book> getReceivedOffers(String userId) {
    return _myOffers.where((book) => book.offeredTo == userId).toList();
  }

  /// Listen to user's swap offers (both sent and received)
  void listenToUserOffers(String userId) {
    _firestoreService
        .getUserOffers(userId)
        .listen(
          (books) {
            _myOffers = books;
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load offers: $error';
            notifyListeners();
          },
        );
  }

  /// Initiate a swap offer
  /// Changes book status to Pending and records who made the offer
  Future<bool> initiateSwap({
    required String bookId,
    required String offeredBy, // Current user ID
    required String offeredTo, // Book owner ID
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Update book status to Pending
      await _firestoreService.updateBookStatus(
        bookId: bookId,
        status: SwapStatus.pending,
        offeredBy: offeredBy,
        offeredTo: offeredTo,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Accept a swap offer
  /// Changes status to Accepted
  Future<bool> acceptSwap(String bookId) async {
    _setLoading(true);
    _error = null;

    try {
      await _firestoreService.updateBookStatus(
        bookId: bookId,
        status: SwapStatus.accepted,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Reject a swap offer
  /// Changes status back to Available and clears offer data
  Future<bool> rejectSwap(String bookId) async {
    _setLoading(true);
    _error = null;

    try {
      // Reset to available and clear offer fields
      Map<String, dynamic> updates = {
        'status': SwapStatus.available.label,
        'offeredBy': null,
        'offeredTo': null,
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

  /// Cancel a pending offer (by the person who made it)
  Future<bool> cancelOffer(String bookId) async {
    return rejectSwap(bookId); // Same logic as reject
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
