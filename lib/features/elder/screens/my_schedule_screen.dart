import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../models/recurring_schedule.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'memory_lane_screen.dart';
import 'nethmi_ready_screen.dart';
import 'new_recurring_checkin_screen.dart';
import 'reschedule_checkin_screen.dart';

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

  List<CheckIn> _checkIns = [];
  List<RecurringSchedule> _recurringSchedules = [];
  String? _connectionId;
  String? _elderId;
  String? _elderName;
  String? _companionId;
  String? _companionName;
  String? _companionImageUrl;
  String? _preferredCheckInType;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _connectionId = widget.connectionId;
    _elderId = widget.elderId;
    _elderName = widget.elderName;
    _companionId = widget.companionId;
    _companionName = widget.companionName;
    _companionImageUrl = widget.companionImageUrl;
    _preferredCheckInType = widget.preferredCheckInType;
    if (widget.navigationOnly) {
      _loading = false;
    } else {
      _loadCheckIns();
    }
  }

  Future<void> _loadCheckIns() async {
    try {
      if (_connectionId == null ||
          _elderId == null ||
          _companionId == null ||
          _companionName == null) {
        final connection = await _service.getActiveConnectionForCurrentElder();
        _connectionId = connection?.id;
        _elderId = connection?.elderId;
        _elderName = connection?.elderName;
        _companionId = connection?.companionId;
        _companionName = connection?.companionName;
        _companionImageUrl = connection?.companionImageUrl;
      }

      final elderId = _elderId;
      final companionId = _companionId;
      final connectionId = _connectionId;
      final items = elderId != null && companionId != null
          ? await _service.getCheckInsForConnection(
              elderId: elderId,
              companionId: companionId,
            )
          : <CheckIn>[];
      final schedules =
          elderId != null && companionId != null && connectionId != null
          ? await _service.getRecurringSchedulesForConnection(
              elderId: elderId,
              companionId: companionId,
              connectionId: connectionId,
            )
          : <RecurringSchedule>[];

      if (!mounted) return;

      setState(() {
        _checkIns = items
            .where((item) => item.status != CheckInStatus.cancelled)
            .toList();
        _recurringSchedules = schedules;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    if (!mounted) return;
    if (!widget.navigationOnly) await _loadCheckIns();
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 1,
        onSchedule: () {},
        onMemory: () => _open(context, const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
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
              'Your upcoming companion check-ins',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? _loadingView()
                  : _loadError == null
                  ? _scheduleContent()
                  : _errorView(_loadError!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingView() {
    return const Center(
      child: CircularProgressIndicator(color: ElderColors.darkTeal),
    );
  }

  Widget _errorView(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ElderColors.textDark),
          ),
          const SizedBox(height: 12),
          ElderOutlineButton(
            label: 'Try again',
            height: 44,
            onPressed: () {
              setState(() => _loading = true);
              _loadCheckIns();
            },
          ),
        ],
      ),
    );
  }

  Widget _scheduleContent() {
    final visible = _checkIns.take(3).toList();

    return Column(
      children: [
        for (int index = 0; index < visible.length; index++) ...[
          _scheduleCard(
            checkIn: visible[index],
            badge: index == 0 ? 'NEXT' : 'RECURRING',
            filledBadge: index == 0,
            onTap: () {
              if (index == 0) {
                _openAndRefresh(
                  NethmiReadyScreen(
                    companionName: visible[index].companionName,
                    companionImageUrl: _companionImageUrl,
                    scheduledAt: visible[index].scheduledAt,
                    durationMinutes: visible[index].durationMinutes,
                    mode: visible[index].mode,
                  ),
                );
              } else {
                _openAndRefresh(
                  RescheduleCheckInScreen(checkInId: visible[index].id),
                );
              }
            },
          ),
          if (index != visible.length - 1) const SizedBox(height: 13),
        ],
        if (visible.isEmpty && _recurringSchedules.isEmpty) _emptySchedule(),
        if (visible.isEmpty && _recurringSchedules.isNotEmpty)
          _recurringScheduleCard(_recurringSchedules.first),
        const Spacer(),
        ElderPrimaryButton(
          label: '+  Create recurring check-in',
          color: ElderColors.darkTeal,
          height: 54,
          onPressed: () => _openAndRefresh(
            NewRecurringCheckInScreen(
              connectionId: _connectionId,
              elderId: _elderId,
              elderName: _elderName,
              companionId: _companionId,
              companionName: _companionName,
              preferredCheckInType: _preferredCheckInType,
              navigationOnly: widget.navigationOnly,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _infoCard(),
      ],
    );
  }

  Widget _recurringScheduleCard(RecurringSchedule schedule) {
    final next = schedule.nextOccurrence(DateTime.now());
    final days = schedule.weekdays
        .where((weekday) => weekday >= 1 && weekday <= 7)
        .map(
          (weekday) => const [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun',
          ][weekday - 1],
        )
        .join(' · ');
    return Container(
      height: 104,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ElderColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            schedule.companionName,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            next == null
                ? days
                : '$days · ${TimeOfDay.fromDateTime(next).format(context)}',
            style: const TextStyle(
              color: ElderColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySchedule() {
    return Container(
      height: 104,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ElderColors.border),
      ),
      child: const Text(
        'No upcoming check-ins',
        style: TextStyle(
          color: ElderColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x66005B59)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: ElderColors.darkTeal,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: ElderColors.darkTeal,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'CareLink',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    Widget tab(String label, {bool selected = false}) {
      return Expanded(
        child: Container(
          height: 42,
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
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ElderColors.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [tab('Today'), tab('Upcoming', selected: true), tab('Past')],
      ),
    );
  }

  Widget _scheduleCard({
    required CheckIn checkIn,
    required String badge,
    required VoidCallback onTap,
    bool filledBadge = false,
  }) {
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const ElderAvatar(asset: ElderAssets.nethmiAvatar, size: 48),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${checkIn.companionName.split(' ').first} • ${checkIn.mode}',
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElderStatusPill(badge, filled: filledBadge),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(DateTime value) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[value.weekday - 1];
    final hour = value.hour > 12 ? value.hour - 12 : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$day • $hour:$minute $period';
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x66A7EEE0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x6693CFC4)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.info_outline_rounded,
              color: ElderColors.darkTeal,
              size: 19,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can reschedule or cancel any session.',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 9.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
