import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/books_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/book.dart';

class PostBookScreen extends StatefulWidget {
  final Book? bookToEdit;

  const PostBookScreen({Key? key, this.bookToEdit}) : super(key: key);

  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _swapForCtrl = TextEditingController();
  BookCondition _condition = BookCondition.good;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _handlePost() async {
    if (!_formKey.currentState!.validate()) return;

    final authProv = context.read<AuthProvider>();
    final currentUser = authProv.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be signed in')));
      return;
    }

    setState(() => _isSubmitting = true);

    final booksProv = context.read<BooksProvider>();
    bool success = false;

    if (widget.bookToEdit == null) {
      success = await booksProv.addBook(
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        swapFor: _swapForCtrl.text.trim(),
        condition: _condition,
        ownerId: currentUser.uid,
        ownerName: currentUser.displayName ?? 'Unknown',
        imageFile: _imageFile,
      );
    } else {
      // Update existing
      success = await booksProv.updateBook(
        bookId: widget.bookToEdit!.id ?? '',
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        swapFor: _swapForCtrl.text.trim(),
        condition: _condition,
        newImageFile: _imageFile,
        existingImageUrl: widget.bookToEdit!.imageUrl,
        ownerId: currentUser.uid,
      );
    }

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(booksProv.error ?? 'Failed to post book')),
      );
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _swapForCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.bookToEdit != null) {
      final b = widget.bookToEdit!;
      _titleCtrl.text = b.title;
      _authorCtrl.text = b.author;
      _swapForCtrl.text = b.swapFor;
      _condition = b.condition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Book')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Book Title'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter author' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _swapForCtrl,
                  decoration: const InputDecoration(labelText: 'Swap For'),
                ),
                const SizedBox(height: 12),
                Text('Condition', style: Theme.of(context).textTheme.bodyLarge),
                Wrap(
                  spacing: 8,
                  children: BookCondition.values.map((c) {
                    return ChoiceChip(
                      label: Text(c.label),
                      selected: _condition == c,
                      onSelected: (_) => setState(() => _condition = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _imageBytes != null
                    ? Image.memory(_imageBytes!, height: 180, fit: BoxFit.cover)
                    : (_imageFile != null
                          ? FutureBuilder<Uint8List>(
                              future: _imageFile!.readAsBytes(),
                              builder: (context, snap) {
                                if (snap.hasData) {
                                  return Image.memory(
                                    snap.data!,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const SizedBox(
                                  height: 180,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            )
                          : ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo),
                              label: const Text('Pick cover image'),
                            )),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePost,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
