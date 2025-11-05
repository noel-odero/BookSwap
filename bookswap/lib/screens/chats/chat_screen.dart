import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        leading: Navigator.canPop(context) ? const BackButton() : null,
      ),
      body: const Center(child: Text('Chat screen - Coming soon!')),
    );
  }
}
