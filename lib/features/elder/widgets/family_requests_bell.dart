import 'package:flutter/material.dart';

import '../../family_safety/services/family_link_service.dart';
import 'elder_colors.dart';

/// Header bell that shows a badge with the number of pending family link
/// requests and opens them in a bottom sheet.
class FamilyRequestsBell extends StatefulWidget {
  const FamilyRequestsBell({super.key});

  @override
  State<FamilyRequestsBell> createState() => _FamilyRequestsBellState();
}

class _FamilyRequestsBellState extends State<FamilyRequestsBell> {
  late final Stream<List<FamilyLinkRequest>> _requests =
      FamilyLinkService.instance.watchPendingRequests().asBroadcastStream();

  List<FamilyLinkRequest> _latest = const [];

  void _openRequests() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _FamilyRequestsSheet(
        requests: _requests,
        initial: _latest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyLinkRequest>>(
      stream: _requests,
      builder: (context, snapshot) {
        _latest = snapshot.data ?? const [];
        final count = _latest.length;

        return Semantics(
          button: true,
          label: count == 0
              ? 'Notifications'
              : 'Notifications, $count family request${count == 1 ? '' : 's'}',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _openRequests,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ElderColors.coral,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: ElderColors.darkTeal,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FamilyRequestsSheet extends StatelessWidget {
  const _FamilyRequestsSheet({required this.requests, required this.initial});

  final Stream<List<FamilyLinkRequest>> requests;
  final List<FamilyLinkRequest> initial;

  Future<void> _respond(
    BuildContext context,
    FamilyLinkRequest request, {
    required bool accept,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FamilyLinkService.instance.respond(request.id, accept: accept);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'You are now linked with ${request.requesterName}.'
                : 'Request from ${request.requesterName} declined.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Only the older adult can respond to this request.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: StreamBuilder<List<FamilyLinkRequest>>(
          stream: requests,
          initialData: initial,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <FamilyLinkRequest>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Family requests',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'No new requests right now.',
                      style: TextStyle(
                        color: ElderColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  for (final request in items)
                    _RequestCard(
                      request: request,
                      onDecline: () =>
                          _respond(context, request, accept: false),
                      onAccept: () => _respond(context, request, accept: true),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onDecline,
    required this.onAccept,
  });

  final FamilyLinkRequest request;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: ElderColors.darkTeal,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${request.requesterName} '
                  '(your ${request.relationship.toLowerCase()}) '
                  'wants to link with you.',
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ElderColors.textDark,
                    side: const BorderSide(color: ElderColors.border),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: ElderColors.darkTeal,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
