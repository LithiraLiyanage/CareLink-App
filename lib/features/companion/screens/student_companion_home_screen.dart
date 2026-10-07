import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../elder/widgets/elder_colors.dart';
import '../controllers/companion_controller.dart';
import '../controllers/companion_controller_factory.dart';
import '../models/companion_connection.dart';
import '../models/companion_incoming_request.dart';
import '../models/match_request.dart';

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

  void _openRequests() =>
      Navigator.of(context).pushNamed(AppRoutes.companionIncomingRequests);

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
        _sectionTitle('Today'),
        const SizedBox(height: 9),
        _todayCard(),
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
                _showUnavailable('Check-in scheduling is not available yet.');
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
        return _sectionCard(
          child: Row(
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
                    const Text(
                      'Your companion connection',
                      style: TextStyle(
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
              const Icon(Icons.chevron_right, color: ElderColors.darkTeal),
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
          _actionTile(
            Icons.calendar_month_outlined,
            'Schedule',
            () => _showUnavailable('Check-in scheduling is not available yet.'),
          ),
          _actionTile(
            Icons.chat_bubble_outline_rounded,
            'Conversation\nIdeas',
            () => _showUnavailable(
              'Conversation ideas are not available here yet.',
            ),
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
        final message = connection == null
            ? 'No check-ins are scheduled yet.'
            : connection.status == ConnectionStatus.paused
            ? 'Your companion connection is paused.'
            : 'Your companion connection is active. Scheduled check-ins will '
                  'appear here.';
        return _sectionCard(
          child: Row(
            children: [
              const Icon(Icons.today_outlined, color: ElderColors.darkTeal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
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
