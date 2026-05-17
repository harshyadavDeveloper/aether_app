import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../services/chat_service.dart';
import '../services/countdown_service.dart';
import '../services/raid_service.dart';

MultiProvider buildProviders({required Widget child}) {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  return MultiProvider(
    providers: <SingleChildWidget>[
      ChangeNotifierProvider<CountdownService>(
        create: (_) => CountdownService(
          bossSpawnTime: DateTime.now().add(const Duration(minutes: 30)),
        ),
      ),
      Provider<RaidService>(create: (_) => RaidService(firestore: firestore)),
      Provider<ChatService>(create: (_) => ChatService(firestore: firestore)),
    ],
    child: child,
  );
}
