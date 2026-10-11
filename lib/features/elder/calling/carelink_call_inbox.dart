import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_elder_service.dart';
import 'carelink_live_call_screen.dart';

/// Watches incoming WebRTC invitations while either role's home is mounted.
/// Do not instantiate in the app's unauthenticated onboarding screens.
class CareLinkCallInbox {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _showing = false;
  bool _disposed = false;
  final Set<String> _dismissed = <String>{};

  void start(BuildContext context) {
    // Deliberately start asynchronously so no Firebase App is required when
    // a home-screen widget is merely constructed in a pure widget test.
    Future<void>(() async {
      if (_disposed || !context.mounted) return;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || uid.isEmpty) return;
        _subscription = FirebaseFirestore.instance
            .collection('carelink_live_calls')
            .where('calleeId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
              if (_disposed || !context.mounted || _showing) return;
              for (final doc in snapshot.docs) {
                final createdAt = doc.data()['createdAt'];
                final fresh = createdAt is Timestamp &&
                    DateTime.now().difference(createdAt.toDate()).inMinutes < 2;
                if (fresh && doc.data()['status'] == 'ringing' &&
                    !_dismissed.contains(doc.id)) {
                  unawaited(_showInvite(context, doc));
                  break;
                }
              }
            }, onError: (Object error) {
              debugPrint('CareLink incoming call listener failed: $error');
            });
      } catch (error) {
        debugPrint('CareLink inbox could not start: $error');
      }
    });
  }

  Future<void> _showInvite(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> invitation,
  ) async {
    if (_showing || _disposed || !context.mounted) return;
    _showing = true;
    _dismissed.add(invitation.id);
    try {
      final call = invitation.data();
      final mode = call['mode'] as String? ?? 'Video';
      final answer = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('Incoming ${mode.toLowerCase()} call'),
          content: const Text('Your connected CareLink partner is calling. Answer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Answer'),
            ),
          ],
        ),
      );
      if (_disposed || !context.mounted) return;
      if (answer != true) {
        try {
          await invitation.reference.update({
            'status': 'ended',
            'endedBy': FirebaseAuth.instance.currentUser?.uid,
            'endedAt': FieldValue.serverTimestamp(),
          });
        } catch (error) {
          debugPrint('CareLink call decline failed: $error');
        }
        return;
      }
      // Verify this invitation is still ringing before opening the camera.
      final fresh = await invitation.reference.get();
      if (fresh.data()?['status'] != 'ringing') return;
      final service = FirebaseElderService.instance;
      final flow = await service.getCurrentFlowContext();
      if (flow.connectionId != call['connectionId'] ||
          flow.elderId != call['elderId'] ||
          flow.companionId != call['companionId']) {
        throw StateError('The caller is not your current active connection.');
      }
      final checkIn = await service.getCheckInById(call['checkInId'] as String);
      if (checkIn == null) throw StateError('This check-in no longer exists.');
      if (!context.mounted) return;
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CareLinkLiveCallScreen(
            checkIn: checkIn,
            flow: flow,
            mode: mode,
            incomingRoomId: invitation.id,
          ),
        ),
      );
    } catch (error) {
      debugPrint('CareLink incoming call error: $error');
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not answer CareLink call: $error')),
        );
      }
    } finally {
      _showing = false;
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
  }
}
