import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/raid_service.dart';

class RaidCard extends StatelessWidget {
  const RaidCard({
    required this.raidService,
    required this.isJoining,
    required this.hasJoined,
    required this.onJoin,
    super.key,
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                    "⚔️ GEO-RAID: DRAGON'S LAIR",
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
