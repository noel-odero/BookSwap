import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/swap_provider.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Listings'),
              Tab(text: 'My Offers'),
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
                      return BookCard(book: b);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
