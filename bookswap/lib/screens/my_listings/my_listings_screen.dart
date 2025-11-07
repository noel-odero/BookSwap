import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/swap_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../post_book/post_book_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  Widget build(BuildContext context) {
    final booksProvider = context.watch<BooksProvider>();
    final swapProvider = context.watch<SwapProvider>();
    final books = booksProvider.userBooks;
    final offers = swapProvider.myOffers;

    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final hasIncomingOffers = currentUser != null
        ? offers.any(
            (b) =>
                b.ownerId == currentUser.uid && b.status == SwapStatus.pending,
          )
        : false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Listings'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('My Offers'),
                    if (hasIncomingOffers) const SizedBox(width: 8),
                    if (hasIncomingOffers)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostBookScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            // Listings tab
            booksProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : books.isEmpty
                ? const Center(child: Text('No listings yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final b = books[index];
                      return BookCard(book: b);
                    },
                  ),

            // My Offers tab
            swapProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : offers.isEmpty
                ? const Center(child: Text('No offers yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final b = offers[index];
                      final currentUser = Provider.of<AuthProvider>(
                        context,
                      ).currentUser;
                      final isOwner =
                          currentUser != null && currentUser.uid == b.ownerId;

                      // If current user is the owner and there's a pending offer,
                      // show Accept / Reject buttons so the owner can respond.
                      if (isOwner && b.status == SwapStatus.pending) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BookCard(book: b),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: swapProvider.isLoading
                                          ? null
                                          : () async {
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              final ok = await swapProvider
                                                  .acceptSwap(b.id!);
                                              if (!mounted) return;
                                              if (ok) {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Offer accepted',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      swapProvider.error ??
                                                          'Failed to accept offer',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: swapProvider.isLoading
                                          ? null
                                          : () async {
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              final ok = await swapProvider
                                                  .rejectSwap(b.id!);
                                              if (!mounted) return;
                                              if (ok) {
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Offer rejected',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      swapProvider.error ??
                                                          'Failed to reject offer',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Otherwise show a normal book card
                      return BookCard(book: b);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
