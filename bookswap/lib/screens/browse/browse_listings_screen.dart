import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/books_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/book_card.dart';
import '../../models/book.dart';

class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({Key? key}) : super(key: key);

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to books when this screen is created
    final booksProvider = context.read<BooksProvider>();
    booksProvider.listenToAllBooks();
  }

  @override
  Widget build(BuildContext context) {
    final booksProvider = context.watch<BooksProvider>();
    final authProvider = context.watch<AuthProvider>();

    final userId = authProvider.currentUser?.uid ?? '';
    final browseBooks = userId.isNotEmpty
        ? booksProvider.getBrowseBooks(userId)
        : booksProvider.allBooks.where((b) => b.status == SwapStatus.available).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
      ),
      body: booksProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : browseBooks.isEmpty
              ? const Center(child: Text('No listings found'))
              : RefreshIndicator(
                  onRefresh: () async {
                    // trigger a refresh by re-listening
                    booksProvider.listenToAllBooks();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: browseBooks.length,
                    itemBuilder: (context, index) {
                      final book = browseBooks[index];
                      return BookCard(book: book);
                    },
                  ),
                ),
    );
  }
}
