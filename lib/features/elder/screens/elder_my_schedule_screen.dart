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
  String? _deletingScheduleId;

  // Figma styling only
  static const Color _background = Color(0xFFF6FAF9);
  static const Color _ink = Color(0xFF123F42);
  static const Color _teal = Color(0xFF095E5C);
  static const Color _mint = Color(0xFFA6F6E2);
  static const Color _mintSoft = Color(0xFFE8F8F4);
  static const Color _coral = Color(0xFFF25266);
  static const Color _muted = Color(0xFF6A8080);
  static const Color _border = Color(0xFFD6E6E2);

  @override
  void initState() {
    super.initState();

    if (widget.navigationOnly) {
      _loading = false;
    } else {
      _loadConnection();
    }
  }

  // =====================================================
  // ORIGINAL FIREBASE CONNECTION LOGIC
  // =====================================================

  Future<void> _loadConnection() async {
    try {
      final connection = await _service.getActiveConnectionForCurrentElder();

      if (!mounted) return;

      if (connection != null &&
          widget.connectionId != null &&
          connection.id != widget.connectionId) {
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

        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
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

  // =====================================================
  // ORIGINAL CHECK-IN FILTERING
  // =====================================================

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

  // =====================================================
  // ORIGINAL CHECK-IN NAVIGATION
  // =====================================================

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

    if (checkIn.status == CheckInStatus.inProgress) {
      _showMessage('This check-in is already in progress.');
      return;
    }

    if (checkIn.status == CheckInStatus.ready) {
      _openAndRefresh(
        NethmiReadyScreen(
          companionName: checkIn.companionName,
          companionImageUrl:
              checkIn.companionImageUrl ?? _connection?.companionImageUrl,
          scheduledAt: checkIn.scheduledAt,
          durationMinutes: checkIn.durationMinutes,
          mode: checkIn.mode,
          onStartCall: () => _startCall(checkIn, 'Video'),
          onVoiceCall: () => _startCall(checkIn, 'Voice'),
        ),
      );
      return;
    }

    if (CheckInScheduling.isDue(checkIn)) {
      if (CheckInScheduling.isCallWindowExpired(checkIn)) {
        _showMessage('This scheduled check-in window has ended.');
      } else {
        _showMessage('Waiting for your Student Companion to become ready.');
      }
      return;
    }

    _openAndRefresh(RescheduleCheckInScreen(checkInId: checkIn.id));
  }

  // =====================================================
  // ORIGINAL REAL WEBRTC CALL FLOW
  // =====================================================

  Future<void> _startCall(CheckIn checkIn, String callType) async {
    if (_openingCall) return;

    final connection = _connection;

    if (connection == null ||
        connection.elderId != checkIn.elderId ||
        connection.companionId != checkIn.companionId) {
      _showMessage('The active connection could not be verified.');
      return;
    }

    if (!CheckInScheduling.canOpenReadyScreen(checkIn)) {
      _showMessage(
        'The check-in is not ready or its '
        'scheduled call window is closed.',
      );
      return;
    }

    if (checkIn.mode == 'Voice' && callType != 'Voice') {
      _showMessage('This is a voice-only check-in.');
      return;
    }

    setState(() {
      _openingCall = true;
    });

    try {
      final active = await _service.getActiveConnectionForCurrentElder();

      if (active == null ||
          active.id != connection.id ||
          active.elderId != checkIn.elderId ||
          active.companionId != checkIn.companionId) {
        throw StateError('Your companion connection is no longer active.');
      }

      final latest = await _service.getCheckInById(checkIn.id);

      if (latest == null ||
          latest.elderId != connection.elderId ||
          latest.companionId != connection.companionId) {
        throw StateError('This check-in is no longer available.');
      }

      if (latest.status != CheckInStatus.ready) {
        throw StateError('Your Student Companion is not ready.');
      }

      if (!CheckInScheduling.isWithinCallWindow(latest)) {
        throw StateError('The scheduled call window is not open.');
      }

      if (latest.mode == 'Voice' && callType != 'Voice') {
        throw StateError('This check-in is voice-only.');
      }

      // Actual connection determines inProgress, not navigation.
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (callContext) => ActiveVideoCallScreen(
            elderId: connection.elderId,
            elderName: latest.elderName,
            elderImageUrl: latest.elderImageUrl,
            companionId: connection.companionId,
            companionName: latest.companionName,
            companionImageUrl:
                latest.companionImageUrl ?? connection.companionImageUrl,
            connectionId: connection.id,
            checkInId: latest.id,
            scheduledAt: latest.scheduledAt,
            durationMinutes: latest.durationMinutes,
            callType: callType,

            onConnected: () async {
              final current = await _service.getCheckInById(latest.id);

              if (current?.status == CheckInStatus.ready) {
                await _service.updateCheckInStatus(
                  latest.id,
                  CheckInStatus.inProgress,
                );
              }
            },

            onEndCall: () async {
              final current = await _service.getCheckInById(latest.id);

              if (current == null) {
                throw StateError('Check-in no longer exists.');
              }

              if (current.status != CheckInStatus.completed) {
                await _service.updateCheckInStatus(
                  latest.id,
                  CheckInStatus.completed,
                );
              }

              if (!callContext.mounted) return;

              Navigator.of(callContext).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => CheckInCompleteNethmiScreen(
                    companionName: latest.companionName,
                    companionImageUrl:
                        latest.companionImageUrl ??
                        connection.companionImageUrl,
                    scheduledAt: latest.scheduledAt,
                    durationMinutes: latest.durationMinutes,
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
      _showMessage('Could not open the call: $error');
    } finally {
      if (mounted) {
        setState(() {
          _openingCall = false;
        });
      }
    }
  }

  // =====================================================
  // ORIGINAL CREATE RECURRING FLOW
  // =====================================================

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

  // =====================================================
  // ORIGINAL DELETE RECURRING FLOW
  // =====================================================

  Future<void> _confirmRemoveRecurring(RecurringSchedule schedule) async {
    if (widget.navigationOnly) {
      _showMessage('This is a navigation preview.');
      return;
    }

    if (_deletingScheduleId != null) return;

    final connection = _connection;

    if (connection == null ||
        schedule.elderId != connection.elderId ||
        schedule.companionId != connection.companionId ||
        (schedule.connectionId != null &&
            schedule.connectionId!.isNotEmpty &&
            schedule.connectionId != connection.id)) {
      _showMessage('This routine is not part of your active connection.');
      return;
    }

    if (schedule.id.trim().isEmpty) {
      _showMessage('Recurring schedule ID is missing.');
      return;
    }

    final next = schedule.nextOccurrence(DateTime.now());

    final when = next == null
        ? ''
        : '\nNext check-in: ${_formatSchedule(next)}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove recurring check-in?'),
          content: Text(
            'Stop the repeating schedule with '
            '${schedule.companionName}?'
            '$when\n\n'
            'Existing individual check-ins will '
            'remain and can be cancelled separately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep schedule'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ElderColors.coral),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove routine'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _deletingScheduleId = schedule.id;
    });

    try {
      final active = await _service.getActiveConnectionForCurrentElder();

      if (active == null ||
          active.id != connection.id ||
          active.elderId != schedule.elderId ||
          active.companionId != schedule.companionId) {
        throw StateError('Active connection changed. Please try again.');
      }

      await _service.deleteRecurringSchedule(schedule.id);

      _showMessage('Recurring routine removed.');
    } catch (error) {
      _showMessage('Could not remove recurring schedule: $error');
    } finally {
      if (mounted) {
        setState(() {
          _deletingScheduleId = null;
        });
      }
    }
  }

  // =====================================================
  // UPDATED FIGMA UI — L02
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: _background,
      statusBarColor: _background,
      darkStatusBar: true,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 1,
        onHome: _goHome,
        onSchedule: () {},
        onMemory: () => _openAndRefresh(const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),

            const SizedBox(height: 13),

            const Text(
              'My Schedule',
              style: TextStyle(
                color: _ink,
                fontSize: 28,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Your upcoming companion check-ins',
              style: TextStyle(color: _muted, fontSize: 12),
            ),

            const SizedBox(height: 17),

            _tabs(),

            const SizedBox(height: 17),

            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FIREBASE STREAM — PRESERVED
  // =====================================================

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
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
          return const Center(child: CircularProgressIndicator(color: _teal));
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
          const Icon(Icons.error_outline_rounded, color: _coral, size: 36),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElderOutlineButton(
            label: 'Try again',
            onPressed: () {
              setState(() {
                _loading = true;
              });
              _loadConnection();
            },
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CHECK-IN LIST + FIXED BOTTOM CONTENT
  // =====================================================

  Widget _scheduleContent(ElderScheduleData data) {
    final visible = _visibleCheckIns(data.checkIns);

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                _scheduleCard(
                  checkIn: visible[i],
                  badge: _statusLabel(visible[i], i),
                  onTap: () => _openCheckIn(visible[i]),
                ),
                const SizedBox(height: 12),
              ],

              // Existing recurring schedules remain
              // visible in the Upcoming tab.
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
          _createButton(),
        ],

        const SizedBox(height: 11),

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

  // =====================================================
  // FIGMA MINT TABS
  // =====================================================

  Widget _tabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _mint,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTab = tab;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _ink.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA SINGLE CHECK-IN CARD
  // =====================================================

  Widget _scheduleCard({
    required CheckIn checkIn,
    required String badge,
    required VoidCallback onTap,
  }) {
    final name = checkIn.companionName;
    final imageUrl =
        checkIn.companionImageUrl ??
        _connection?.companionImageUrl ??
        widget.companionImageUrl;

    final localizations = MaterialLocalizations.of(context);

    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(checkIn.scheduledAt),
    );

    final day = _sameDay(checkIn.scheduledAt, DateTime.now())
        ? 'Today'
        : _shortWeekday(checkIn.scheduledAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 83),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.065),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _avatar(name, imageUrl),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day • $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      '$name · ${checkIn.mode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${localizations.formatMediumDate(checkIn.scheduledAt)}'
                      ' · ${checkIn.durationMinutes} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              _statusBadge(
                badge,
                filled:
                    badge == 'READY' || badge == 'NEXT' || badge == 'IN CALL',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortWeekday(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // =====================================================
  // COMPANION AVATAR — REAL IMAGE OR INITIALS
  // =====================================================

  Widget _avatar(String name, String? imageUrl) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    Widget fallback() {
      return CircleAvatar(
        radius: 26,
        backgroundColor: _mintSoft,
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return fallback();
    }

    return CircleAvatar(
      radius: 27,
      backgroundColor: _coral,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA RECURRING CARD
  // =====================================================

  Widget _recurringCard(RecurringSchedule schedule) {
    final next = schedule.nextOccurrence(DateTime.now());
    final isDeleting = _deletingScheduleId == schedule.id;

    final imageUrl = _connection?.companionImageUrl ?? widget.companionImageUrl;

    final subtitle = next == null
        ? 'Recurring schedule'
        : '${_shortWeekday(next)} • '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(next))}'
              ' · ${schedule.mode}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _deletingScheduleId != null
            ? null
            : () => _confirmRemoveRecurring(schedule),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.055),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              _avatar(schedule.companionName, imageUrl),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.companionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              if (isDeleting)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _teal,
                  ),
                )
              else ...[
                _statusBadge('RECURRING'),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 20, color: _teal),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: filled ? _teal : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _teal, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : _teal,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _emptyState() {
    final message = switch (_selectedTab) {
      _ScheduleTab.today => 'No check-ins today',
      _ScheduleTab.upcoming => 'No upcoming check-ins',
      _ScheduleTab.past => 'No past check-ins',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined, color: _teal, size: 28),
          const SizedBox(height: 13),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSchedule(DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(date)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

  // =====================================================
  // FIGMA HEADER
  // =====================================================

  Widget _topBar() {
    return Row(
      children: [
        ElderBackButton(onPressed: () => Navigator.of(context).maybePop()),

        const SizedBox(width: 11),

        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
          child: const Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(width: 8),

        const Text(
          'CareLink',
          style: TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),

        const Spacer(),

        const CircleAvatar(radius: 4, backgroundColor: _coral),
      ],
    );
  }

  // =====================================================
  // FIGMA CREATE BUTTON
  // =====================================================

  Widget _createButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _createRecurringCheckIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _teal.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '+  Create recurring check-in',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA WHITE REMINDER
  // =====================================================

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFFFFEBED),
            child: Icon(Icons.info_outline_rounded, color: _coral, size: 24),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'You can reschedule or cancel any '
              'upcoming check-in. Calls open when '
              'your companion confirms readiness. '
              'Tap a recurring routine to remove it.',
              style: TextStyle(color: _ink, fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
