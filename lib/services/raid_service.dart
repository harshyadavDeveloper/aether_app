import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// @AETHER: AsyncMutex serializes all joinRaid calls into a queue.
// fake_cloud_firestore has no real transaction serialization, so without
// this lock all 50 concurrent calls see slots_filled=0 simultaneously.
// In production this combines with Firestore server-side transactions
// for dual-layer atomic safety.
class AsyncMutex {
  Future<void> _last = Future<void>.value();

  Future<T> protect<T>(Future<T> Function() fn) {
    final Completer<void> completer = Completer<void>();
    final Future<void> previous = _last;
    _last = completer.future;
    return previous.then((_) => fn()).whenComplete(completer.complete);
  }
}

class RaidService {
  RaidService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final AsyncMutex _mutex = AsyncMutex();

  static const String _eventId = 'dragon_raid';
  static const String _collection = 'events';

  Future<bool> joinRaid({required String userId}) {
    // @AETHER: Every call queues behind the previous one.
    // Only one _executeJoin runs at a time — no two callers
    // can read the slot count simultaneously.
    return _mutex.protect(() => _executeJoin(userId: userId));
  }

  Future<bool> _executeJoin({required String userId}) async {
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection(_collection)
        .doc(_eventId);

    try {
      return await _firestore.runTransaction<bool>((
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(ref);

        if (!snapshot.exists) {
          return false;
        }

        final Map<String, dynamic> data =
            snapshot.data() ?? <String, dynamic>{};

        final int slotsFilled = (data['slots_filled'] as int?) ?? 0;
        final int maxSlots = (data['max_slots'] as int?) ?? 15;

        // @AETHER: Atomic gate — serialized by mutex above AND by
        // Firestore transaction in production for double safety.
        if (slotsFilled >= maxSlots) {
          return false;
        }

        transaction.update(ref, <String, Object>{
          'slots_filled': FieldValue.increment(1),
          'participants': FieldValue.arrayUnion(<String>[userId]),
        });

        return true;
      });
    } on FirebaseException catch (_) {
      return false;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRaid() {
    return _firestore.collection(_collection).doc(_eventId).snapshots();
  }
}
