import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTION TRACKING SERVICE (Phase 3 Step 7 — "Summit A" data layer)
//
// Accumulates a per-user, per-tag interest weight (views/likes/saves on tags
// like "Kedi", "Acil", "Golden") into `users/{uid}.interestScores` —
// see [UserModel.interestScores]. This is the raw signal Summit A's future
// recommendation algorithm will read to rank [AlgorithmicFeedScreen].
//
// STRICT SCOPE (per spec): this step only establishes the data model and
// this service. Nothing calls [logInteraction] yet — no `onTap` handlers
// were added to any card, and no fake/mock interaction data was generated.
// Wiring real UI call sites is a future step.
//
// Singleton, plain-Dart service — mirrors [NotificationService]'s pattern
// (private constructor + static `.instance`, no Provider/BuildContext
// dependency), since this is infrastructure, not view state.
// ─────────────────────────────────────────────────────────────────────────────

class InteractionTrackingService {
  InteractionTrackingService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final InteractionTrackingService instance =
      InteractionTrackingService._();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Adds [weight] to the current user's interest score for [tag].
  ///
  /// Uses [FieldValue.increment] inside a merge write rather than a
  /// read-then-write: Firestore resolves the increment against whatever
  /// value currently sits at `interestScores.$tag` (or `0` if the tag or
  /// even the whole document doesn't exist yet), so "add the weight if the
  /// tag exists, otherwise create it" happens atomically server-side with a
  /// single request — no local read, no race condition between two
  /// concurrent interactions on the same tag.
  ///
  /// Best-effort telemetry: silently no-ops when signed out or [tag] is
  /// blank, and swallows Firestore failures (logged in debug only) rather
  /// than surfacing an error, since a failed interaction log must never
  /// interrupt the user's actual action (viewing/liking/saving something).
  Future<void> logInteraction(String tag, double weight) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).set(
        {
          'interestScores': {
            trimmedTag: FieldValue.increment(weight),
          },
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      debugPrint('[InteractionTrackingService] logInteraction("$trimmedTag") '
          'failed: ${e.message}');
    }
  }
}
