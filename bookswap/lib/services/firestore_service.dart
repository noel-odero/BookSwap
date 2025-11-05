import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class FirestoreService {
  final CollectionReference _booksRef;

  FirestoreService()
    : _booksRef = FirebaseFirestore.instance.collection('books');

  /// Stream of all books
  Stream<List<Book>> getAllBooks() {
    return _booksRef.snapshots().map(
      (snap) => snap.docs.map((d) => Book.fromDoc(d)).toList(growable: false),
    );
  }

  /// Stream of books belonging to a user
  Stream<List<Book>> getUserBooks(String userId) {
    return _booksRef
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Book.fromDoc(d)).toList());
  }

  /// Stream of offers involving user (either offeredBy or offeredTo)
  /// Firestore doesn't support OR easily, so we listen to all and filter.
  Stream<List<Book>> getUserOffers(String userId) {
    return _booksRef.snapshots().map((snap) {
      return snap.docs
          .map((d) => Book.fromDoc(d))
          .where((b) => b.offeredBy == userId || b.offeredTo == userId)
          .toList();
    });
  }

  Future<void> createBook(Book book) async {
    await _booksRef.add(book.toMap());
  }

  Future<void> updateBook(String bookId, Map<String, dynamic> updates) async {
    await _booksRef.doc(bookId).update(updates);
  }

  Future<void> updateBookStatus({
    required String bookId,
    required SwapStatus status,
    String? offeredBy,
    String? offeredTo,
  }) async {
    final data = <String, dynamic>{'status': status.label};
    if (offeredBy != null) data['offeredBy'] = offeredBy;
    if (offeredTo != null) data['offeredTo'] = offeredTo;
    await _booksRef.doc(bookId).update(data);
  }

  Future<void> deleteBook(String bookId) async {
    await _booksRef.doc(bookId).delete();
  }
}
