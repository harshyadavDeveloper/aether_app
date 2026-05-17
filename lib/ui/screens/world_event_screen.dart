import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/chat_service.dart';
import '../../services/countdown_service.dart';
import '../../services/raid_service.dart';
import '../widgets/chat_box.dart';
import '../widgets/countdown_card.dart';
import '../widgets/raid_card.dart';

class WorldEventScreen extends StatefulWidget {
  const WorldEventScreen({super.key});

  @override
  State<WorldEventScreen> createState() => _WorldEventScreenState();
}

class _WorldEventScreenState extends State<WorldEventScreen> {
  final TextEditingController _chatController = TextEditingController();
  // @AETHER: userId would come from FirebaseAuth in production.
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
    if (text.trim().isEmpty) return;
    _chatController.clear();
    await chatService.sendMessage(userId: _userId, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final RaidService raidService = context.read<RaidService>();
    final ChatService chatService = context.read<ChatService>();
    final CountdownService countdown = context.watch<CountdownService>();

    return Scaffold(
      // @AETHER: resizeToAvoidBottomInset lets the scaffold shrink
      // when the keyboard appears so SingleChildScrollView can scroll.
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text(
          '⚡ Project Aether — World Event',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // @AETHER: reverse: true keeps the chat input pinned near
          // the keyboard when it appears, matching messaging app UX.
          reverse: false,
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Global Pulse: Countdown ---
              RepaintBoundary(
                child: CountdownCard(formattedTime: countdown.formattedTime),
              ),
              const SizedBox(height: 12),

              // --- Geo-Raid: Join Button ---
              RepaintBoundary(
                child: RaidCard(
                  raidService: raidService,
                  isJoining: _isJoining,
                  hasJoined: _hasJoined,
                  onJoin: () => _onJoinRaid(raidService),
                ),
              ),
              const SizedBox(height: 12),

              // --- Engagement Chat ---
              RepaintBoundary(
                child: SizedBox(
                  // Fixed height so chat has a defined space in the scroll view
                  height: 380,
                  child: ChatBox(
                    chatService: chatService,
                    controller: _chatController,
                    onSend: () => _onSendMessage(chatService),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
