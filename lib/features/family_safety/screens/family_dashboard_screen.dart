import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../elder/models/check_in.dart';
import '../services/family_check_in_service.dart';
import '../services/family_link_service.dart';
import '../widgets/family_more_menu.dart';

/// True when Firestore refused the read because of security rules.
bool _isPermissionDenied(Object? error) =>
    error is FirebaseException && error.code == 'permission-denied';

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
                          if (snapshot.hasError) {
                            debugPrint(
                              'Family approvals stream error: ${snapshot.error}',
                            );
                          }
                          final approvals = snapshot.data;
                          final approval = approvals == null || approvals.isEmpty
                              ? null
                              : approvals.first;
                          final loading =
                              !snapshot.hasData && !snapshot.hasError;
                          final linkError =
                              snapshot.hasError ? snapshot.error : null;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MemberCard(
                                approval: approval,
                                loading: loading,
                                error: linkError,
                              ),
                              const SizedBox(height: 12),
                              // Also renders the Family Status card, which is
                              // derived from the same check-in summary.
                              _CheckInRow(
                                elderId: approval?.elderId,
                                loading: loading,
                                linkError: linkError,
                              ),
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
                              _UpdatesCard(
                                elderId: approval?.elderId,
                                loading: loading,
                                linkError: linkError,
                              ),
                            ],
                          );
                        },
                      ),
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
  const _MemberCard({
    required this.approval,
    this.loading = false,
    this.error,
  });

  final FamilyLinkRequest? approval;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final elderName = approval?.elderName.trim() ?? '';
    final relationship = approval?.relationship.trim() ?? '';
    final connected = approval != null && !loading && error == null;
    final String nameText;
    final String relationshipText;
    if (loading) {
      nameText = 'Loading...';
      relationshipText = 'Checking your family link';
    } else if (error != null) {
      nameText = 'Family link unavailable';
      relationshipText = _isPermissionDenied(error)
          ? "You don't have permission to view this link"
          : "Couldn't load your family link";
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
          // Link requests carry no photo, so don't show a stock one.
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
          if (!loading) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: connected
                    ? FamilyDashboardScreen._lightSuccess
                    : const Color(0xFFEEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle,
                      size: 7,
                      color: connected
                          ? FamilyDashboardScreen._success
                          : FamilyDashboardScreen._muted),
                  const SizedBox(width: 5),
                  Text(
                    connected
                        ? 'Connected'
                        : error != null
                            ? 'Unavailable'
                            : 'Not linked',
                    style: TextStyle(
                      color: connected
                          ? FamilyDashboardScreen._success
                          : FamilyDashboardScreen._muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Today's and the next check-in for the linked elder, live from Firestore.
class _CheckInRow extends StatefulWidget {
  const _CheckInRow({
    required this.elderId,
    this.loading = false,
    this.linkError,
  });

  /// The linked elder's UID; null until a request is accepted.
  final String? elderId;

  /// The accepted link request is still loading.
  final bool loading;

  /// The accepted link request couldn't be read.
  final Object? linkError;

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
    if (oldWidget.elderId != widget.elderId) _subscribe();
  }

  void _subscribe() {
    final elderId = widget.elderId ?? '';
    _summary = elderId.isEmpty
        ? null
        : FamilyCheckInService.instance.watchSummary(elderId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return _buildRow(
        today: null,
        next: null,
        message: 'Loading...',
        familyStatus: 'Loading check-in status...',
      );
    }
    if (widget.linkError != null) {
      return _buildRow(
        today: null,
        next: null,
        message: 'Unavailable',
        detail: 'Family link not loaded',
        familyStatus: "Check-in status can't be shown until your family "
            'link loads.',
      );
    }
    if (_summary == null) {
      return _buildRow(
        today: null,
        next: null,
        message: 'Not linked yet',
        familyStatus: 'Link a family member to see their check-in status.',
      );
    }
    return StreamBuilder<FamilyCheckInSummary>(
      stream: _summary,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Family check-in stream error: ${snapshot.error}',
          );
          final denied = _isPermissionDenied(snapshot.error);
          return _buildRow(
            today: null,
            next: null,
            message: 'Unavailable',
            detail: denied ? 'No access to check-ins' : "Couldn't load",
            familyStatus: denied
                ? "Your account doesn't have permission to view this "
                    "family member's check-ins yet."
                : "Check-ins couldn't be loaded right now.",
          );
        }
        if (!snapshot.hasData) {
          return _buildRow(
            today: null,
            next: null,
            message: 'Loading...',
            familyStatus: 'Loading check-in status...',
          );
        }
        final today = snapshot.data!.today;
        final next = snapshot.data!.next;
        return _buildRow(
          today: today,
          next: next,
          familyStatus: _familyStatus(today, next),
        );
      },
    );
  }

  /// A one-line summary of the real check-in data, for the Family Status card.
  static String _familyStatus(CheckIn? today, CheckIn? next) {
    switch (today?.status) {
      case CheckInStatus.missed:
        return "Today's check-in was missed.";
      case CheckInStatus.completed:
        return "Today's check-in has been completed.";
      case CheckInStatus.inProgress:
        return "Today's check-in is in progress.";
      case CheckInStatus.scheduled:
      case CheckInStatus.ready:
        return "Today's check-in is coming up.";
      case CheckInStatus.cancelled:
      case null:
        return next == null
            ? 'No upcoming check-ins are scheduled.'
            : 'The next check-in is scheduled.';
    }
  }

  Widget _buildRow({
    required CheckIn? today,
    required CheckIn? next,
    required String familyStatus,
    String? message,
    String detail = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCards(today: today, next: next, message: message, detail: detail),
        const SizedBox(height: 12),
        _FamilyStatusCard(message: familyStatus),
      ],
    );
  }

  Widget _buildCards({
    required CheckIn? today,
    required CheckIn? next,
    String? message,
    String detail = '',
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
                ? detail
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
                ? detail
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
  const _FamilyStatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF2E8D3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded,
              color: FamilyDashboardScreen._ink, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Family Status',
                  style: TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
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

/// One recorded change to a check-in, timestamped by the field written when
/// that change happened.
class _CheckInUpdate {
  const _CheckInUpdate({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.at,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final DateTime at;
}

/// The linked elder's latest check-in activity, live from Firestore.
///
/// Uses the same `check_ins` query as [FamilyCheckInService.watchSummary],
/// so Firestore serves both from one watch target.
class _UpdatesCard extends StatefulWidget {
  const _UpdatesCard({
    required this.elderId,
    this.loading = false,
    this.linkError,
  });

  final String? elderId;
  final bool loading;
  final Object? linkError;

  @override
  State<_UpdatesCard> createState() => _UpdatesCardState();
}

class _UpdatesCardState extends State<_UpdatesCard> {
  static const _maxUpdates = 3;

  Stream<List<_CheckInUpdate>>? _updates;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(_UpdatesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elderId != widget.elderId) _subscribe();
  }

  void _subscribe() {
    final elderId = widget.elderId ?? '';
    if (elderId.isEmpty) {
      _updates = null;
      return;
    }
    _updates = FirebaseFirestore.instance
        .collection('check_ins')
        .where('elderId', isEqualTo: elderId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final updates = snapshot.docs
          .map((doc) => doc.data())
          .map((data) => _updateFrom(data, now))
          .whereType<_CheckInUpdate>()
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
      return updates.take(_maxUpdates).toList();
    });
  }

  /// The check-in's latest recorded change, or null when the document has
  /// no timestamp for it (e.g. written before that field existed).
  static _CheckInUpdate? _updateFrom(Map<String, dynamic> data, DateTime now) {
    DateTime? field(String name) {
      final value = data[name];
      return value is Timestamp ? value.toDate() : null;
    }

    final scheduledAt = field('scheduledAt');
    final status = CheckInStatus.values
        .where((status) => status.name == data['status'])
        .firstOrNull;
    final slot = scheduledAt == null
        ? ''
        : '${_CheckInRowState._dayLabel(scheduledAt)}, '
            '${_CheckInRowState._formatTime(scheduledAt)}';

    final _CheckInUpdate? update;
    switch (status) {
      case CheckInStatus.completed:
        final at = field('completedAt');
        update = at == null
            ? null
            : _CheckInUpdate(
                icon: Icons.check_rounded,
                iconColor: FamilyDashboardScreen._success,
                title: 'Check-in completed',
                at: at,
              );
      case CheckInStatus.inProgress:
        final at = field('startedAt');
        update = at == null
            ? null
            : _CheckInUpdate(
                icon: Icons.videocam_rounded,
                iconColor: FamilyDashboardScreen._ink,
                title: 'Check-in started',
                at: at,
              );
      case CheckInStatus.missed:
        // Nothing stamps when a check-in is marked missed, so use the slot
        // it missed, and only once that slot has passed.
        update = scheduledAt == null || scheduledAt.isAfter(now)
            ? null
            : _CheckInUpdate(
                icon: Icons.error_outline_rounded,
                iconColor: const Color(0xFFC62828),
                title: 'Check-in missed',
                at: scheduledAt,
              );
      case CheckInStatus.cancelled:
        final at = field('updatedAt');
        update = at == null
            ? null
            : _CheckInUpdate(
                icon: Icons.event_busy_rounded,
                iconColor: FamilyDashboardScreen._muted,
                title: slot.isEmpty
                    ? 'Check-in cancelled'
                    : 'Check-in for $slot cancelled',
                at: at,
              );
      case CheckInStatus.ready:
        // Only rescheduling moves a check-in to ready.
        final at = field('updatedAt');
        update = at == null || slot.isEmpty
            ? null
            : _CheckInUpdate(
                icon: Icons.calendar_month_rounded,
                iconColor: FamilyDashboardScreen._ink,
                title: 'Check-in moved to $slot',
                at: at,
              );
      case CheckInStatus.scheduled:
        final at = field('createdAt');
        update = at == null || slot.isEmpty
            ? null
            : _CheckInUpdate(
                icon: Icons.calendar_month_rounded,
                iconColor: FamilyDashboardScreen._ink,
                title: 'Check-in scheduled for $slot',
                at: at,
              );
      case null:
        update = null;
    }
    return update;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return _buildMessage('Loading updates...');
    if (widget.linkError != null) {
      return _buildMessage("Family link couldn't be loaded");
    }
    if (_updates == null) return _buildMessage('No family member linked yet');
    return StreamBuilder<List<_CheckInUpdate>>(
      stream: _updates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Family updates stream error: ${snapshot.error}',
          );
          return _buildMessage(_isPermissionDenied(snapshot.error)
              ? 'No permission to view these updates'
              : 'Updates are unavailable right now');
        }
        if (!snapshot.hasData) return _buildMessage('Loading updates...');
        final updates = snapshot.data!;
        if (updates.isEmpty) return _buildMessage('No recent updates yet');
        return _buildCard([
          for (final update in updates)
            _UpdateRow(
              icon: update.icon,
              iconColor: update.iconColor,
              title: update.title,
              time: '${_CheckInRowState._dayLabel(update.at)}, '
                  '${_CheckInRowState._formatTime(update.at)}',
            ),
        ]);
      },
    );
  }

  Widget _buildMessage(String message) => _buildCard([
        _UpdateRow(
          icon: Icons.info_outline_rounded,
          iconColor: FamilyDashboardScreen._muted,
          title: message,
          time: '',
        ),
      ]);

  Widget _buildCard(List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0xFFE7F6F1)),
            rows[i],
          ],
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
