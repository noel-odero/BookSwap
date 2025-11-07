import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class FirestoreService {
  final CollectionReference _booksRef;
  final CollectionReference _chatsRef;
  final CollectionReference _usersRef;

  FirestoreService()
    : _booksRef = FirebaseFirestore.instance.collection('books'),
      _chatsRef = FirebaseFirestore.instance.collection('chats'),
      _usersRef = FirebaseFirestore.instance.collection('users');

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
    try {
      // Log the attempted update for debugging (web console)
      // ignore: avoid_print
      print('FirestoreService.updateBookStatus: updating $bookId with $data');
      await _booksRef.doc(bookId).update(data);
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print(
        'FirestoreService.updateBookStatus: FirebaseException ${e.code} ${e.message}',
      );
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('FirestoreService.updateBookStatus: unexpected error $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    await _booksRef.doc(bookId).delete();
  }

  // -------------------- Chats --------------------

  /// Create or return a deterministic chatId for two participants
  String chatIdFor(String a, String b) {
    final ordered = [a, b]..sort();
    return '${ordered[0]}_${ordered[1]}';
  }

  /// Ensure chat document exists with participants list
  Future<void> ensureChatExists(
    String chatId,
    List<String> participants,
  ) async {
    final doc = _chatsRef.doc(chatId);
    // Avoid reading the document first: some security rules block reads
    // on non-existent chat docs even though creation would be allowed.
    // Directly attempt to create/set the document; if it already exists
    // this will overwrite with equivalent data (participants remain same).
    await doc.set({
      'participants': participants,
      'lastMessage': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream chats that include the given userId
  Stream<List<QueryDocumentSnapshot>> getUserChats(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Stream messages for a chat, ordered by timestamp
  Stream<List<QueryDocumentSnapshot>> getChatMessages(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// Get a single user document snapshot
  Future<DocumentSnapshot> getUserDoc(String userId) async {
    return await _usersRef.doc(userId).get();
  }

  /// Stream a user document
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _usersRef.doc(userId).snapshots();
  }

  /// Send a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final messagesRef = _chatsRef.doc(chatId).collection('messages');
    final data = {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
    try {
      // ignore: avoid_print
      print(
        'FirestoreService.sendMessage: chat=$chatId sender=$senderId text=$text',
      );
      // Add message
      await messagesRef.add(data);
      // Update chat meta
      await _chatsRef.doc(chatId).update({
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print(
        'FirestoreService.sendMessage: FirebaseException ${e.code} ${e.message}',
      );
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('FirestoreService.sendMessage: unexpected error $e');
      rethrow;
    }
  }
}
