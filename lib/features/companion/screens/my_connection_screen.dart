import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../elder/models/check_in.dart';
import '../../elder/screens/my_schedule_screen.dart';
import '../../elder/services/firebase_elder_service.dart';
import '../../elder/widgets/elder_colors.dart';
import '../../elder/widgets/elder_ui.dart';
import '../widgets/companion_profile_avatar.dart';

/// The Student Companion's connection details, before entering My Schedule.
/// Uses existing matching connection documents without changing their logic.
class MyConnectionScreen extends StatefulWidget {
  const MyConnectionScreen({super.key});

  @override
  State<MyConnectionScreen> createState() => _MyConnectionScreenState();
}

class _MyConnectionScreenState extends State<MyConnectionScreen> {
  final _elderService = FirebaseElderService.instance;
  bool _loading = true;
  String? _error;
  String _companionName = 'Student Companion';
  String? _companionPhoto;
  String _verification = '';
  String _connectionStatus = 'active';
  List<String> _interests = [];
  DateTime? _nextCheckIn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contextData = await _elderService.getCurrentFlowContext();
      final db = FirebaseFirestore.instance;
      final profile = await db
          .collection('companion_profiles')
          .doc(contextData.companionId)
          .get();
      final user = await db
          .collection('users')
          .doc(contextData.companionId)
          .get();
      final connection = await db
          .collection('connections')
          .doc(contextData.connectionId)
          .get();
      final profileData = profile.data() ?? <String, dynamic>{};
      final userData = user.data() ?? <String, dynamic>{};

      DateTime? nextCheckIn;
      try {
        final checkIns = await _elderService.getCheckIns();
        final now = DateTime.now();
        final future = checkIns
            .where(
              (c) =>
                  c.scheduledAt.isAfter(now) &&
                  c.status != CheckInStatus.completed &&
                  c.status != CheckInStatus.cancelled &&
                  c.status != CheckInStatus.missed,
            )
            .toList();
        future.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        if (future.isNotEmpty) nextCheckIn = future.first.scheduledAt;
      } catch (_) {
        // Still show connection information if the check-in query needs an index.
      }

      if (!mounted) return;
      setState(() {
        _companionName =
            (profileData['fullName'] as String?) ??
            (userData['fullName'] as String?) ??
            contextData.companionName;
        _companionPhoto =
            (profileData['profileImageUrl'] as String?) ??
            (userData['profileImageUrl'] as String?);
        _verification =
            (userData['verificationStatus'] as String?) ??
            (profileData['verificationStatus'] as String?) ??
            '';
        _connectionStatus =
            (connection.data()?['status'] as String?) ?? 'active';
        _interests = (profileData['interests'] is List)
            ? (profileData['interests'] as List)
                  .whereType<String>()
                  .take(3)
                  .toList()
            : <String>[];
        _nextCheckIn = nextCheckIn;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _formattedNext(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${days[date.weekday - 1]} • $hour:$minute $period';
  }

  void _openSchedule() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const MyScheduleScreen()));

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      bottomNavigationBar: _bottomNav(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(19, 12, 19, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: ElderColors.darkTeal,
                      size: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: ElderColors.darkTeal,
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'CareLink',
                  style: TextStyle(
                    color: ElderColors.darkTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'My Connection',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Your active companion and next actions.',
              style: TextStyle(color: ElderColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 11),
            Container(width: 34, height: 3, color: ElderColors.coral),
            const SizedBox(height: 22),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: ElderColors.darkTeal),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: ElderColors.darkTeal,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Unable to load your connection.\n$_error',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              _profileCard(),
              const SizedBox(height: 20),
              _nextCard(),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _openSchedule,
                  style: FilledButton.styleFrom(
                    backgroundColor: ElderColors.darkTeal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'View / Schedule Check-in',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 46),
              const Text(
                'Manage connection',
                style: TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These actions do not affect completed check-ins.',
                style: TextStyle(color: ElderColors.textMuted, fontSize: 11),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ElderColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x11000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CompanionProfileAvatar(
              name: _companionName,
              imageUrl: _companionPhoto,
              size: 62,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _companionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_verification == 'verified') ...[
                    const SizedBox(height: 5),
                    _chip(
                      '✓ Verified Companion',
                      const Color(0xFFD9F6EE),
                      ElderColors.darkTeal,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _chip(
              _connectionStatus == 'paused' ? '● Paused' : '● Active',
              const Color(0xFFDEF5EB),
              ElderColors.darkTeal,
            ),
            ..._interests.map(
              (e) => _chip(e, const Color(0xFFFFF3F0), ElderColors.coral),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _chip(String label, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _nextCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    decoration: BoxDecoration(
      color: ElderColors.mintSoft,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: ElderColors.border),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next check-in',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.darkTeal,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _nextCheckIn == null
                    ? 'No upcoming check-in'
                    : _formattedNext(_nextCheckIn!),
                style: const TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _openSchedule,
          icon: const Icon(Icons.chevron_right, color: ElderColors.darkTeal),
        ),
      ],
    ),
  );

  Widget _bottomNav() => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: 1,
    backgroundColor: Colors.white,
    selectedItemColor: ElderColors.darkTeal,
    unselectedItemColor: ElderColors.textMuted,
    onTap: (i) {
      if (i == 0) Navigator.of(context).maybePop();
      if (i == 2) _openSchedule();
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite_border_rounded),
        label: 'Matches',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        label: 'Check-ins',
      ),
    ],
  );
}
