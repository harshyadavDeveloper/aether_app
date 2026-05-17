import 'package:cloud_firestore/cloud_firestore.dart';

// @AETHER: Chat is scoped to a fixed-size window of 50 messages using
// .limitToLast(50). This means 10,000 concurrent users each trigger
// reads only on new documents, not the full collection history.
class ChatService {
  ChatService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  static const String _collection = 'chat_messages';
  static const int _messageLimit = 50;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages() {
    // @AETHER: orderBy + limitToLast ensures Firestore only sends the
    // latest 50 docs. Each new message triggers exactly 1 document read
    // per connected client — not a full collection scan.
    return _firestore
        .collection(_collection)
        .orderBy('timestamp')
        .limitToLast(_messageLimit)
        .snapshots();
  }

  Future<void> sendMessage({
    required String userId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return;
    }

    await _firestore.collection(_collection).add(<String, Object>{
      'userId': userId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
