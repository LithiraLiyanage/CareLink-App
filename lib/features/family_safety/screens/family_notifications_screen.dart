import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../services/family_link_service.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${date.day} ${_months[date.month - 1]} ${date.year}, '
      '$hour:$minute $period';
}

/// Lists the family member's link requests that older adults have accepted.
class FamilyNotificationsScreen extends StatefulWidget {
  const FamilyNotificationsScreen({super.key});

  static const _ink = Color(0xFF00695C);
  static const _titleInk = Color(0xFF004D40);
  static const _muted = Color(0xFF55706E);
  static const _mint = Color(0xFFF2F9F7);
  static const _line = Color(0xFFD5E5E2);
  static const _coral = Color(0xFFF26F6A);
  static const _unreadFill = Color(0xFFE6F4F1);

  @override
  State<FamilyNotificationsScreen> createState() =>
      _FamilyNotificationsScreenState();
}

class _FamilyNotificationsScreenState extends State<FamilyNotificationsScreen> {
  static const _ink = FamilyNotificationsScreen._ink;
  static const _muted = FamilyNotificationsScreen._muted;
  static const _mint = FamilyNotificationsScreen._mint;
  static const _coral = FamilyNotificationsScreen._coral;

  late final Stream<List<FamilyLinkRequest>> _approvals =
      FamilyLinkService.instance.watchApprovals();

  void _view(FamilyLinkRequest request) {
    if (!request.seenByRequester) {
      // Clear the unread state in the background; navigation shouldn't
      // wait on it.
      FamilyLinkService.instance
          .markApprovalSeen(request.id)
          .catchError((_) {});
    }
    // The approved screen's back arrow replaces itself with this screen.
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.familyApproved,
      arguments: request.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 23),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: StreamBuilder<List<FamilyLinkRequest>>(
              stream: _approvals,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(22),
                    child: Text(
                      'Could not load notifications: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _coral),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _ink),
                  );
                }
                final approvals = snapshot.data!;
                if (approvals.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'No notifications yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: approvals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final request = approvals[index];
                    return _NotificationCard(
                      request: request,
                      onView: () => _view(request),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.request, required this.onView});

  final FamilyLinkRequest request;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final unread = !request.seenByRequester;
    final elderName =
        request.elderName.isEmpty ? 'The older adult' : request.elderName;
    final respondedAt = request.respondedAt?.toLocal() ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread ? FamilyNotificationsScreen._unreadFill : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamilyNotificationsScreen._line),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.verified_user_rounded,
                  color: FamilyNotificationsScreen._ink,
                  size: 22,
                ),
              ),
              if (unread)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: FamilyNotificationsScreen._coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$elderName accepted your link request',
                  style: TextStyle(
                    color: FamilyNotificationsScreen._titleInk,
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(respondedAt),
                  style: const TextStyle(
                    color: FamilyNotificationsScreen._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onView,
            style: FilledButton.styleFrom(
              backgroundColor: FamilyNotificationsScreen._coral,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Text(
              'View',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
