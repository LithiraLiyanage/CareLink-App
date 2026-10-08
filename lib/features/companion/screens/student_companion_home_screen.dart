import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../elder/models/check_in.dart';
import '../../elder/screens/kamala_ready_screen.dart';
import '../../elder/screens/active_video_call_screen.dart';
import '../../elder/screens/my_schedule_screen.dart';
import '../../elder/screens/student_checkin_complete_screen.dart';
import '../../elder/services/firebase_elder_service.dart';
import '../../elder/widgets/elder_colors.dart';
import '../controllers/companion_controller.dart';
import '../controllers/companion_controller_factory.dart';
import '../models/companion_connection.dart';
import '../models/companion_incoming_request.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/match_request.dart';
import 'conversation_ideas_screen.dart';

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
  late final CompanionController _controller;
  late final bool _ownsController;
  late final Future<_StudentProfileData> _profile;
  Stream<ElderScheduleData>? _scheduleStream;
  String? _scheduleConnectionId;
  final GlobalKey _todaySectionKey = GlobalKey();

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
    final verificationStatus =
        userData['verificationStatus'] as String? ??
        profileData['verificationStatus'] as String? ??
        'unknown';
    return _StudentProfileData(
      fullName:
          (userData['fullName'] as String?) ??
          (profileData['fullName'] as String?) ??
          '',
      verificationStatus: verificationStatus,
      bio: profileData['bio'] as String? ?? '',
      languages: _stringList(profileData['languages']),
      interests: _stringList(profileData['interests']),
      profileImageUrl: profileData['profileImageUrl'] as String?,
    );
  }

  List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList(growable: false) : [];

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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ??
                (status == MatchRequestStatus.accepted
                    ? 'Request accepted. Your connection is active.'
                    : 'Request declined.'),
          ),
        ),
      );
  }

  void _openRequests() => Navigator.of(context)
      .pushNamed(AppRoutes.companionIncomingRequests, arguments: _controller);

  void _openSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/student-my-schedule'),
        builder: (_) => const MyScheduleScreen(navigationOnly: true),
      ),
    );
  }

  Future<void> _openConversationIdeas() async {
    final connection = _controller.studentConnection;
    final request = _controller.studentConnectionRequest;
    if (connection == null ||
        connection.status != ConnectionStatus.active ||
        request == null) {
      _showUnavailable(
        'Conversation ideas are available for an active connection.',
      );
      return;
    }
    try {
      final student = await _profile;
      if (!mounted) return;
      final profile = CompanionProfile(
        id: _auth.currentUser?.uid ?? '',
        userId: _auth.currentUser?.uid,
        name: student.fullName,
        imagePath: '',
        profileImageUrl: student.profileImageUrl,
        verified: student.verificationStatus == 'verified',
        languages: student.languages,
        interests: student.interests,
        availability: '',
        about: student.bio,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConversationIdeasScreen(
            profile: profile,
            selectedLanguage: CompanionLanguage.english,
            controller: _controller,
            interests: request.sharedInterests,
            studentPerspective: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showUnavailable('Could not load conversation ideas: $error');
    }
  }

  Stream<ElderScheduleData> _scheduleFor(CompanionConnection connection) {
    if (_scheduleConnectionId != connection.id || _scheduleStream == null) {
      _scheduleConnectionId = connection.id;
      _scheduleStream = _watchSchedule(connection);
    }
    return _scheduleStream!;
  }

  Stream<ElderScheduleData> _watchSchedule(
    CompanionConnection connection,
  ) async* {
    yield* FirebaseElderService.instance.watchScheduleForConnection(
      elderId: connection.elderId,
      companionId: connection.companionId,
      connectionId: connection.id,
    );
  }

  void _openReadyScreen(CheckIn checkIn, CompanionConnection connection) {
    void openCall(String callType) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ActiveVideoCallScreen(
            elderId: checkIn.elderId,
            elderName: checkIn.elderName,
            elderImageUrl: checkIn.elderImageUrl,
            companionId: checkIn.companionId,
            connectionId: connection.id,
            checkInId: checkIn.id,
            scheduledAt: checkIn.scheduledAt,
            durationMinutes: checkIn.durationMinutes,
            callType: callType,
            onEndCall: () async {
              await FirebaseElderService.instance.updateCheckInStatus(
                checkIn.id,
                CheckInStatus.completed,
              );
              if (!mounted) return;
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => StudentCheckInCompleteScreen(
                    elderId: checkIn.elderId,
                    elderName: checkIn.elderName,
                    elderImageUrl: checkIn.elderImageUrl,
                    companionId: checkIn.companionId,
                    connectionId: connection.id,
                    checkInId: checkIn.id,
                    scheduledAt: checkIn.scheduledAt,
                    durationMinutes: checkIn.durationMinutes,
                    callType: callType,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KamalaReadyScreen(
          elderId: checkIn.elderId,
          elderName: checkIn.elderName,
          elderImageUrl: checkIn.elderImageUrl,
          scheduledAt: checkIn.scheduledAt,
          durationMinutes: checkIn.durationMinutes,
          mode: checkIn.mode,
          companionId: checkIn.companionId,
          connectionId: connection.id,
          checkInId: checkIn.id,
          onStartCall: () => openCall('Video'),
          onVoiceCall: () => openCall('Voice'),
          onMessageInstead: () =>
              _showUnavailable('Messaging is not available in CareLink yet.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElderColors.background,
      bottomNavigationBar: _bottomNavigation(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FutureBuilder<_StudentProfileData>(
              future: _profile,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return _header(
                  profile?.fullName ?? '',
                  profile?.verificationStatus,
                  profile?.profileImageUrl,
                );
              },
            ),
            Expanded(
              child: FutureBuilder<_StudentProfileData>(
                future: _profile,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _messageState(
                      'Could not load your companion profile: '
                      '${snapshot.error}',
                      icon: Icons.error_outline_rounded,
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ElderColors.darkTeal,
                      ),
                    );
                  }
                  return _homeContent(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    String fullName,
    String? verificationStatus,
    String? profileImageUrl,
  ) {
    final displayName = fullName.trim().isEmpty
        ? 'Student Companion'
        : fullName;
    final firstName = displayName.split(RegExp(r'\s+')).first;
    final statusLabel = switch (verificationStatus) {
      'verified' => 'Verified Student Companion',
      'pending' => 'Verification under review',
      'rejected' => 'Verification not approved',
      _ => 'Verification status unavailable',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      decoration: const BoxDecoration(
        color: ElderColors.darkTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
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
              SizedBox(width: 7),
              Text(
                'CareLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
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
                    const SizedBox(height: 7),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Color(0xFFD7EBE8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _profileAvatar(displayName, profileImageUrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar(String name, String? imageUrl) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    return CircleAvatar(
      radius: 32,
      backgroundColor: ElderColors.mint,
      backgroundImage: imageUrl == null || imageUrl.isEmpty
          ? null
          : NetworkImage(imageUrl),
      onBackgroundImageError: imageUrl == null || imageUrl.isEmpty
          ? null
          : (_, _) {},
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(
              initial,
              style: const TextStyle(
                color: ElderColors.darkTeal,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );
  }

  Widget _homeContent(_StudentProfileData profile) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _connectionCard(),
        const SizedBox(height: 17),
        _sectionTitle('Incoming Companion Requests'),
        const SizedBox(height: 9),
        _incomingRequestsCard(),
        const SizedBox(height: 17),
        _sectionTitle('Quick actions'),
        const SizedBox(height: 9),
        _quickActions(),
        const SizedBox(height: 17),
        _sectionTitle('Your companion profile'),
        const SizedBox(height: 9),
        _profileCard(profile),
        const SizedBox(height: 17),
        KeyedSubtree(
          key: _todaySectionKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Today'),
              const SizedBox(height: 9),
              _todayCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomNavigation() {
    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ElderColors.darkTeal,
          unselectedItemColor: ElderColors.textMuted,
          backgroundColor: Colors.white,
          onTap: (index) {
            switch (index) {
              case 1:
                _openRequests();
              case 2:
                _openSchedule();
              case 3:
                _showProfile();
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _requestCountIcon(),
              label: 'Requests',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Schedule',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCountIcon() {
    final count = _controller.incomingRequests.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.inbox_outlined),
        if (count > 0)
          Positioned(
            right: -10,
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: ElderColors.coral,
                borderRadius: BorderRadius.all(Radius.circular(10)),
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

  Widget _connectionCard() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoadingStudentConnection &&
            _controller.studentConnection == null) {
          return _sectionCard(
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ElderColors.darkTeal,
                  ),
                ),
                SizedBox(width: 12),
                Text('Checking your connection...'),
              ],
            ),
          );
        }
        if (_controller.studentConnectionError != null) {
          return _sectionCard(
            child: Text(
              'Could not load your connection: '
              '${_controller.studentConnectionError}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        final connection = _controller.studentConnection;
        if (connection == null) {
          return _sectionCard(
            child: const Row(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  color: ElderColors.darkTeal,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No active connection yet. Accepted connections will '
                    'appear here.',
                    style: TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final request = _controller.studentConnectionRequest;
        final elderName = request?.elderDisplayName.trim().isNotEmpty == true
            ? request!.elderDisplayName
            : 'Older Adult';
        return _sectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: ElderColors.mintSoft,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: ElderColors.darkTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          elderName,
                          style: const TextStyle(
                            color: ElderColors.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          connection.status == ConnectionStatus.paused
                              ? 'Connection paused'
                              : 'Connection active',
                          style: const TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (request?.sharedInterests.isNotEmpty == true) ...[
                const SizedBox(height: 9),
                _requestDetail(
                  'Shared interests',
                  request!.sharedInterests.join(', '),
                ),
              ],
              if (request?.preferredLanguage.isNotEmpty == true)
                _requestDetail(
                  'Preferred language',
                  request!.preferredLanguage,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _incomingRequestsCard() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoadingIncomingRequests &&
            _controller.incomingRequests.isEmpty) {
          return _sectionCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: ElderColors.darkTeal),
              ),
            ),
          );
        }
        if (_controller.incomingRequestsError != null) {
          return _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load incoming requests: '
                  '${_controller.incomingRequestsError}',
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton(
                  onPressed: _openRequests,
                  child: const Text('Open Incoming Requests'),
                ),
              ],
            ),
          );
        }
        final requests = _controller.incomingRequests;
        if (requests.isEmpty) {
          return _sectionCard(
            child: const Row(
              children: [
                Icon(Icons.inbox_outlined, color: ElderColors.textMuted),
                SizedBox(width: 10),
                Text(
                  'No new companion requests.',
                  style: TextStyle(color: ElderColors.textDark),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _requestCard(requests.first),
            if (requests.length > 1)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _openRequests,
                  child: Text('View all requests (${requests.length})'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _requestCard(CompanionIncomingRequest incoming) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                color: ElderColors.darkTeal,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Incoming Companion Request',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            incoming.elderDisplayName.isEmpty
                ? 'Older Adult'
                : incoming.elderDisplayName,
            style: const TextStyle(
              color: ElderColors.darkTeal,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (incoming.preferredLanguage.isNotEmpty)
            _requestDetail('Preferred language', incoming.preferredLanguage),
          if (incoming.sharedInterests.isNotEmpty)
            _requestDetail(
              'Shared interests',
              incoming.sharedInterests.join(', '),
            ),
          if (incoming.compatibleAvailability.isNotEmpty)
            _requestDetail('Availability', incoming.compatibleAvailability),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _controller.isLoading
                      ? null
                      : () => _respond(incoming, MatchRequestStatus.declined),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _controller.isLoading
                      ? null
                      : () => _respond(incoming, MatchRequestStatus.accepted),
                  style: FilledButton.styleFrom(
                    backgroundColor: ElderColors.darkTeal,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requestDetail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      '$label: $value',
      style: const TextStyle(color: ElderColors.textMuted, fontSize: 12),
    ),
  );

  Widget _quickActions() {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _actionTile(
            Icons.inbox_outlined,
            'Incoming\nRequests',
            _openRequests,
          ),
          _actionTile(Icons.calendar_month_outlined, 'Schedule', _openSchedule),
          _actionTile(
            Icons.chat_bubble_outline_rounded,
            'Conversation\nIdeas',
            _openConversationIdeas,
          ),
          _actionTile(
            Icons.person_outline_rounded,
            'Profile',
            () => _showProfile(),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: 92,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            decoration: BoxDecoration(
              color: ElderColors.mintSoft,
              border: Border.all(color: ElderColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: ElderColors.textDark, size: 23),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard(_StudentProfileData profile) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.fullName.trim().isEmpty
                ? 'Student Companion'
                : profile.fullName,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Verification: ${profile.verificationStatus}',
            style: const TextStyle(color: ElderColors.textMuted, fontSize: 12),
          ),
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              profile.bio,
              style: const TextStyle(
                color: ElderColors.textDark,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (profile.languages.isNotEmpty)
            _requestDetail('Languages', profile.languages.join(', ')),
          if (profile.interests.isNotEmpty)
            _requestDetail('Interests', profile.interests.join(', ')),
        ],
      ),
    );
  }

  Future<void> _showProfile() async {
    final profile = await _profile;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _profileCard(profile),
        ),
      ),
    );
  }

  Widget _todayCard() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final connection = _controller.studentConnection;
        if (connection == null) {
          return _sectionCard(
            child: const Text(
              'No check-ins are scheduled yet.',
              style: TextStyle(color: ElderColors.textDark, fontSize: 12),
            ),
          );
        }
        if (connection.status != ConnectionStatus.active) {
          return _sectionCard(
            child: const Text(
              'Your companion connection is paused.',
              style: TextStyle(color: ElderColors.textDark, fontSize: 12),
            ),
          );
        }
        return _sectionCard(
          child: StreamBuilder<ElderScheduleData>(
            stream: _scheduleFor(connection),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Could not load shared check-ins: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: ElderColors.darkTeal),
                );
              }
              final now = DateTime.now();
              final checkIns =
                  snapshot.data!.checkIns
                      .where(
                        (item) =>
                            item.status == CheckInStatus.scheduled ||
                            item.status == CheckInStatus.ready ||
                            item.status == CheckInStatus.inProgress,
                      )
                      .where(
                        (item) =>
                            item.status == CheckInStatus.ready ||
                            !item.scheduledAt.isBefore(now),
                      )
                      .toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
              if (checkIns.isNotEmpty) {
                final checkIn = checkIns.first;
                final localizations = MaterialLocalizations.of(context);
                final date = localizations.formatMediumDate(
                  checkIn.scheduledAt,
                );
                final time = localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(checkIn.scheduledAt),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next check-in with ${checkIn.elderName}',
                      style: const TextStyle(
                        color: ElderColors.textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$date · $time · ${checkIn.durationMinutes} min · ${checkIn.mode}',
                      style: const TextStyle(
                        color: ElderColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 9),
                    if (checkIn.status == CheckInStatus.scheduled ||
                        checkIn.status == CheckInStatus.ready)
                      FilledButton(
                        onPressed: () => _openReadyScreen(checkIn, connection),
                        child: const Text('View Check-in'),
                      ),
                  ],
                );
              }
              final recurring =
                  snapshot.data!.recurringSchedules
                      .map(
                        (schedule) => (
                          schedule: schedule,
                          next: schedule.nextOccurrence(now),
                        ),
                      )
                      .where((item) => item.next != null)
                      .toList()
                    ..sort((a, b) => a.next!.compareTo(b.next!));
              if (recurring.isEmpty) {
                return const Text(
                  'No upcoming check-ins are scheduled yet.',
                  style: TextStyle(color: ElderColors.textDark, fontSize: 12),
                );
              }
              final next = recurring.first;
              final date = MaterialLocalizations.of(context)
                  .formatMediumDate(next.next!);
              final time = MaterialLocalizations.of(context)
                  .formatTimeOfDay(TimeOfDay.fromDateTime(next.next!));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next check-in with ${next.schedule.elderName}',
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$date · $time · ${next.schedule.durationMinutes} min · ${next.schedule.mode}',
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Recurring check-in',
                    style: TextStyle(
                      color: ElderColors.darkTeal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      title,
      style: const TextStyle(
        color: ElderColors.textDark,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _sectionCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _messageState(String message, {required IconData icon}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ElderColors.darkTeal, size: 34),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
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
