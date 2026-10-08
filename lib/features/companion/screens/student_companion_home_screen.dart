import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../elder/models/check_in.dart';
import '../../elder/services/firebase_elder_service.dart';
import '../../elder/widgets/elder_colors.dart';
import '../controllers/companion_controller.dart';
import '../controllers/companion_controller_factory.dart';
import '../models/companion_connection.dart';
import '../models/companion_incoming_request.dart';
import '../models/match_request.dart';
import '../widgets/companion_profile_avatar.dart';
import 'my_connection_screen.dart';

/// Student Companion's home dashboard. Real profile, requests and connections
/// come from the existing team controller; check-ins come from ElderService.
class StudentCompanionHomeScreen extends StatefulWidget {
  const StudentCompanionHomeScreen({
    super.key,
    this.controller,
    this.auth,
    this.firestore,
  });

  final CompanionController? controller;
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;

  @override
  State<StudentCompanionHomeScreen> createState() =>
      _StudentCompanionHomeScreenState();
}

class _StudentCompanionHomeScreenState
    extends State<StudentCompanionHomeScreen> {
  static const Color _teal = ElderColors.darkTeal;
  static const Color _coral = ElderColors.coral;
  static const Color _ink = ElderColors.textDark;
  static const Color _muted = ElderColors.textMuted;
  static const Color _canvas = Color(0xFFF6FAF9);
  static const Color _line = Color(0xFFE2EEEB);
  static const Color _rose = Color(0xFFFFF1EF);

  late final CompanionController _controller;
  late final bool _ownsController;
  late final Future<_StudentProfileData> _profile;
  late Future<_DashboardData?> _dashboard;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? createCompanionController();
    _controller.watchIncomingRequests();
    _controller.watchCompanionConnection();
    _profile = _loadProfile();
    _dashboard = _loadDashboard();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<_StudentProfileData> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to view your companion home.');
    }
    final userSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!userSnapshot.exists) {
      throw StateError('Your CareLink user profile could not be found.');
    }
    final userData = userSnapshot.data()!;
    if (userData['role'] != 'Student Companion') {
      throw StateError('This home is only available to Student Companions.');
    }
    final profileSnapshot = await _firestore
        .collection('companion_profiles')
        .doc(user.uid)
        .get();
    final profileData = profileSnapshot.data() ?? const <String, dynamic>{};
    return _StudentProfileData(
      fullName:
          (userData['fullName'] as String?) ??
          (profileData['fullName'] as String?) ??
          '',
      verificationStatus:
          (userData['verificationStatus'] as String?) ??
          (profileData['verificationStatus'] as String?) ??
          'unknown',
      bio: profileData['bio'] as String? ?? '',
      languages: _stringList(profileData['languages']),
      interests: _stringList(profileData['interests']),
      profileImageUrl:
          (profileData['profileImageUrl'] as String?) ??
          (userData['profileImageUrl'] as String?),
    );
  }

  List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : <String>[];

  /// A read-only overview. A failure here should never block the main home.
  Future<_DashboardData?> _loadDashboard() async {
    try {
      final service = FirebaseElderService.instance;
      final flow = await service.getCurrentFlowContext();
      final sessions = await service.getCheckIns();
      final now = DateTime.now();
      final future = sessions
          .where(
            (c) =>
                !c.scheduledAt.isBefore(now) &&
                c.status != CheckInStatus.completed &&
                c.status != CheckInStatus.cancelled &&
                c.status != CheckInStatus.missed,
          )
          .toList();
      future.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return _DashboardData(
        elderName: flow.elderName,
        nextSession: future.isEmpty ? null : future.first,
      );
    } catch (_) {
      return null;
    }
  }

  void _refreshDashboard() {
    if (mounted) setState(() => _dashboard = _loadDashboard());
  }

  Future<void> _openConnection() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const MyConnectionScreen()));
    _refreshDashboard();
  }

  void _openRequests() =>
      Navigator.of(context).pushNamed(AppRoutes.companionIncomingRequests);

  Future<void> _respond(
    CompanionIncomingRequest incoming,
    MatchRequestStatus status,
  ) async {
    await _controller.respondToIncomingRequest(
      incoming: incoming,
      status: status,
    );
    if (!mounted) return;
    final error = _controller.errorMessage;
    if (error != null) {
      _toast(error);
      return;
    }
    if (status == MatchRequestStatus.accepted) {
      await _openConnection();
    } else {
      _toast('Request declined.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      bottomNavigationBar: _bottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_StudentProfileData>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _errorState(
                'Could not load your companion profile.\n'
                '${snapshot.error}',
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _teal),
              );
            }
            final profile = snapshot.data!;
            return Column(
              children: [
                _hero(profile),
                Expanded(
                  child: RefreshIndicator(
                    color: _teal,
                    onRefresh: () async {
                      _refreshDashboard();
                      await _dashboard;
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      children: [
                        _sectionHeading(
                          'YOUR CONNECTION',
                          'View details',
                          onTap: _openConnection,
                        ),
                        const SizedBox(height: 10),
                        _connectionCard(),
                        const SizedBox(height: 22),
                        _sectionHeading(
                          'NEXT CHECK-IN',
                          'Open schedule',
                          onTap: _openConnection,
                        ),
                        const SizedBox(height: 10),
                        _nextCheckInCard(),
                        const SizedBox(height: 22),
                        _sectionHeading('QUICK ACTIONS', null),
                        const SizedBox(height: 11),
                        _quickActions(),
                        const SizedBox(height: 22),
                        _sectionHeading(
                          'COMPANION REQUESTS',
                          'View all',
                          onTap: _openRequests,
                        ),
                        const SizedBox(height: 10),
                        _incomingRequestsCard(),
                        const SizedBox(height: 22),
                        _sectionHeading(
                          'YOUR PROFILE',
                          'View profile',
                          onTap: _showProfile,
                        ),
                        const SizedBox(height: 10),
                        _profilePreview(profile),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(_StudentProfileData profile) {
    final displayName = profile.fullName.trim().isEmpty
        ? 'Student Companion'
        : profile.fullName.trim();
    final firstName = displayName.split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _teal,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF075955), Color(0xFF074743)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -54,
              child: _decorCircle(155, const Color(0x12FFFFFF)),
            ),
            Positioned(
              right: 64,
              bottom: -82,
              child: _decorCircle(138, const Color(0x0CFFFFFF)),
            ),
            Positioned(
              left: -55,
              bottom: -85,
              child: _decorCircle(118, const Color(0x17FF696C)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 12, 19, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 31,
                        height: 31,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: _teal,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CareLink',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -.4,
                        ),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: _coral,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _heroIconButton(
                              Icons.notifications_none_rounded,
                              onTap: _openRequests,
                              tooltip: 'Companion requests',
                            ),
                            if (_controller.incomingRequests.isNotEmpty)
                              Positioned(
                                right: 5,
                                top: 4,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: _coral,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFFDBF1EC),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.7,
                              ),
                            ),
                            const SizedBox(height: 9),
                            _verifiedPill(profile.verificationStatus),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x38000000),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CompanionProfileAvatar(
                          name: displayName,
                          imageUrl: profile.profileImageUrl,
                          size: 66,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 14, color: _coral),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Every connection makes a difference.',
                          style: TextStyle(
                            color: Color(0xFFD8EEE9),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verifiedPill(String status) {
    final verified = status == 'verified';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: verified ? const Color(0xFF9CF4D7) : Colors.white,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            verified ? 'Verified Student Companion' : 'Status: $status',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(
    IconData icon, {
    required VoidCallback onTap,
    required String tooltip,
  }) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );

  Widget _decorCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _sectionHeading(String text, String? action, {VoidCallback? onTap}) =>
      Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              letterSpacing: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (action != null)
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      action,
                      style: const TextStyle(
                        color: _teal,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _teal,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );

  Widget _card({
    required Widget child,
    Color color = Colors.white,
    EdgeInsetsGeometry? padding,
    Color border = _line,
  }) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B153B38),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );

  Widget _connectionCard() => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final connection = _controller.studentConnection;
      final loading =
          _controller.isLoadingStudentConnection && connection == null;
      final error = _controller.studentConnectionError;
      return InkWell(
        onTap: _openConnection,
        borderRadius: BorderRadius.circular(19),
        child: _card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: _rose,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: _coral,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Connection',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (loading)
                      const Text(
                        'Checking your connection...',
                        style: TextStyle(color: _muted, fontSize: 11.5),
                      )
                    else if (error != null)
                      const Text(
                        'Unable to load connection. Tap to retry.',
                        style: TextStyle(color: _muted, fontSize: 11.5),
                      )
                    else
                      Text(
                        connection == null
                            ? 'No active connection yet'
                            : connection.status == ConnectionStatus.paused
                            ? 'Connection paused'
                            : 'Connection active',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connection == null
                                ? _muted
                                : connection.status == ConnectionStatus.paused
                                ? _coral
                                : const Color(0xFF22A580),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            connection == null
                                ? 'Find your match'
                                : connection.status == ConnectionStatus.paused
                                ? 'Manage connection'
                                : 'View check-in details',
                            style: const TextStyle(
                              color: _teal,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _teal,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _nextCheckInCard() => FutureBuilder<_DashboardData?>(
    future: _dashboard,
    builder: (context, snapshot) {
      final session = snapshot.data?.nextSession;
      final elderName = snapshot.data?.elderName.trim() ?? '';
      return InkWell(
        onTap: _openConnection,
        borderRadius: BorderRadius.circular(19),
        child: _card(
          color: const Color(0xFFE9F7F2),
          border: const Color(0xFFD3ECE3),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session == null
                          ? 'Plan your next check-in'
                          : _formatDate(session.scheduledAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      session == null
                          ? (snapshot.connectionState == ConnectionState.waiting
                                ? 'Loading your sessions...'
                                : snapshot.data == null
                                ? 'Open schedule to view your sessions'
                                : 'No upcoming sessions scheduled')
                          : '${elderName.isEmpty ? 'Older Adult' : elderName} · ${session.mode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _teal, size: 22),
            ],
          ),
        ),
      );
    },
  );

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final meridian = date.hour >= 12 ? 'PM' : 'AM';
    return '${days[date.weekday - 1]}, $hour:$minute $meridian';
  }

  Widget _quickActions() => Row(
    children: [
      Expanded(
        child: _quickAction(
          Icons.calendar_today_rounded,
          'Schedule',
          _openConnection,
          const Color(0xFFE9F7F2),
          _teal,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _quickAction(
          Icons.mark_email_unread_outlined,
          'Requests',
          _openRequests,
          _rose,
          _coral,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _quickAction(
          Icons.person_outline_rounded,
          'My Profile',
          _showProfile,
          const Color(0xFFF0F1FB),
          const Color(0xFF6560AA),
        ),
      ),
    ],
  );

  Widget _quickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color bg,
    Color foreground,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(17),
    child: Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: foreground, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: _ink,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _incomingRequestsCard() => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      if (_controller.isLoadingIncomingRequests &&
          _controller.incomingRequests.isEmpty) {
        return _card(
          child: const Center(child: CircularProgressIndicator(color: _teal)),
        );
      }
      if (_controller.incomingRequestsError != null) {
        return _card(
          child: Text(
            'Could not load your requests: '
            '${_controller.incomingRequestsError}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        );
      }
      final requests = _controller.incomingRequests;
      if (requests.isEmpty) {
        return _card(
          child: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: _teal, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'re all caught up. No new requests.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF35A68D),
                size: 18,
              ),
            ],
          ),
        );
      }
      return Column(
        children: [
          _requestCard(requests.first),
          if (requests.length > 1)
            TextButton(
              onPressed: _openRequests,
              child: Text('View all ${requests.length} requests'),
            ),
        ],
      );
    },
  );

  Widget _requestCard(CompanionIncomingRequest incoming) => _card(
    padding: const EdgeInsets.all(16),
    border: const Color(0xFFFFDED8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border_rounded, color: _coral, size: 21),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'New companion request',
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.circle, color: _coral, size: 8),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          incoming.elderDisplayName.isEmpty
              ? 'Older Adult'
              : incoming.elderDisplayName,
          style: const TextStyle(
            color: _teal,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (incoming.preferredLanguage.isNotEmpty)
          _requestDetail('Language', incoming.preferredLanguage),
        if (incoming.sharedInterests.isNotEmpty)
          _requestDetail(
            'Shared interests',
            incoming.sharedInterests.join(', '),
          ),
        if (incoming.compatibleAvailability.isNotEmpty)
          _requestDetail('Available', incoming.compatibleAvailability),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _controller.isLoading
                    ? null
                    : () => _respond(incoming, MatchRequestStatus.declined),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _coral,
                  side: const BorderSide(color: Color(0xFFF5B4AD)),
                ),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _controller.isLoading
                    ? null
                    : () => _respond(incoming, MatchRequestStatus.accepted),
                style: FilledButton.styleFrom(backgroundColor: _teal),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _requestDetail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      '$label: $value',
      style: const TextStyle(color: _muted, fontSize: 11.5),
    ),
  );

  Widget _profilePreview(_StudentProfileData profile) => InkWell(
    onTap: _showProfile,
    borderRadius: BorderRadius.circular(19),
    child: _card(
      child: Row(
        children: [
          CompanionProfileAvatar(
            name: profile.fullName,
            imageUrl: profile.profileImageUrl,
            size: 49,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.isEmpty
                      ? 'Student Companion'
                      : profile.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.verificationStatus == 'verified'
                      ? 'Verified student · CareLink member'
                      : 'Verification: ${profile.verificationStatus}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: _coral, size: 14),
        ],
      ),
    ),
  );

  Future<void> _showProfile() async {
    try {
      final profile = await _profile;
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _canvas,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CompanionProfileAvatar(
                      name: profile.fullName,
                      imageUrl: profile.profileImageUrl,
                      size: 64,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Verification: ${profile.verificationStatus}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    profile.bio,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                if (profile.languages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Languages: ${profile.languages.join(', ')}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
                if (profile.interests.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    'Interests: ${profile.interests.join(', ')}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) _toast('Could not open profile: $e');
    }
  }

  Widget _bottomNavigation() => SafeArea(
    top: false,
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: _teal,
          unselectedItemColor: _muted,
          backgroundColor: Colors.white,
          selectedFontSize: 10.5,
          unselectedFontSize: 10,
          onTap: (index) {
            switch (index) {
              case 1:
                _openRequests();
              case 2:
                _openConnection();
              case 3:
                _showProfile();
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _requestCountIcon(),
              label: 'Requests',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Schedule',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );

  Widget _requestCountIcon() {
    final count = _controller.incomingRequests.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.mail_outline_rounded),
        if (count > 0)
          Positioned(
            right: -10,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _coral,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _coral, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _StudentProfileData {
  const _StudentProfileData({
    required this.fullName,
    required this.verificationStatus,
    required this.bio,
    required this.languages,
    required this.interests,
    required this.profileImageUrl,
  });
  final String fullName;
  final String verificationStatus;
  final String bio;
  final List<String> languages;
  final List<String> interests;
  final String? profileImageUrl;
}

class _DashboardData {
  const _DashboardData({required this.elderName, required this.nextSession});
  final String elderName;
  final CheckIn? nextSession;
}
