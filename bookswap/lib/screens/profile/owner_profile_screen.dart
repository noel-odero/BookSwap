import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../services/firestore_service.dart';
import '../../models/book.dart';
// Avoid importing BookCard here to prevent a circular import with book_card.dart
import '../../providers/auth_provider.dart';

class OwnerProfileScreen extends StatelessWidget {
  final String userId;

  const OwnerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final isSelf = authProv.currentUser?.uid == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirestoreService().getUserStream(userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snap.data?.data() as Map<String, dynamic>?;
                final displayName = data?['displayName'] as String? ?? 'User';
                final photoUrl = data?['photoUrl'] as String?;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            (photoUrl != null && photoUrl.startsWith('http'))
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null)
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'U',
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSelf ? 'This is you' : 'Member',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 1),

            Expanded(
              child: StreamBuilder<List<Book>>(
                stream: FirestoreService().getUserBooks(userId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final books = snap.data ?? [];
                  if (books.isEmpty) {
                    return const Center(child: Text('No listings yet'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      // Lightweight listing to avoid circular imports
                      Widget leading;
                      if (book.imageUrl != null &&
                          book.imageUrl!.startsWith('data:')) {
                        try {
                          final parts = book.imageUrl!.split(',');
                          final b64 = parts.length > 1 ? parts[1] : '';
                          final bytes = base64Decode(b64);
                          leading = Image.memory(
                            bytes,
                            width: 56,
                            height: 78,
                            fit: BoxFit.cover,
                          );
                        } catch (_) {
                          leading = const SizedBox(
                            width: 56,
                            height: 78,
                            child: Icon(Icons.broken_image),
                          );
                        }
                      } else if (book.imageUrl != null) {
                        leading = Image.network(
                          book.imageUrl!,
                          width: 56,
                          height: 78,
                          fit: BoxFit.cover,
                        );
                      } else {
                        leading = const SizedBox(
                          width: 56,
                          height: 78,
                          child: Icon(Icons.book),
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: leading,
                          ),
                          title: Text(book.title),
                          subtitle: Text(
                            '${book.condition.label} • ${_timeAgo(book.createdAt)}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays >= 1) return '${diff.inDays} days ago';
    if (diff.inHours >= 1) return '${diff.inHours} hours ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }
}
