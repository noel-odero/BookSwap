import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class FirestoreService {
  final CollectionReference _booksRef;
  final CollectionReference _chatsRef;
  final CollectionReference _usersRef;
  // userReadStatus root is accessed per-user (userReadStatus/{userId}/chats/{chatId})
  // we'll construct references ad-hoc where needed

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
    List<String>? recipients,
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
      // Also update the chat meta
      await _chatsRef.doc(chatId).update({
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
        // store per-user last read timestamps in a map field 'lastRead' for sender
        'lastRead.$senderId': FieldValue.serverTimestamp(),
      });

      // If recipients were provided, increment their per-user unread counters
      if (recipients != null && recipients.isNotEmpty) {
        for (final r in recipients) {
          if (r == senderId) continue;
          await _incrementUserUnread(userId: r, chatId: chatId);
        }
      }
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

  /// Mark a chat as read for a specific user by updating the per-user lastRead map
  Future<void> markChatRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      // Update chat-level lastRead map
      await _chatsRef.doc(chatId).update({
        'lastRead.$userId': FieldValue.serverTimestamp(),
      });
      // Reset per-user unread counter in userReadStatus
      await _resetUserUnread(userId: userId, chatId: chatId);
    } catch (e) {
      // ignore: avoid_print
      print('FirestoreService.markChatRead: failed to mark read $e');
    }
  }

  // -------------------- userReadStatus helpers --------------------

  CollectionReference _userChatsRef(String userId) {
    return FirebaseFirestore.instance
        .collection('userReadStatus')
        .doc(userId)
        .collection('chats');
  }

  Future<void> _incrementUserUnread({
    required String userId,
    required String chatId,
  }) async {
    final docRef = _userChatsRef(userId).doc(chatId);
    try {
      await docRef.set({
        'chatId': chatId,
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('FirestoreService._incrementUserUnread: $e');
    }
  }

  Future<void> _resetUserUnread({
    required String userId,
    required String chatId,
  }) async {
    final docRef = _userChatsRef(userId).doc(chatId);
    try {
      await docRef.set({
        'chatId': chatId,
        'lastRead': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore: avoid_print
      print('FirestoreService._resetUserUnread: $e');
    }
  }

  /// Stream the user's read-status documents under userReadStatus/{userId}/chats
  Stream<List<QueryDocumentSnapshot>> getUserReadStatuses(String userId) {
    return _userChatsRef(userId).snapshots().map((snap) => snap.docs);
  }
}
