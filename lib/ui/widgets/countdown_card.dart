import 'package:flutter/material.dart';

class CountdownCard extends StatelessWidget {
  const CountdownCard({required this.formattedTime, super.key});
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Remove fixed padding, use smaller value
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)),
      ),
      child: FittedBox(
        // @AETHER: FittedBox scales the timer text to fit whatever
        // vertical space the Flexible parent gives it — never overflows.
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '🐉 WORLD BOSS SPAWNS IN',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }
}
