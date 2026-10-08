import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../elder/models/check_in.dart';
import '../../elder/widgets/elder_assets.dart';
import '../../elder/widgets/elder_ui.dart';
import '../services/family_check_in_service.dart';
import '../services/family_link_service.dart';

/// Family caregiver dashboard shown after a connection is approved.
class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  static const _ink = Color(0xFF00776F);
  static const _titleInk = Color(0xFF073F42);
  static const _muted = Color(0xFF708486);
  static const _mint = Color(0xFFF5FBF9);
  static const _line = Color(0xFFD1EBE7);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  static const _titleInk = FamilyDashboardScreen._titleInk;
  static const _muted = FamilyDashboardScreen._muted;
  static const _mint = FamilyDashboardScreen._mint;

  late final Future<String?> _caregiverName = _loadCaregiverName();
  late final Stream<List<FamilyLinkRequest>> _approvals =
      FamilyLinkService.instance.watchApprovals();

  Future<String?> _loadCaregiverName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final fullName = (profile.data()?['fullName'] as String?)?.trim();
    if (fullName == null || fullName.isEmpty) return user.displayName;
    return fullName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF073F42),
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Open approved connection',
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.familyApproved),
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
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
            padding: EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: Color(0xFF073F42), size: 19),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -68,
            right: -64,
            child: _SoftCircle(size: 176),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 13, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<String?>(
                        future: _caregiverName,
                        builder: (context, snapshot) {
                          final name = snapshot.data?.trim() ?? '';
                          final firstName =
                              name.isEmpty ? '' : name.split(' ').first;
                          return Text(
                            firstName.isEmpty
                                ? 'Hello 👋'
                                : 'Hello, $firstName 👋',
                            style: const TextStyle(
                              color: _titleInk,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Here's an overview of your family member.",
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<FamilyLinkRequest>>(
                        stream: _approvals,
                        builder: (context, snapshot) {
                          final approvals = snapshot.data;
                          final approval = approvals == null || approvals.isEmpty
                              ? null
                              : approvals.first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MemberCard(
                                approval: approval,
                                loading: !snapshot.hasData && !snapshot.hasError,
                              ),
                              const SizedBox(height: 12),
                              _CheckInRow(elderName: approval?.elderName),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const _FamilyStatusCard(),
                      const SizedBox(height: 12),
                      const _ConsentCard(),
                      const SizedBox(height: 18),
                      const Text(
                        'Recent Updates',
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _UpdatesCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _DashboardNavigationBar(),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.approval, this.loading = false});

  final FamilyLinkRequest? approval;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final elderName = approval?.elderName.trim() ?? '';
    final relationship = approval?.relationship.trim() ?? '';
    final String nameText;
    final String relationshipText;
    if (loading) {
      nameText = 'Loading...';
      relationshipText = '';
    } else if (approval == null) {
      nameText = 'No family member linked';
      relationshipText = 'Send a link request to connect';
    } else {
      nameText = elderName.isEmpty ? 'Older adult' : elderName;
      relationshipText =
          relationship.isEmpty ? 'Family member' : 'You are their $relationship';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          if (approval != null && !loading)
            const ElderAvatar(
              asset: ElderAssets.kamalaAvatar,
              size: 54,
              border: false,
            )
          else
            const CircleAvatar(
              radius: 27,
              backgroundColor: Color(0xFFE7F6F1),
              child: Icon(Icons.person_rounded,
                  size: 31, color: FamilyDashboardScreen._ink),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameText,
                  style: const TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(relationshipText,
                    style: const TextStyle(
                        color: FamilyDashboardScreen._muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: FamilyDashboardScreen._lightSuccess,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: FamilyDashboardScreen._success),
                SizedBox(width: 5),
                Text(
                  'Connected',
                  style: TextStyle(
                    color: FamilyDashboardScreen._success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's and the next check-in for the linked elder, live from Firestore.
class _CheckInRow extends StatefulWidget {
  const _CheckInRow({required this.elderName});

  final String? elderName;

  @override
  State<_CheckInRow> createState() => _CheckInRowState();
}

class _CheckInRowState extends State<_CheckInRow> {
  Stream<FamilyCheckInSummary>? _summary;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(_CheckInRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elderName != widget.elderName) _subscribe();
  }

  void _subscribe() {
    final name = widget.elderName?.trim() ?? '';
    _summary = name.isEmpty
        ? null
        : FamilyCheckInService.instance.watchSummary(name);
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null) {
      return _buildRow(today: null, next: null, message: 'Not linked yet');
    }
    return StreamBuilder<FamilyCheckInSummary>(
      stream: _summary,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildRow(today: null, next: null, message: 'Unavailable');
        }
        if (!snapshot.hasData) {
          return _buildRow(today: null, next: null, message: 'Loading...');
        }
        return _buildRow(today: snapshot.data!.today, next: snapshot.data!.next);
      },
    );
  }

  Widget _buildRow({
    required CheckIn? today,
    required CheckIn? next,
    String? message,
  }) {
    final todayStatus = message ?? _todayStatus(today);
    final todayDone = today?.status == CheckInStatus.completed;
    final todayMissed = today?.status == CheckInStatus.missed;
    final todayColor = todayDone
        ? FamilyDashboardScreen._success
        : todayMissed
            ? const Color(0xFFC62828)
            : FamilyDashboardScreen._titleInk;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CheckInCard(
            title: "Today's Check-in",
            status: todayStatus,
            time: message != null
                ? ''
                : today == null
                    ? 'Nothing scheduled'
                    : _formatTime(today.scheduledAt),
            icon: todayDone ? Icons.check_rounded : Icons.today_rounded,
            iconColor: todayDone
                ? FamilyDashboardScreen._success
                : FamilyDashboardScreen._ink,
            statusColor: todayColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CheckInCard(
            title: 'Next Check-in',
            status: message ?? (next == null ? 'None yet' : _dayLabel(next.scheduledAt)),
            time: message != null
                ? ''
                : next == null
                    ? 'Nothing scheduled'
                    : _formatTime(next.scheduledAt),
            icon: Icons.calendar_month_rounded,
            iconColor: FamilyDashboardScreen._ink,
            statusColor: FamilyDashboardScreen._titleInk,
          ),
        ),
      ],
    );
  }

  static String _todayStatus(CheckIn? checkIn) {
    switch (checkIn?.status) {
      case null:
        return 'None today';
      case CheckInStatus.completed:
        return 'Completed';
      case CheckInStatus.inProgress:
        return 'In progress';
      case CheckInStatus.missed:
        return 'Missed';
      case CheckInStatus.cancelled:
        return 'Cancelled';
      case CheckInStatus.scheduled:
      case CheckInStatus.ready:
        return 'Upcoming';
    }
  }

  static String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.title,
    required this.status,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.statusColor,
  });

  final String title;
  final String status;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon == Icons.check_rounded)
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                )
              else
                Icon(icon, size: 23, color: iconColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(time,
              style: const TextStyle(
                  color: FamilyDashboardScreen._muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FamilyStatusCard extends StatelessWidget {
  const _FamilyStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF2E8D3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.bar_chart_rounded,
              color: FamilyDashboardScreen._ink, size: 23),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Status',
                  style: TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'All scheduled check-ins are on track.',
                  style: TextStyle(
                    color: FamilyDashboardScreen._muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: FamilyDashboardScreen._ink, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consent',
                  style: TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Information sharing',
                  style: TextStyle(
                      color: FamilyDashboardScreen._muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FamilyDashboardScreen._lightSuccess,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Enabled',
                    style: TextStyle(
                      color: FamilyDashboardScreen._success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View Details',
                style: TextStyle(
                  color: FamilyDashboardScreen._ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: FamilyDashboardScreen._ink, size: 19),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdatesCard extends StatelessWidget {
  const _UpdatesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _UpdateRow(
            icon: Icons.check_rounded,
            iconColor: FamilyDashboardScreen._success,
            title: 'Check-in completed',
            time: 'Today, 9:15 AM',
          ),
          Divider(height: 1, thickness: 1, color: Color(0xFFE7F6F1)),
          _UpdateRow(
            icon: Icons.calendar_month_rounded,
            iconColor: FamilyDashboardScreen._ink,
            title: 'Next check-in scheduled',
            time: 'Tomorrow, 10:00 AM',
          ),
        ],
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51,
      child: Row(
        children: [
          if (icon == Icons.check_rounded)
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
              child: Icon(icon, size: 14, color: Colors.white),
            )
          else
            Icon(icon, size: 21, color: iconColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FamilyDashboardScreen._titleInk,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              color: FamilyDashboardScreen._muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardNavigationBar extends StatelessWidget {
  const _DashboardNavigationBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: FamilyDashboardScreen._line)),
        ),
        child: Row(
          children: [
            const _NavigationItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
            ),
            _NavigationItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.missedSession),
            ),
            const _NavigationItem(
              icon: Icons.shield_outlined,
              label: 'Consent',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FamilyDashboardScreen._ink : const Color(0xFF708486);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
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

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: FamilyDashboardScreen._line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A073F42),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    );

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
