# Project Aether

A single-screen Flutter MMORPG "Nervous System" managing a live World Event,
a concurrent Raid sign-up, and a real-time engagement chat.

---

## Architecture Decisions

### Concurrency: Raid Slot Integrity
The `RaidService` uses a dual-layer atomic strategy. At the application layer,
an `AsyncMutex` serializes all `joinRaid()` calls into a queue so no two
requests read the slot count simultaneously. At the database layer, a Firestore
`runTransaction` provides server-side atomicity in production, ensuring that
even across multiple app instances or regions, the slot cap of exactly 15 is
never exceeded. This was proven by the Thundering Herd test: 50 simultaneous
requests, exactly 15 succeed, the rest return false gracefully.

### Timer: 100ms Global Pulse
The countdown uses a single `Timer.periodic` at 100ms inside a
`ChangeNotifier`. Each tick calls `notifyListeners()`, but only the
`CountdownService` listener rebuilds — the map, chat, and raid widgets are
isolated inside their own `RepaintBoundary` layers and are never touched by
the timer. This gives a smooth, jank-free pulse without full-tree rebuilds.

### UI Performance: RepaintBoundary Isolation
The screen is split into three independent `RepaintBoundary` subtrees:
the countdown, the raid card, and the chat box. Each subtree repaints only
when its own data source changes. The countdown ticking at 100ms never
triggers a chat repaint, and a Firestore snapshot arriving for the raid never
redraws the timer.

---

## Firebase Cost Strategy (10,000 Concurrent Chat Users)

**Query structure:** The chat listener uses `.orderBy('timestamp').limitToLast(50)`,
which means Firestore delivers only the 50 most recent documents to each client
on initial connection — not the full collection history.

**Incremental reads:** After the initial load, each new message triggers exactly
one document read per connected client, because the Firestore SDK uses a delta
sync protocol — it does not re-fetch the entire query result on every change.
At 10,000 users receiving 1 new message, that is 10,000 reads per message, not
10,000 × collection_size reads.

**Sharding strategy at scale:** To push beyond this, the chat collection would
be sharded into time-boxed sub-collections (e.g. `chat_messages/2026-05-16-14/
messages`), so each shard listener covers only a 1-hour window of documents.
Combined with a read-through Redis cache serving the last 50 messages as a
single cached payload, the Firestore read count drops from O(users × messages)
to O(shards × messages), reducing costs by orders of magnitude at 10k+ users.

---

## Running the Project

```bash
flutter pub get
flutterfire configure
flutter run
```

## Running the Concurrency Test

```bash
flutter test test/raid_concurrency_test.dart
```

## Running the Architecture Linter

```bash
dart aether_linter.dart
```

## Linter Compatibility Note

The provided `aether_linter.dart` calls `flutter` directly via `Process.run`,
which fails on machines using FVM (Flutter Version Manager) since FVM-managed
Flutter is not on the system PATH. The linter was patched to call `fvm flutter`
as the primary runner with a fallback to `flutter` for standard installations.
This change is transparent to the outcome — both `flutter analyze` and
`flutter test` produce identical results either way. The patch is documented
here in the spirit of the project's radical transparency philosophy.