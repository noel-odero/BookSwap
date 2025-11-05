import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the condition of a book
enum BookCondition { newGood, good, fair }

extension BookConditionLabel on BookCondition {
  String get label {
    switch (this) {
      case BookCondition.newGood:
        return 'New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.fair:
        return 'Fair';
    }
  }

  static BookCondition fromLabel(String? label) {
    switch (label) {
      case 'New':
        return BookCondition.newGood;
      case 'Good':
        return BookCondition.good;
      default:
        return BookCondition.fair;
    }
  }
}

/// Swap status for a book listing
enum SwapStatus { available, pending, accepted }

extension SwapStatusLabel on SwapStatus {
  String get label {
    switch (this) {
      case SwapStatus.available:
        return 'available';
      case SwapStatus.pending:
        return 'pending';
      case SwapStatus.accepted:
        return 'accepted';
    }
  }

  static SwapStatus fromLabel(String? label) {
    switch (label) {
      case 'pending':
        return SwapStatus.pending;
      case 'accepted':
        return SwapStatus.accepted;
      default:
        return SwapStatus.available;
    }
  }
}

class Book {
  final String? id;
  final String title;
  final String author;
  final String swapFor;
  final BookCondition condition;
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final SwapStatus status;
  final String? offeredBy;
  final String? offeredTo;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.swapFor,
    required this.condition,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.status = SwapStatus.available,
    this.offeredBy,
    this.offeredTo,
  });

  factory Book.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Book(
      id: doc.id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      swapFor: data['swapFor'] as String? ?? '',
      condition: BookConditionLabel.fromLabel(data['condition'] as String?),
      imageUrl: data['imageUrl'] as String?,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SwapStatusLabel.fromLabel(data['status'] as String?),
      offeredBy: data['offeredBy'] as String?,
      offeredTo: data['offeredTo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'swapFor': swapFor,
      'condition': condition.label,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.label,
      'offeredBy': offeredBy,
      'offeredTo': offeredTo,
    };
  }
}
