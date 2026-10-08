import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../models/check_in_scheduling.dart';
import '../models/recurring_schedule.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';

import 'active_video_call_screen.dart';
import 'checkin_complete_nethmi_screen.dart';
import 'elder_home_screen.dart';
import 'memory_lane_screen.dart';
import 'nethmi_ready_screen.dart';
import 'new_recurring_checkin_screen.dart';
import 'reschedule_checkin_screen.dart';

enum _ScheduleTab { today, upcoming, past }

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({
    super.key,
    this.connectionId,
    this.elderId,
    this.elderName,
    this.companionId,
    this.companionName,
    this.companionImageUrl,
    this.preferredCheckInType,
    this.navigationOnly = false,
  });

  final String? connectionId;
  final String? elderId;
  final String? elderName;
  final String? companionId;
  final String? companionName;
  final String? companionImageUrl;
  final String? preferredCheckInType;
  final bool navigationOnly;

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  ElderConnectionDetails? _connection;
  Stream<ElderScheduleData>? _scheduleStream;

  _ScheduleTab _selectedTab = _ScheduleTab.upcoming;
  bool _loading = true;
  bool _openingCall = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    if (widget.navigationOnly) {
      _loading = false;
    } else {
      _loadConnection();
    }
  }

  Future<void> _loadConnection() async {
    try {
      final connection = await _service.getActiveConnectionForCurrentElder();

      if (!mounted) return;

      if (connection != null &&
          widget.connectionId != null &&
          widget.connectionId != connection.id) {
        throw StateError('The selected connection is no longer active.');
      }

      setState(() {
        _connection = connection;

        _scheduleStream = connection == null
            ? null
            : _service.watchScheduleForConnection(
                elderId: connection.elderId,
                companionId: connection.companionId,
                connectionId: connection.id,
              );

        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    if (!mounted || widget.navigationOnly) return;

    // The Firestore stream updates records automatically.
    // Refresh connection information after returning.
    await _loadConnection();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ElderHomeScreen()),
      (_) => false,
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<CheckIn> _visibleCheckIns(List<CheckIn> all) {
    final now = DateTime.now();

    final filtered = all.where((checkIn) {
      if (checkIn.status == CheckInStatus.cancelled) {
        return false;
      }

      switch (_selectedTab) {
        case _ScheduleTab.today:
          return _sameDay(checkIn.scheduledAt, now);

        case _ScheduleTab.upcoming:
          return checkIn.scheduledAt.isAfter(now) &&
              !_sameDay(checkIn.scheduledAt, now) &&
              CheckInScheduling.isActiveUpcoming(checkIn);

        case _ScheduleTab.past:
          return checkIn.status == CheckInStatus.completed ||
              checkIn.status == CheckInStatus.missed ||
              checkIn.scheduledAt
                  .add(Duration(minutes: checkIn.durationMinutes))
                  .isBefore(now);
      }
    }).toList();

    filtered.sort((a, b) {
      if (_selectedTab == _ScheduleTab.past) {
        return b.scheduledAt.compareTo(a.scheduledAt);
      }
      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    return filtered;
  }

  void _openCheckIn(CheckIn checkIn) {
    if (widget.navigationOnly) {
      _showMessage('This is a navigation preview.');
      return;
    }

    if (checkIn.status == CheckInStatus.completed) {
      _showMessage('This check-in is already completed.');
      return;
    }

    if (checkIn.status == CheckInStatus.cancelled ||
        checkIn.status == CheckInStatus.missed) {
      _showMessage('This check-in is no longer available.');
      return;
    }

    if (CheckInScheduling.canOpenReadyScreen(checkIn)) {
      _openAndRefresh(
        NethmiReadyScreen(
          companionName: checkIn.companionName,
          companionImageUrl:
              checkIn.companionImageUrl ?? _connection?.companionImageUrl,
          scheduledAt: checkIn.scheduledAt,
          durationMinutes: checkIn.durationMinutes,
          mode: checkIn.mode,

          // Override the ready screen's demo call navigation.
          // Always use this selected real check-in.
          onStartCall: () => _startCall(checkIn, 'Video'),
          onVoiceCall: () => _startCall(checkIn, 'Voice'),
        ),
      );
      return;
    }

    if (CheckInScheduling.isDue(checkIn) &&
        !CheckInScheduling.companionReadinessConfirmed(checkIn)) {
      _showMessage('Waiting for your Student Companion to become ready.');
      return;
    }

    _openAndRefresh(RescheduleCheckInScreen(checkInId: checkIn.id));
  }

  Future<void> _startCall(CheckIn checkIn, String callType) async {
    if (_openingCall) return;

    if (!CheckInScheduling.canOpenReadyScreen(checkIn)) {
      _showMessage('This check-in is not ready yet.');
      return;
    }

    final connection = _connection;

    if (connection == null ||
        connection.elderId != checkIn.elderId ||
        connection.companionId != checkIn.companionId) {
      _showMessage('The active connection could not be verified.');
      return;
    }

    setState(() => _openingCall = true);

    try {
      final latest = await _service.getCheckInById(checkIn.id);

      if (latest == null || !CheckInScheduling.canOpenReadyScreen(latest)) {
        throw StateError('The check-in is no longer ready.');
      }

      await _service.updateCheckInStatus(checkIn.id, CheckInStatus.inProgress);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (callContext) => ActiveVideoCallScreen(
            elderId: connection.elderId,
            elderName: checkIn.elderName,
            elderImageUrl: checkIn.elderImageUrl,
            companionId: connection.companionId,
            companionName: checkIn.companionName,
            companionImageUrl:
                checkIn.companionImageUrl ?? connection.companionImageUrl,
            connectionId: connection.id,
            checkInId: checkIn.id,
            scheduledAt: checkIn.scheduledAt,
            durationMinutes: checkIn.durationMinutes,
            callType: callType,
            onEndCall: () async {
              await _service.updateCheckInStatus(
                checkIn.id,
                CheckInStatus.completed,
              );

              if (!callContext.mounted) return;

              Navigator.of(callContext).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => CheckInCompleteNethmiScreen(
                    companionName: checkIn.companionName,
                    companionImageUrl:
                        checkIn.companionImageUrl ??
                        connection.companionImageUrl,
                    scheduledAt: checkIn.scheduledAt,
                    durationMinutes: checkIn.durationMinutes,
                    mode: callType,
                  ),
                ),
                (_) => false,
              );
            },
          ),
        ),
      );
    } catch (error) {
      _showMessage('Could not start the check-in: $error');
    } finally {
      if (mounted) {
        setState(() => _openingCall = false);
      }
    }
  }

  void _createRecurringCheckIn() {
    final connection = _connection;

    if (connection == null) {
      _showMessage('Connect with a Student Companion first.');
      return;
    }

    _openAndRefresh(
      NewRecurringCheckInScreen(
        connectionId: connection.id,
        elderId: connection.elderId,
        elderName: connection.elderName,
        companionId: connection.companionId,
        companionName: connection.companionName,
        preferredCheckInType: widget.preferredCheckInType,
        navigationOnly: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 1,
        onHome: _goHome,
        onSchedule: () {},
        onMemory: () => _openAndRefresh(const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            const SizedBox(height: 10),
            const Text(
              'My Schedule',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your companion check-ins',
              style: TextStyle(color: ElderColors.textMuted, fontSize: 10.5),
            ),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 16),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ElderColors.darkTeal),
      );
    }

    if (_error != null) {
      return _errorView(_error!);
    }

    if (_scheduleStream == null) {
      return _scheduleContent(
        const ElderScheduleData(checkIns: [], recurringSchedules: []),
      );
    }

    return StreamBuilder<ElderScheduleData>(
      stream: _scheduleStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: ElderColors.darkTeal),
          );
        }

        return _scheduleContent(snapshot.data!);
      },
    );
  }

  Widget _errorView(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36, color: ElderColors.coral),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ElderColors.textDark),
          ),
          const SizedBox(height: 12),
          ElderOutlineButton(
            label: 'Try again',
            onPressed: () {
              setState(() => _loading = true);
              _loadConnection();
            },
          ),
        ],
      ),
    );
  }

  Widget _scheduleContent(ElderScheduleData data) {
    final visible = _visibleCheckIns(data.checkIns);

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                _scheduleCard(
                  checkIn: visible[i],
                  badge: _statusLabel(visible[i], i),
                  onTap: () => _openCheckIn(visible[i]),
                ),
                const SizedBox(height: 12),
              ],
              if (_selectedTab == _ScheduleTab.upcoming)
                for (final schedule in data.recurringSchedules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _recurringCard(schedule),
                  ),
              if (visible.isEmpty &&
                  (_selectedTab != _ScheduleTab.upcoming ||
                      data.recurringSchedules.isEmpty))
                _emptyState(),
            ],
          ),
        ),
        if (_connection != null) ...[
          const SizedBox(height: 10),
          ElderPrimaryButton(
            label: '+  Create recurring check-in',
            color: ElderColors.darkTeal,
            height: 54,
            onPressed: _createRecurringCheckIn,
          ),
        ],
        const SizedBox(height: 10),
        _infoCard(),
      ],
    );
  }

  String _statusLabel(CheckIn checkIn, int index) {
    switch (checkIn.status) {
      case CheckInStatus.ready:
        return 'READY';
      case CheckInStatus.inProgress:
        return 'IN CALL';
      case CheckInStatus.completed:
        return 'COMPLETED';
      case CheckInStatus.cancelled:
        return 'CANCELLED';
      case CheckInStatus.missed:
        return 'MISSED';
      case CheckInStatus.scheduled:
        return index == 0 ? 'NEXT' : 'SCHEDULED';
    }
  }

  Widget _tabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ElderColors.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _tabButton('Today', _ScheduleTab.today),
          _tabButton('Upcoming', _ScheduleTab.upcoming),
          _tabButton('Past', _ScheduleTab.past),
        ],
      ),
    );
  }

  Widget _tabButton(String label, _ScheduleTab tab) {
    final selected = _selectedTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tab),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ElderColors.textDark,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleCard({
    required CheckIn checkIn,
    required String badge,
    required VoidCallback onTap,
  }) {
    final name = checkIn.companionName;
    final imageUrl =
        checkIn.companionImageUrl ?? _connection?.companionImageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0x6693CFC4)),
        ),
        child: Row(
          children: [
            _avatar(name, imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatSchedule(checkIn.scheduledAt),
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$name · ${checkIn.durationMinutes} min · '
                    '${checkIn.mode}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            ElderStatusPill(
              badge,
              filled: checkIn.status == CheckInStatus.ready,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String name, String? imageUrl) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: ElderColors.mintSoft,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: ElderColors.darkTeal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return fallback;
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: ElderColors.mintSoft,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }

  Widget _recurringCard(RecurringSchedule schedule) {
    final next = schedule.nextOccurrence(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ElderColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded, color: ElderColors.darkTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.companionName,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  next == null
                      ? 'Recurring schedule'
                      : 'Recurring · ${_formatSchedule(next)}',
                  style: const TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const ElderStatusPill('RECURRING'),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final message = switch (_selectedTab) {
      _ScheduleTab.today => 'No check-ins today',
      _ScheduleTab.upcoming => 'No upcoming check-ins',
      _ScheduleTab.past => 'No past check-ins',
    };

    return Container(
      height: 104,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: ElderColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatSchedule(DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    final day = localizations.formatMediumDate(date);
    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));

    return '$day · $time';
  }

  Widget _topBar() {
    return Row(
      children: [
        ElderBackButton(onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 10),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: ElderColors.darkTeal,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'C',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 7),
        const Text(
          'CareLink',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0x66A7EEE0),
        border: Border.all(color: const Color(0x6693CFC4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: ElderColors.darkTeal),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can reschedule or cancel your upcoming '
              'check-ins. Calls open when your companion '
              'confirms readiness.',
              style: TextStyle(color: ElderColors.textDark, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
