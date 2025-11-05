import 'package:flutter/material.dart';
import '../models/book.dart';
import 'package:provider/provider.dart';
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
      child: ListTile(
        leading: book.imageUrl != null
            ? Image.network(
                book.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : const SizedBox(width: 56, height: 56, child: Icon(Icons.book)),
        title: Text(book.title),
        subtitle: Text('${book.author} • ${book.condition.label}'),
        trailing: book.status == SwapStatus.available
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
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
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
                    final currentUserId = authProvider.currentUser?.uid;
                    if (currentUserId == null || book.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You must be signed in to send a swap'),
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
                          success ? 'Swap request sent' : 'Failed to send swap',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Swap'),
              )
            : Text(book.status.label),
        onTap: () {
          // Show details
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
                                    if (!context.mounted) return;
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    final currentUserId =
                                        authProvider.currentUser?.uid;
                                    if (currentUserId == null ||
                                        book.id == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
      ),
    );
  }
}
