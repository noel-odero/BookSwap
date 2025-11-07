import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../providers/books_provider.dart';
import '../screens/chats/conversation_screen.dart';
import '../screens/profile/owner_profile_screen.dart';
import '../providers/swap_provider.dart';
import '../providers/auth_provider.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final swapProvider = context.read<SwapProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          // keep the existing onTap behaviour from before (show details)
          showModalBottomSheet(
            context: context,
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('By ${book.author}'),
                  const SizedBox(height: 8),
                  Text('Condition: ${book.condition.label}'),
                  const SizedBox(height: 8),
                  Text('Owner: ${book.ownerName}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: book.status == SwapStatus.available
                              ? () async {
                                  // Capture dependencies before awaiting dialogs to
                                  // avoid using context across async gaps.
                                  final authProvider =
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );

                                  Navigator.pop(context);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Swap'),
                                      content: Text(
                                        'Send a swap request to ${book.ownerName}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Send'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    final currentUserId =
                                        authProvider.currentUser?.uid;
                                    if (currentUserId == null ||
                                        book.id == null) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'You must be signed in to send a swap',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final success = await swapProvider
                                        .initiateSwap(
                                          bookId: book.id!,
                                          offeredBy: currentUserId,
                                          offeredTo: book.ownerId,
                                        );

                                    if (!context.mounted) return;

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Swap request sent'
                                              : 'Failed to send swap',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: Text(
                            book.status == SwapStatus.available
                                ? 'Swap'
                                : book.status.label,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // image with optional pending-offer badge (if owner sees a pending offer)
              Builder(
                builder: (context) {
                  final currentUserId = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).currentUser?.uid;
                  final showOfferBadge =
                      currentUserId != null &&
                      currentUserId == book.ownerId &&
                      book.status == SwapStatus.pending;

                  Widget imageWidget;
                  if (book.imageUrl != null) {
                    final url = book.imageUrl!;
                    if (url.startsWith('data:')) {
                      try {
                        final parts = url.split(',');
                        final b64 = parts.length > 1 ? parts[1] : '';
                        final bytes = base64Decode(b64);
                        imageWidget = Image.memory(
                          bytes,
                          width: 68,
                          height: 96,
                          fit: BoxFit.cover,
                        );
                      } catch (_) {
                        imageWidget = const SizedBox(
                          width: 68,
                          height: 96,
                          child: Icon(Icons.broken_image),
                        );
                      }
                    } else {
                      imageWidget = Image.network(
                        url,
                        width: 68,
                        height: 96,
                        fit: BoxFit.cover,
                      );
                    }
                  } else {
                    imageWidget = const SizedBox(
                      width: 68,
                      height: 96,
                      child: Icon(Icons.book),
                    );
                  }

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imageWidget,
                      ),
                      if (showOfferBadge)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 6,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 12),

              // text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Owner row: avatar + name + condition
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirestoreService().getUserStream(book.ownerId),
                      builder: (context, snap) {
                        String displayName = book.ownerName;
                        String? photoUrl;
                        if (snap.hasData) {
                          final data =
                              snap.data!.data() as Map<String, dynamic>?;
                          if (data != null) {
                            displayName =
                                (data['displayName'] as String?) ?? displayName;
                            photoUrl = data['photoUrl'] as String?;
                          }
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OwnerProfileScreen(userId: book.ownerId),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    (photoUrl != null &&
                                        photoUrl.startsWith('http'))
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null)
                                    ? Text(
                                        _initials(displayName),
                                        style: const TextStyle(fontSize: 10),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '$displayName • ${book.condition.label}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(book.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // actions
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 92,
                    child: book.status == SwapStatus.available
                        ? ElevatedButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Swap'),
                                  content: Text(
                                    'Send a swap request to ${book.ownerName}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Send'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                if (!context.mounted) return;
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final currentUserId =
                                    authProvider.currentUser?.uid;
                                if (currentUserId == null || book.id == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You must be signed in to send a swap',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final success = await swapProvider.initiateSwap(
                                  bookId: book.id!,
                                  offeredBy: currentUserId,
                                  offeredTo: book.ownerId,
                                );

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Swap request sent'
                                          : 'Failed to send swap',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Swap'),
                          )
                        : Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.status.label,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final currentUserId = authProvider.currentUser?.uid;
                      if (currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sign in to message')),
                        );
                        return;
                      }
                      final peerId = book.ownerId;
                      final chatId = FirestoreService().chatIdFor(
                        currentUserId,
                        peerId,
                      );
                      final navigator = Navigator.of(context);
                      await FirestoreService().ensureChatExists(chatId, [
                        currentUserId,
                        peerId,
                      ]);
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            chatId: chatId,
                            peerId: peerId,
                          ),
                        ),
                      );
                    },
                  ),
                  // Delete button for owners
                  Builder(
                    builder: (context) {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final currentUserId = authProvider.currentUser?.uid;
                      if (currentUserId != null &&
                          currentUserId == book.ownerId) {
                        return IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            // Capture dependencies before showing dialog to avoid
                            // using BuildContext after await.
                            final booksProv = Provider.of<BooksProvider>(
                              context,
                              listen: false,
                            );
                            final messenger = ScaffoldMessenger.of(context);

                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete listing'),
                                content: const Text(
                                  'Are you sure you want to delete this listing? This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true) return;

                            final success = await booksProv.deleteBook(
                              book.id ?? '',
                              book.imageUrl,
                            );
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Listing deleted'
                                      : (booksProv.error ?? 'Failed to delete'),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
