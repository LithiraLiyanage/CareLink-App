import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../companion/widgets/companion_profile_avatar.dart';

import '../../companion/screens/student_companion_home_screen.dart';
import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'kamala_ready_screen.dart';
import 'memory_lane_screen.dart';
import 'new_recurring_checkin_screen.dart';
import 'reschedule_checkin_screen.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  List<CheckIn> _checkIns = <CheckIn>[];
  ElderFlowContext? _connection;
  String? _companionPhotoUrl;
  bool _loading = true;
  String? _error;
  int _selectedTab = 1; // Today, Upcoming, Past

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final connection = await _service.getCurrentFlowContext();
      final items = await _service.getCheckIns();
      String? companionPhotoUrl;
      try {
        final companionProfile = await FirebaseFirestore.instance
            .collection('companion_profiles')
            .doc(connection.companionId)
            .get();
        companionPhotoUrl =
            companionProfile.data()?['profileImageUrl'] as String?;
        if (companionPhotoUrl == null || companionPhotoUrl.isEmpty) {
          final user = await FirebaseFirestore.instance
              .collection('users')
              .doc(connection.companionId)
              .get();
          companionPhotoUrl = user.data()?['profileImageUrl'] as String?;
        }
      } catch (_) {
        // The bundled avatar still works if a remote image is unavailable.
      }
      if (!mounted) return;

      items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      setState(() {
        _connection = connection;
        _companionPhotoUrl = companionPhotoUrl;
        _checkIns = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _loadCheckIns();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const StudentCompanionHomeScreen(),
      ),
      (route) => false,
    );
  }

  void _openCreate() {
    if (_loading) return;
    if (_connection == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Accept an Elder request before creating a check-in.',
            ),
          ),
        );
      return;
    }
    _openAndRefresh(const NewRecurringCheckInScreen());
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isFinished(CheckIn checkIn) =>
      checkIn.status == CheckInStatus.completed ||
      checkIn.status == CheckInStatus.cancelled ||
      checkIn.status == CheckInStatus.missed;

  List<CheckIn> get _visibleCheckIns {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final filtered = _checkIns.where((checkIn) {
      final finished = _isFinished(checkIn);
      switch (_selectedTab) {
        case 0:
          return !finished && _sameDay(checkIn.scheduledAt, now);
        case 1:
          // Upcoming includes today's remaining sessions.
          return !finished && !checkIn.scheduledAt.isBefore(startOfToday);
        case 2:
          return finished || checkIn.scheduledAt.isBefore(startOfToday);
        default:
          return false;
      }
    }).toList();

    if (_selectedTab == 2) {
      filtered.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    } else {
      filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    return filtered;
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
              'Your upcoming companion check-ins',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(child: _mainContent()),
            const SizedBox(height: 10),
            ElderPrimaryButton(
              label: '+  Create recurring check-in',
              color: ElderColors.darkTeal,
              height: 54,
              onPressed: _openCreate,
            ),
            const SizedBox(height: 10),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _mainContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ElderColors.darkTeal),
      );
    }
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: ElderColors.darkTeal,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Could not load your check-ins.\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ElderColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loadCheckIns,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _visibleCheckIns;
    if (visible.isEmpty) {
      final message = _selectedTab == 0
          ? 'No check-ins scheduled for today.'
          : _selectedTab == 2
          ? 'No past check-ins yet.'
          : 'No upcoming check-ins yet.\nCreate your first recurring check-in below.';
      return RefreshIndicator(
        onRefresh: _loadCheckIns,
        color: ElderColors.darkTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [const SizedBox(height: 26), _emptySchedule(message)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCheckIns,
      color: ElderColors.darkTeal,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 1, bottom: 12),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final checkIn = visible[index];
          final finished = _isFinished(checkIn);
          return _scheduleCard(
            checkIn: checkIn,
            badge: finished
                ? checkIn.status.name.toUpperCase()
                : index == 0
                ? 'NEXT'
                : 'RECURRING',
            filledBadge: !finished && index == 0,
            onTap: finished
                ? null
                : () => _openAndRefresh(
                    // Next check-in can open the ready screen directly.
                    // Other scheduled sessions can be rescheduled first.
                    index == 0
                        ? KamalaReadyScreen(checkInId: checkIn.id)
                        : RescheduleCheckInScreen(checkInId: checkIn.id),
                  ),
          );
        },
      ),
    );
  }

  Widget _topBar() {
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
    const labels = <String>['Today', 'Upcoming', 'Past'];
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ElderColors.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(13),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
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
                  labels[index],
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _emptySchedule(String message) {
    return Container(
      height: 116,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ElderColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ElderColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _scheduleCard({
    required CheckIn checkIn,
    required String badge,
    required VoidCallback? onTap,
    bool filledBadge = false,
  }) {
    final companionName = checkIn.companionName.trim().isEmpty
        ? (_connection?.companionName ?? 'Student Companion')
        : checkIn.companionName.trim();
    final firstName = companionName.split(RegExp(r'\s+')).first;
    final companionLabel = firstName.isEmpty
        ? 'Companion'
        : '${firstName[0].toUpperCase()}${firstName.substring(1)}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 100,
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
            CompanionProfileAvatar(
              name: companionName,
              imageUrl: _companionPhotoUrl,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatSchedule(checkIn.scheduledAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$companionLabel • ${checkIn.mode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            ElderStatusPill(badge, filled: filledBadge),
          ],
        ),
      ),
    );
  }

  String _formatSchedule(DateTime date) {
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final label = _sameDay(date, today) ? 'Today' : days[date.weekday - 1];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$label • $hour:$minute $period';
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
