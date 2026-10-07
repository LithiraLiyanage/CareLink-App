import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'memory_lane_screen.dart';
import 'my_schedule_screen.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;
  StreamSubscription<ElderConnectionDetails?>? _connectionSubscription;
  ElderConnectionDetails? _connection;
  String? _scheduleConnectionId;
  Stream<ElderScheduleData>? _scheduleStream;
  String _elderName = '';
  Object? _connectionError;
  Object? _elderNameError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadElderName();
    _connectionSubscription = _service
        .watchActiveConnectionForCurrentElder()
        .listen(
          (connection) {
            if (!mounted) return;
            if (_connection?.id != connection?.id) {
              _scheduleConnectionId = null;
              _scheduleStream = null;
            }
            setState(() {
              _connection = connection;
              _connectionError = null;
              _loading = false;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _connectionError = error;
              _loading = false;
            });
          },
        );
  }

  @override
  void dispose() {
    unawaited(_connectionSubscription?.cancel());
    super.dispose();
  }

  Future<void> _loadElderName() async {
    try {
      final name = await _service.getCurrentElderName();
      if (mounted) {
        setState(() {
          _elderName = name;
          _elderNameError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _elderNameError = error);
    }
  }

  Stream<ElderScheduleData> _watchSchedule() {
    final connection = _connection!;
    if (_scheduleConnectionId != connection.id || _scheduleStream == null) {
      _scheduleConnectionId = connection.id;
      _scheduleStream = _service.watchScheduleForConnection(
        elderId: connection.elderId,
        companionId: connection.companionId,
        connectionId: connection.id,
      );
    }
    return _scheduleStream!;
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openSchedule(BuildContext context) {
    final connection = _connection;
    _open(
      context,
      MyScheduleScreen(
        connectionId: connection?.id,
        elderId: connection?.elderId,
        elderName: connection?.elderName,
        companionId: connection?.companionId,
        companionName: connection?.companionName,
        companionImageUrl: connection?.companionImageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _elderName.trim().isEmpty
        ? 'Older Adult'
        : _elderName.trim().split(RegExp(r'\s+')).first;
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.darkTeal,
      darkStatusBar: false,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onSchedule: () => _openSchedule(context),
        onMemory: () => _open(context, const MemoryLaneScreen()),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(displayName),
            _checkInCard(context),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 9),
              child: Text(
                'Quick actions',
                style: TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _quickActions(context),
            const SizedBox(height: 14),
            _reminder(),
          ],
        ),
      ),
    );
  }

  Widget _header(String firstName) {
    return Container(
      height: 165,
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 14),
      decoration: const BoxDecoration(
        color: ElderColors.darkTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  'C',
                  style: TextStyle(
                    color: ElderColors.darkTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'CareLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _connection == null
                          ? 'Your companion connection'
                          : 'Connected with ${_connection!.companionName}',
                      style: const TextStyle(
                        color: Color(0xFFD7EBE8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (_connection?.companionImageUrl case final url?
                  when url.isNotEmpty)
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(url),
                  onBackgroundImageError: (_, _) {},
                )
              else
                CircleAvatar(
                  radius: 32,
                  backgroundColor: ElderColors.mint,
                  child: Text(
                    firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: ElderColors.darkTeal,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkInCard(BuildContext context) {
    final connection = _connection;
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (connection?.companionImageUrl case final url?
                        when url.isNotEmpty)
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _companionPlaceholder(
                          connection?.companionName ?? '',
                        ),
                      )
                    else
                      _companionPlaceholder(connection?.companionName ?? ''),
                    if (connection != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          color: const Color(0xB9144A47),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${connection.companionName} · '
                                  '${connection.companionVerified ? 'verified companion' : 'companion'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ElderStatusPill('ACTIVE', filled: true),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
              child: Column(
                children: [
                  if (_loading)
                    const LinearProgressIndicator()
                  else if (_connectionError ?? _elderNameError
                      case final error?)
                    Text(
                      'Could not load connection or schedule: $error',
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (connection == null)
                    const Text(
                      'You do not have an active companion yet.',
                      style: TextStyle(
                        color: ElderColors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  else
                    StreamBuilder<ElderScheduleData>(
                      stream: _watchSchedule(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                            'Could not load your check-in: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        final next = _nextCheckIn(snapshot.data!);
                        if (next == null) {
                          return Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: ElderColors.darkTeal,
                                size: 23,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      connection.companionName,
                                      style: const TextStyle(
                                        color: ElderColors.textDark,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Next check-in: Not scheduled yet',
                                      style: TextStyle(
                                        color: ElderColors.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return _scheduledSummary(context, next);
                      },
                    ),
                  const SizedBox(height: 11),
                  ElderPrimaryButton(
                    label: connection == null
                        ? 'Find a Companion'
                        : 'My Schedule',
                    color: ElderColors.coral,
                    height: 52,
                    onPressed: connection == null
                        ? () =>
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.companionMatching)
                        : () => _openSchedule(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _companionPlaceholder(String name) => Container(
    color: ElderColors.deepTeal,
    alignment: Alignment.center,
    child: CircleAvatar(
      radius: 43,
      backgroundColor: ElderColors.mintSoft,
      child: Text(
        name
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0])
            .join(),
        style: const TextStyle(
          color: ElderColors.darkTeal,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  ({DateTime at, int duration, String mode, String companionName})?
  _nextCheckIn(ElderScheduleData data) {
    final now = DateTime.now();
    final oneOff =
        data.checkIns
            .where(
              (item) =>
                  (item.status == CheckInStatus.scheduled ||
                      item.status == CheckInStatus.ready ||
                      item.status == CheckInStatus.inProgress) &&
                  !item.scheduledAt.isBefore(now),
            )
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (oneOff.isNotEmpty) {
      final next = oneOff.first;
      return (
        at: next.scheduledAt,
        duration: next.durationMinutes,
        mode: next.mode,
        companionName: next.companionName,
      );
    }
    final recurring =
        data.recurringSchedules
            .map(
              (schedule) =>
                  (schedule: schedule, next: schedule.nextOccurrence(now)),
            )
            .where((item) => item.next != null)
            .toList()
          ..sort((a, b) => a.next!.compareTo(b.next!));
    if (recurring.isEmpty) return null;
    final next = recurring.first;
    return (
      at: next.next!,
      duration: next.schedule.durationMinutes,
      mode: next.schedule.mode,
      companionName: next.schedule.companionName,
    );
  }

  Widget _scheduledSummary(
    BuildContext context,
    ({DateTime at, int duration, String mode, String companionName}) item,
  ) {
    final localizations = MaterialLocalizations.of(context);
    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          color: ElderColors.darkTeal,
          size: 23,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.companionName,
                style: const TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.formatMediumDate(item.at)} · '
                '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(item.at))} · '
                '${item.duration} min · ${item.mode}',
                style: const TextStyle(
                  color: ElderColors.textMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    Widget item(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: ElderColors.mint,
              border: Border.all(color: ElderColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: ElderColors.textDark, size: 27),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          item(
            Icons.schedule_rounded,
            'Schedule',
            () => _openSchedule(context),
          ),
          const SizedBox(width: 8),
          item(
            Icons.menu_book_rounded,
            'Memory Lane',
            () => _open(context, const MemoryLaneScreen()),
          ),
          const SizedBox(width: 8),
          item(
            Icons.help_outline_rounded,
            'Need Help',
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help options will open here.')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: ElderColors.success,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ElderColors.coral,
            child: Icon(
              Icons.favorite_border_rounded,
              color: ElderColors.textDark,
              size: 21,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A gentle reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Take your time. You can end or\nreschedule anytime.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.18,
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
