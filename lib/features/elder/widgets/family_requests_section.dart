import 'dart:async';

import 'package:flutter/material.dart';

import '../../family_safety/services/family_link_service.dart';
import 'elder_colors.dart';

/// Header icon for family link requests. Shows a badge with the number of
/// pending requests and opens them in a bottom sheet when tapped.
class FamilyRequestsButton extends StatefulWidget {
  const FamilyRequestsButton({super.key});

  @override
  State<FamilyRequestsButton> createState() => _FamilyRequestsButtonState();
}

class _FamilyRequestsButtonState extends State<FamilyRequestsButton> {
  // Shared by the icon and the open sheet.
  late final _FamilyRequestsController _controller =
      _FamilyRequestsController()..start();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openRequests() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _FamilyRequestsSheet(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final count = _controller.count;

        return IconButton(
          tooltip: count == 0
              ? 'Family requests'
              : '$count family request${count == 1 ? '' : 's'}',
          onPressed: _openRequests,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: Colors.white,
                size: 26,
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
        );
      },
    );
  }
}

/// Holds the request stream and which responses are in flight.
class _FamilyRequestsController extends ChangeNotifier {
  StreamSubscription<List<FamilyLinkRequest>>? _subscription;

  List<FamilyLinkRequest> requests = const [];
  Object? error;

  /// Result of the last accept/decline, shown inside the sheet. A SnackBar
  /// would appear behind the bottom sheet and go unnoticed.
  String? notice;
  bool noticeIsError = false;

  void showNotice(String message, {required bool isError}) {
    notice = message;
    noticeIsError = isError;
    _notify();
  }

  /// IDs of requests with a response in flight.
  final Set<String> _busy = {};

  bool _disposed = false;

  int get count => requests.length;

  bool isBusy(String id) => _busy.contains(id);

  void start() => subscribe();

  void subscribe() {
    _subscription?.cancel();
    error = null;
    _subscription = FamilyLinkService.instance.watchPendingRequests().listen(
      (requests) {
        this.requests = requests;
        error = null;
        _notify();
      },
      onError: (Object error) {
        debugPrint('Family requests stream failed: $error');
        requests = const [];
        this.error = error;
        _notify();
      },
    );
    _notify();
  }

  /// Responds to [request] unless a response for it is already in flight.
  /// Returns false if it was skipped.
  Future<bool> respond(FamilyLinkRequest request, {required bool accept}) async {
    if (!_busy.add(request.id)) return false;
    notice = null;
    _notify();
    try {
      await FamilyLinkService.instance.respond(request.id, accept: accept);
      return true;
    } finally {
      _busy.remove(request.id);
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}

class _FamilyRequestsSheet extends StatelessWidget {
  const _FamilyRequestsSheet({required this.controller});

  final _FamilyRequestsController controller;

  Future<void> _respond(FamilyLinkRequest request, {required bool accept}) async {
    try {
      final done = await controller.respond(request, accept: accept);
      if (!done) return;
      controller.showNotice(
        accept
            ? 'You are now linked with ${request.requesterName}.'
            : 'Request from ${request.requesterName} declined.',
        isError: false,
      );
    } catch (error) {
      debugPrint('Family request response failed: $error');
      controller.showNotice(
        error is FamilyLinkException
            ? error.message
            : 'Could not respond to this request. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final requests = controller.requests;
              final error = controller.error;
              final notice = controller.notice;

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
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (notice != null)
                          _ResponseNotice(
                            message: notice,
                            isError: controller.noticeIsError,
                          ),
                        if (error != null)
                          _StreamErrorNotice(
                            message: 'Could not load family requests.',
                            onRetry: controller.subscribe,
                          ),
                        if (requests.isEmpty && error == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'No new requests right now.',
                              style: TextStyle(
                                color: ElderColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        for (final request in requests)
                          _FamilyRequestCard(
                            requesterName: request.requesterName,
                            relationship: request.relationship,
                            idNumber: request.idNumber,
                            busy: controller.isBusy(request.id),
                            onDecline: () => _respond(request, accept: false),
                            onAccept: () => _respond(request, accept: true),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResponseNotice extends StatelessWidget {
  const _ResponseNotice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? ElderColors.dangerSoft.withValues(alpha: 0.4)
            : ElderColors.mintSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: ElderColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StreamErrorNotice extends StatelessWidget {
  const _StreamErrorNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: ElderColors.dangerSoft.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ElderColors.textDark,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: ElderColors.darkTeal,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _FamilyRequestCard extends StatelessWidget {
  const _FamilyRequestCard({
    required this.requesterName,
    required this.relationship,
    required this.busy,
    required this.onDecline,
    required this.onAccept,
    this.idNumber,
  });

  final String requesterName;
  final String relationship;

  /// The ID number the family member entered, shown for name-addressed
  /// requests so the older adult can confirm the request is for them.
  final String? idNumber;

  /// True while a response is in flight; disables both buttons.
  final bool busy;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final relationship = this.relationship.trim().toLowerCase();
    final idNumber = this.idNumber?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: ElderColors.darkTeal,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relationship.isEmpty
                          ? '$requesterName wants to link with you.'
                          : '$requesterName (your $relationship) '
                              'wants to link with you.',
                      style: const TextStyle(
                        color: ElderColors.textDark,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (idNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID number entered: $idNumber',
                        style: const TextStyle(
                          color: ElderColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
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
                  onPressed: busy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: ElderColors.darkTeal,
                  ),
                  child: busy
                      ? const _ButtonSpinner(color: Colors.white)
                      : const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
