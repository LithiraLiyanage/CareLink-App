import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../elder/models/check_in.dart';
import '../services/family_check_in_service.dart';
import '../services/family_link_service.dart';
import '../widgets/family_more_menu.dart';

/// Missed check-ins of the older adult the family caregiver is linked to,
/// live from Firestore.
class MissedSessionNotificationScreen extends StatefulWidget {
  const MissedSessionNotificationScreen({super.key});

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _coral = Color(0xFFFF5369);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _line = Color(0xFFD1EBE7);
  static const _secondary = Color(0xFF708486);
  static const _orange = Color(0xFFF59E0B);
  static const _lightWarning = Color(0xFFFFF4DF);

  @override
  State<MissedSessionNotificationScreen> createState() =>
      _MissedSessionNotificationScreenState();
}

class _MissedSessionNotificationScreenState
    extends State<MissedSessionNotificationScreen> {
  late final Stream<List<FamilyLinkRequest>> _approvals =
      FamilyLinkService.instance.watchApprovals();

  // Cached per elder so rebuilds don't resubscribe.
  String? _elderId;
  Stream<List<CheckIn>>? _missed;

  Stream<List<CheckIn>> _missedFor(String elderId) {
    if (_elderId != elderId || _missed == null) {
      _elderId = elderId;
      _missed = FamilyCheckInService.instance.watchMissed(elderId);
    }
    return _missed!;
  }

  void _goHome() =>
      Navigator.pushReplacementNamed(context, AppRoutes.familyDashboard);

  Widget _page(Widget child, {int missedCount = 0}) => _PageLayout(
        missedCount: missedCount,
        onHome: _goHome,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MissedSessionNotificationScreen._mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: MissedSessionNotificationScreen._darkTeal,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Back to family dashboard',
          onPressed: _goHome,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded,
                  color: MissedSessionNotificationScreen._darkTeal, size: 20),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<FamilyLinkRequest>>(
        stream: _approvals,
        builder: (context, approvalSnapshot) {
          if (approvalSnapshot.hasError) {
            debugPrint('Missed check-ins: approvals stream error: '
                '${approvalSnapshot.error}');
            return _page(const _Message(
              'We couldn\'t load your family connection. Please try again.',
            ));
          }
          if (!approvalSnapshot.hasData) return _page(const _Loading());

          final approvals = approvalSnapshot.data!;
          final approval = approvals.isEmpty ? null : approvals.first;
          final elderId = approval?.elderId;
          if (approval == null || elderId == null) {
            return _page(const _Message(
              'Once a family member accepts your request, their missed '
              'check-ins will appear here.',
            ));
          }

          return StreamBuilder<List<CheckIn>>(
            stream: _missedFor(elderId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Missed check-ins stream error: ${snapshot.error}');
                return _page(const _Message(
                  'We couldn\'t load check-ins. Please try again.',
                ));
              }
              if (!snapshot.hasData) return _page(const _Loading());
              final missed = snapshot.data!;
              return _page(
                _MissedList(approval: approval, missed: missed),
                missedCount: missed.length,
              );
            },
          );
        },
      ),
    );
  }
}

/// Background, scrolling content and bottom bar shared by every state.
class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.missedCount,
    required this.onHome,
    required this.child,
  });

  final int missedCount;
  final VoidCallback onHome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              const Positioned(
                top: -48,
                left: -54,
                child: _SoftCircle(size: 172),
              ),
              const Positioned(
                top: 50,
                left: 56,
                child: _SoftCircle(size: 38),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
        _NotificationNavigationBar(missedCount: missedCount, onHome: onHome),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(
            color: MissedSessionNotificationScreen._teal,
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MissedSessionNotificationScreen._secondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
}

class _MissedList extends StatelessWidget {
  const _MissedList({required this.approval, required this.missed});

  final FamilyLinkRequest approval;
  final List<CheckIn> missed;

  @override
  Widget build(BuildContext context) {
    final name = approval.elderName.trim();
    final elderName = name.isEmpty ? 'Your family member' : name;
    final firstName = elderName.split(' ').first;
    final count = missed.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _MissedMark(allClear: count == 0)),
        const SizedBox(height: 10),
        Text(
          count == 0 ? 'No Missed Check-ins' : 'Missed Check-ins',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MissedSessionNotificationScreen._darkTeal,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          count == 0
              ? '$firstName hasn\'t missed any check-ins.'
              : '$firstName missed $count scheduled '
                  'check-in${count == 1 ? '' : 's'}.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MissedSessionNotificationScreen._secondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        for (final checkIn in missed) ...[
          _MissedCheckInCard(
            elderName: elderName,
            relationship: approval.relationship,
            checkIn: checkIn,
          ),
          const SizedBox(height: 10),
        ],
        if (count > 0) const _ExplanationCard(),
      ],
    );
  }
}

class _MissedMark extends StatelessWidget {
  const _MissedMark({required this.allClear});

  final bool allClear;

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: allClear
              ? MissedSessionNotificationScreen._lightTeal
              : MissedSessionNotificationScreen._lightWarning,
          shape: BoxShape.circle,
        ),
        child: Icon(
          allClear
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          color: allClear
              ? MissedSessionNotificationScreen._teal
              : MissedSessionNotificationScreen._orange,
          size: 42,
        ),
      );
}

class _MissedCheckInCard extends StatelessWidget {
  const _MissedCheckInCard({
    required this.elderName,
    required this.relationship,
    required this.checkIn,
  });

  final String elderName;
  final String relationship;
  final CheckIn checkIn;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.day} ${_months[date.month - 1]} ${date.year}, '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final companion = checkIn.companionName.trim();
    final details = [
      '${checkIn.durationMinutes} min ${checkIn.mode}',
      if (companion.isNotEmpty) 'with $companion',
    ].join(' · ');
    final relation = relationship.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: MissedSessionNotificationScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A073F42),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: MissedSessionNotificationScreen._lightTeal,
            child: Icon(Icons.person_rounded,
                size: 28, color: MissedSessionNotificationScreen._teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  elderName,
                  style: const TextStyle(
                    color: MissedSessionNotificationScreen._darkTeal,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (relation.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    'You are their $relation',
                    style: const TextStyle(
                      color: MissedSessionNotificationScreen._secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  _formatDateTime(checkIn.scheduledAt),
                  style: const TextStyle(
                    color: MissedSessionNotificationScreen._darkTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(
                    color: Color(0xFF9AABAC),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: MissedSessionNotificationScreen._lightWarning,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Missed',
              style: TextStyle(
                color: MissedSessionNotificationScreen._orange,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F6F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MissedSessionNotificationScreen._line),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                color: MissedSessionNotificationScreen._teal, size: 21),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Missed sessions are reviewed according to the CareLink '
                'safety process.',
                style: TextStyle(
                  color: MissedSessionNotificationScreen._secondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _NotificationNavigationBar extends StatelessWidget {
  const _NotificationNavigationBar({
    required this.missedCount,
    required this.onHome,
  });

  final int missedCount;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          height: 66,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: MissedSessionNotificationScreen._line),
            ),
          ),
          child: Row(
            children: [
              _NavigationItem(
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: onHome,
              ),
              _NavigationItem(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                selected: true,
                badgeCount: missedCount,
              ),
              _NavigationItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                onTap: () => showFamilyMoreMenu(context),
              ),
            ],
          ),
        ),
      );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.badgeCount = 0,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? MissedSessionNotificationScreen._teal
        : const Color(0xFF708486);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 25,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, size: 22, color: color),
                    if (badgeCount > 0)
                      Positioned(
                        right: -7,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: MissedSessionNotificationScreen._coral,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F6F1),
          shape: BoxShape.circle,
        ),
      );
}
