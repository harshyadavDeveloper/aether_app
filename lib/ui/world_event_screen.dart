import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/countdown_service.dart';
import '../services/raid_service.dart';

class WorldEventScreen extends StatefulWidget {
  const WorldEventScreen({super.key});

  @override
  State<WorldEventScreen> createState() => _WorldEventScreenState();
}

class _WorldEventScreenState extends State<WorldEventScreen> {
  final TextEditingController _chatController = TextEditingController();
  // Simulated user id — in production this comes from FirebaseAuth
  static const String _userId = 'player_001';
  bool _isJoining = false;
  bool _hasJoined = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _onJoinRaid(RaidService raidService) async {
    if (_isJoining || _hasJoined) return;
    setState(() => _isJoining = true);

    final bool success = await raidService.joinRaid(userId: _userId);

    if (!mounted) return;
    setState(() {
      _isJoining = false;
      _hasJoined = success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '⚔️ You joined the raid!' : '❌ Raid is full.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _onSendMessage(ChatService chatService) async {
    final String text = _chatController.text;
    _chatController.clear();
    await chatService.sendMessage(userId: _userId, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final RaidService raidService = context.read<RaidService>();
    final ChatService chatService = context.read<ChatService>();
    final CountdownService countdown = context.watch<CountdownService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text(
          '⚡ Project Aether — World Event',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // --- Global Pulse: Countdown ---
            RepaintBoundary(
              child: _CountdownCard(formattedTime: countdown.formattedTime),
            ),
            const SizedBox(height: 16),

            // --- Geo-Raid: Join Button ---
            RepaintBoundary(
              child: _RaidCard(
                raidService: raidService,
                isJoining: _isJoining,
                hasJoined: _hasJoined,
                onJoin: () => _onJoinRaid(raidService),
              ),
            ),
            const SizedBox(height: 16),

            // --- Engagement Chat ---
            Expanded(
              child: RepaintBoundary(
                child: _ChatBox(
                  chatService: chatService,
                  controller: _chatController,
                  onSend: () => _onSendMessage(chatService),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------- Sub-widgets (each in its own RepaintBoundary) ---------------

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.formattedTime});
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            '🐉 WORLD BOSS SPAWNS IN',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RaidCard extends StatelessWidget {
  const _RaidCard({
    required this.raidService,
    required this.isJoining,
    required this.hasJoined,
    required this.onJoin,
  });

  final RaidService raidService;
  final bool isJoining;
  final bool hasJoined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: raidService.watchRaid(),
      builder:
          (
            BuildContext ctx,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snap,
          ) {
            final int filled =
                (snap.data?.data()?['slots_filled'] as int?) ?? 0;
            final int max = (snap.data?.data()?['max_slots'] as int?) ?? 15;
            final bool isFull = filled >= max;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: <Widget>[
                  const Text(
                    '⚔️ GEO-RAID: DRAGON\'S LAIR',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$filled / $max slots filled',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isFull || hasJoined || isJoining)
                          ? null
                          : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        disabledBackgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isJoining
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              hasJoined
                                  ? '✅ Joined'
                                  : isFull
                                  ? 'Raid Full'
                                  : 'Join Raid',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}

class _ChatBox extends StatelessWidget {
  const _ChatBox({
    required this.chatService,
    required this.controller,
    required this.onSend,
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
