import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ChatBox extends StatelessWidget {
  const ChatBox({
    required this.chatService,
    required this.controller,
    required this.onSend,
    super.key,
  });

  final ChatService chatService;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              '💬 ENGAGEMENT CHAT',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
          // @AETHER: Chat list is fixed height via parent SizedBox.
          // ListView inside a constrained parent never overflows.
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatService.watchMessages(),
              builder:
                  (
                    BuildContext ctx,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,
                  ) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                    docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Say something!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: docs.length,
                      itemBuilder: (BuildContext ctx, int i) {
                        final Map<String, dynamic> msg = docs[i].data();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${msg['userId']}: ${msg['text']}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
