import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(child: Text('Please sign in to use chats')),
      );
    }

    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: firestore.getUserChats(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final participants = List<String>.from(
                data['participants'] ?? [],
              );
              final peerId = participants.firstWhere(
                (p) => p != user.uid,
                orElse: () => user.uid,
              );
              final lastMessage = data['lastMessage'] as String? ?? '';
              final updatedAt = data['updatedAt'] as Timestamp?;

              return ListTile(
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: FutureBuilder(
                  future: FirestoreService().getUserDoc(peerId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Text(peerId == user.uid ? 'You' : peerId);
                    }
                    if (snap.hasData) {
                      final data =
                          (snap.data as DocumentSnapshot).data()
                              as Map<String, dynamic>? ??
                          {};
                      final name = data['displayName'] as String? ?? peerId;
                      return Text(name);
                    }
                    return Text(peerId == user.uid ? 'You' : peerId);
                  },
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: updatedAt != null
                    ? Text(
                        updatedAt.toDate().toLocal().toString().split(' ')[0],
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                onTap: () async {
                  final chatId = FirestoreService().chatIdFor(user.uid, peerId);
                  // Capture navigator to avoid using context after await
                  final navigator = Navigator.of(context);
                  await FirestoreService().ensureChatExists(chatId, [
                    user.uid,
                    peerId,
                  ]);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ConversationScreen(chatId: chatId, peerId: peerId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
