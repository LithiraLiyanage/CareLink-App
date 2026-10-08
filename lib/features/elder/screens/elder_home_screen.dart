import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../companion/controllers/companion_controller.dart';
import '../../companion/models/companion_connection.dart';
import '../../companion/models/companion_language.dart';
import '../../companion/models/match_preferences.dart';
import '../../companion/models/match_request.dart';
import '../../companion/screens/connection_accepted_screen.dart';
import '../../companion/services/firebase_companion_service.dart';
import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
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
  bool _openingAcceptedRequest = false;

  // ==========================================
  // FIGMA COLOUR PALETTE
  // ==========================================

  static const Color _darkTeal = Color(0xFF073F46);
  static const Color _primaryTeal = Color(0xFF0E5D5D);
  static const Color _background = Color(0xFFF6FAF9);
  static const Color _mint = Color(0xFFAFF9E4);
  static const Color _mintStrong = Color(0xFFA4F2DC);
  static const Color _coral = Color(0xFFF05263);
  static const Color _reminderGreen = Color(0xFF146755);
  static const Color _mutedText = Color(0xFF5E706B);
  static const Color _border = Color(0xFF91BFB7);

  static const String _elderAvatar =
      'assets/images/carelink_elder_avatar_demo.jpg';

  static const String _heroImage = 'assets/images/carelink_home_hero_demo.jpg';

  // ==========================================
  // FIREBASE - ORIGINAL LOGIC
  // ==========================================

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

      if (!mounted) return;

      setState(() {
        _elderName = name;
        _elderNameError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _elderNameError = error;
      });
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

  // ==========================================
  // NAVIGATION
  // ==========================================

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
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

  void _openCompanionMatching(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.companionMatching);
  }

  Future<void> _openAcceptedRequest(BuildContext context) async {
    final connection = _connection;

    if (connection == null || _openingAcceptedRequest) {
      return;
    }

    setState(() {
      _openingAcceptedRequest = true;
    });

    final companionService = FirebaseCompanionService();

    final controller = CompanionController(service: companionService);

    try {
      final realConnection = await companionService.getCurrentConnection(
        connection.elderId,
      );

      if (realConnection == null ||
          realConnection.id != connection.id ||
          realConnection.status != ConnectionStatus.active ||
          realConnection.companionId != connection.companionId) {
        throw StateError('This connection is no longer active.');
      }

      final profile = await companionService.getCompanionById(
        realConnection.companionId,
      );

      if (profile == null) {
        throw StateError('The verified companion profile is unavailable.');
      }

      controller.selectCompanion(profile);
      controller.currentConnection = realConnection;

      CompanionLanguage language = CompanionLanguage.english;

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('matching_preferences')
            .doc(realConnection.elderId)
            .get();

        final data = snapshot.data();

        if (data != null) {
          final preferences = MatchPreferences.fromMap(data);

          controller.currentPreferences = preferences;

          language = switch (preferences.preferredLanguage.toLowerCase()) {
            'sinhala' || 'සිංහල' => CompanionLanguage.sinhala,
            'tamil' || 'தமிழ்' => CompanionLanguage.tamil,
            _ => CompanionLanguage.english,
          };
        }
      } on FirebaseException catch (error) {
        debugPrint('Could not restore preferences: ${error.code}');
      }

      final requestId = realConnection.matchRequestId;

      if (requestId != null && requestId.isNotEmpty) {
        try {
          final request = await companionService
              .watchMatchRequest(requestId)
              .first;

          if (request != null &&
              request.status == MatchRequestStatus.accepted &&
              request.elderId == realConnection.elderId &&
              request.companionId == realConnection.companionId) {
            controller.currentRequest = request;
          }
        } on FirebaseException catch (error) {
          debugPrint('Could not restore request: ${error.code}');
        }
      }

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConnectionAcceptedScreen(
            profile: profile,
            selectedLanguage: language,
            controller: controller,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open accepted connection: $error')),
      );
    } finally {
      controller.dispose();

      if (mounted) {
        setState(() {
          _openingAcceptedRequest = false;
        });
      }
    }
  }

  // ==========================================
  // MAIN UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final firstName = _elderName.trim().isEmpty
        ? 'Older Adult'
        : _elderName.trim().split(RegExp(r'\s+')).first;

    return ElderPhoneScaffold(
      backgroundColor: _background,
      statusBarColor: _darkTeal,
      darkStatusBar: false,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onSchedule: () => _openSchedule(context),
        onMemory: () => _open(context, const MemoryLaneScreen()),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(firstName),

            if (_connection != null)
              _acceptedNotificationBanner(context, _connection!),

            _checkInCard(context),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 9),
              child: Text(
                'Quick actions',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            _quickActions(context),

            const SizedBox(height: 17),

            _reminder(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DARK FIGMA HEADER
  // ==========================================

  Widget _header(String firstName) {
    return Container(
      width: double.infinity,
      height: 168,
      decoration: const BoxDecoration(
        color: _darkTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 18, 15),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: _darkTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),

                const Text(
                  'CareLink',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const Spacer(),

                IconButton(
                  tooltip: 'Notifications',
                  onPressed: _connection == null
                      ? null
                      : () => _openAcceptedRequest(context),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                      if (_connection != null)
                        const Positioned(
                          right: 1,
                          top: 0,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: _coral,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()} $firstName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          height: 1.13,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 7),

                      Text(
                        _connection == null
                            ? 'Find a companion to get started'
                            : 'Connected with '
                                  '${_connection!.companionName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD0EBE7),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                ClipOval(
                  child: Image.asset(
                    _elderAvatar,
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return CircleAvatar(
                        radius: 39,
                        backgroundColor: const Color(0xFFB5EFE5),
                        child: Text(
                          firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                          style: const TextStyle(
                            color: _darkTeal,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ==========================================
  // ACCEPTED CONNECTION NOTIFICATION
  // ==========================================

  Widget _acceptedNotificationBanner(
    BuildContext context,
    ElderConnectionDetails connection,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 11, 20, 0),
      child: Material(
        color: const Color(0xFFE7F6F1),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _openAcceptedRequest(context),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB5DFD2)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: _primaryTeal,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${connection.companionName} '
                        'accepted your request',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'View request & check-in details',
                        style: TextStyle(color: _mutedText, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right_rounded, color: _primaryTeal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FIGMA PHOTO + CHECK-IN CARD
  // ==========================================

  Widget _checkInCard(BuildContext context) {
    final connection = _connection;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 145,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _heroImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _companionPlaceholder(connection?.companionName ?? ''),
                  ),

                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.05),
                          _darkTeal.withValues(alpha: 0.85),
                        ],
                        stops: const [0.20, 0.55, 1.0],
                      ),
                    ),
                  ),

                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 11,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            connection == null
                                ? 'Find a trusted companion'
                                : '${connection.companionName} · '
                                      '${connection.companionVerified ? 'verified companion' : 'companion'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryTeal,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            connection == null ? 'DISCOVER' : 'ACTIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading)
                  const LinearProgressIndicator(color: _primaryTeal)
                else if (_connectionError != null || _elderNameError != null)
                  Text(
                    'Could not load connection or schedule: '
                    '${_connectionError ?? _elderNameError}',
                    style: const TextStyle(color: _coral, fontSize: 12),
                  )
                else if (connection == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'You do not have an active companion yet.',
                      style: TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  )
                else
                  StreamBuilder<ElderScheduleData>(
                    stream: _watchSchedule(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Could not load your check-in: '
                          '${snapshot.error}',
                          style: const TextStyle(color: _coral, fontSize: 12),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator(
                          color: _primaryTeal,
                        );
                      }

                      final next = _nextCheckIn(snapshot.data!);

                      if (next == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connection.companionName,
                              style: const TextStyle(
                                color: _darkTeal,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Next check-in: Not scheduled yet',
                              style: TextStyle(color: _mutedText, fontSize: 12),
                            ),
                          ],
                        );
                      }

                      return _scheduledSummary(context, next);
                    },
                  ),

                const SizedBox(height: 14),

                if (connection == null)
                  ElderPrimaryButton(
                    label: 'Find a Companion',
                    color: _coral,
                    height: 48,
                    onPressed: () => _openCompanionMatching(context),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElderPrimaryButton(
                          label: 'My Schedule',
                          color: _coral,
                          height: 48,
                          onPressed: () => _openSchedule(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElderOutlineButton(
                          label: 'Find Companion',
                          foregroundColor: _primaryTeal,
                          height: 48,
                          onPressed: () => _openCompanionMatching(context),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _companionPlaceholder(String name) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF047C79), Color(0xFF07504D)],
        ),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 51,
          backgroundColor: Color(0xFFDCF8F1),
          child: Text(
            initials.isEmpty ? 'C' : initials,
            style: const TextStyle(
              color: _darkTeal,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // NEXT CHECK-IN - REAL DATA
  // ==========================================

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

    final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(item.at));

    final date = localizations.formatMediumDate(item.at);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 26,
            height: 1.08,
            color: _darkTeal,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              item.mode.toLowerCase() == 'voice'
                  ? Icons.call_outlined
                  : Icons.videocam_outlined,
              size: 16,
              color: _primaryTeal,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${item.duration} min · '
                '${item.mode} check-in',
                style: const TextStyle(color: _mutedText, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '$date · ${item.companionName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _mutedText, fontSize: 11),
        ),
      ],
    );
  }

  // ==========================================
  // BRIGHT MINT QUICK ACTIONS
  // ==========================================

  Widget _quickActions(BuildContext context) {
    Widget actionItem(
      IconData icon,
      String label,
      VoidCallback onTap,
      Color background,
    ) {
      return Expanded(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: _darkTeal, size: 29),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _darkTeal,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          actionItem(
            Icons.schedule_rounded,
            'Schedule',
            () => _openSchedule(context),
            _mint,
          ),
          const SizedBox(width: 8),
          actionItem(
            Icons.menu_book_rounded,
            'Memory Lane',
            () => _open(context, const MemoryLaneScreen()),
            _mint,
          ),
          const SizedBox(width: 8),
          actionItem(Icons.help_outline_rounded, 'Need Help', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help options will open here.')),
            );
          }, _mintStrong),
        ],
      ),
    );
  }

  // ==========================================
  // DARK GREEN FIGMA REMINDER
  // ==========================================

  Widget _reminder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: _reminderGreen,
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFF87373),
            child: Icon(
              Icons.favorite_border_rounded,
              color: _darkTeal,
              size: 27,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A gentle reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Take your time. You can end or '
                  'reschedule anytime.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
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
