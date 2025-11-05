import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/books_provider.dart';
import '../../models/book.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final booksProvider = context.watch<BooksProvider>();
    final books = booksProvider.userBooks;

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: booksProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
          ? const Center(child: Text('No listings yet'))
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final b = books[index];
                return ListTile(
                  leading: b.imageUrl != null
                      ? Image.network(
                          b.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.book),
                        ),
                  title: Text(b.title),
                  subtitle: Text('${b.author} • ${b.condition.label}'),
                );
              },
            ),
    );
  }
}
