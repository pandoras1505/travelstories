/// A queued write not yet confirmed by Firestore — see [SyncEngine].
///
/// [type] names the mutation (e.g. `'createTravelBook'`) and picks which
/// registered applier replays it; [payload] carries whatever that applier
/// needs, JSON-encoded in storage since SQLite has no native map type.
class PendingMutation {
  const PendingMutation({
    required this.id,
    required this.type,
    required this.payload,
  });

  final int id;
  final String type;
  final Map<String, dynamic> payload;
}
