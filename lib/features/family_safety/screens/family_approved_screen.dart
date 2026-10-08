import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../services/family_link_service.dart';
import 'family_notifications_screen.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${date.day} ${_months[date.month - 1]} ${date.year}, '
      '$hour:$minute $period';
}

/// Success state shown after an older adult approves a family request.
///
/// Takes the approved request's id as the route argument; without one it
/// shows the family member's most recent approval.
class FamilyApprovedScreen extends StatefulWidget {
  const FamilyApprovedScreen({super.key});

  static const _ink = Color(0xFF00695C);
  static const _titleInk = Color(0xFF004D40);
  static const _muted = Color(0xFF55706E);
  static const _mint = Color(0xFFF2F9F7);
  static const _line = Color(0xFFD5E5E2);
  static const _coral = Color(0xFFF26F6A);
  static const _success = Color(0xFF00A878);

  @override
  State<FamilyApprovedScreen> createState() => _FamilyApprovedScreenState();
}

class _FamilyApprovedScreenState extends State<FamilyApprovedScreen> {
  static const _ink = FamilyApprovedScreen._ink;
  static const _titleInk = FamilyApprovedScreen._titleInk;
  static const _muted = FamilyApprovedScreen._muted;
  static const _mint = FamilyApprovedScreen._mint;
  static const _coral = FamilyApprovedScreen._coral;

  late final Stream<List<FamilyLinkRequest>> _approvals =
      FamilyLinkService.instance.watchApprovals();

  FamilyLinkRequest? _selectedApproval(List<FamilyLinkRequest> approvals) {
    if (approvals.isEmpty) return null;
    final requestId = ModalRoute.of(context)?.settings.arguments;
    if (requestId is String) {
      for (final approval in approvals) {
        if (approval.id == requestId) return approval;
      }
    }
    return approvals.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Back to notifications',
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const FamilyNotificationsScreen(),
            ),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _ink, size: 21),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE0F2EF),
              child: Icon(Icons.person_rounded, color: _ink, size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172, color: Color(0xFFDFF1ED)),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38, color: Color(0xFFDFF1ED)),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _SuccessMark()),
                      const SizedBox(height: 12),
                      const Text(
                        'Connection Approved!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'You can now view the information\napproved by the older adult.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 19),
                      StreamBuilder<List<FamilyLinkRequest>>(
                        stream: _approvals,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(
                              'Could not load the approval: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: _coral),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(color: _ink),
                              ),
                            );
                          }
                          final approval = _selectedApproval(snapshot.data!);
                          if (approval == null) {
                            return const Text(
                              'No approved connections yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _muted, fontSize: 13),
                            );
                          }
                          return _CaregiverCard(approval: approval);
                        },
                      ),
                      const SizedBox(height: 13),
                      const _ApprovedInformationCard(),
                      const SizedBox(height: 20),
                      Semantics(
                        button: true,
                        label: 'Go to Dashboard',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.familyDashboard),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _coral,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20E85D5A),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Go to Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFDFF5ED),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: FamilyApprovedScreen._success,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 33),
        ),
      ),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  const _CaregiverCard({required this.approval});

  final FamilyLinkRequest approval;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;
    final elderName =
        approval.elderName.isEmpty ? 'the older adult' : approval.elderName;
    // respondedAt is null until the server timestamp lands.
    final approvedAt = approval.respondedAt?.toLocal() ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamilyApprovedScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00695C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE0F2EF),
            child: Icon(Icons.person_rounded,
                size: 31, color: FamilyApprovedScreen._ink),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.requesterName,
                  style: const TextStyle(
                    color: FamilyApprovedScreen._titleInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  approval.relationship.isEmpty
                      ? 'Family caregiver'
                      : '${approval.relationship} of $elderName',
                  style: const TextStyle(
                    color: FamilyApprovedScreen._muted,
                    fontSize: 12,
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: FamilyApprovedScreen._muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Approved on ${_formatDateTime(approvedAt)}',
                  style:
                      const TextStyle(color: Color(0xFF829390), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedInformationCard extends StatelessWidget {
  const _ApprovedInformationCard();

  static const _rows = <(IconData, String)>[
    (Icons.calendar_today_rounded, 'Check-in status'),
    (Icons.access_time_rounded, 'Schedule information'),
    (Icons.favorite_border_rounded, 'General wellbeing status'),
    (Icons.shield_outlined, 'Consent preferences'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FamilyApprovedScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00695C),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _rows.length; i++) ...[
            SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Icon(_rows[i].$1,
                        color: FamilyApprovedScreen._ink, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _rows[i].$2,
                        style: const TextStyle(
                          color: FamilyApprovedScreen._titleInk,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.check_rounded,
                        color: FamilyApprovedScreen._success, size: 22),
                  ],
                ),
              ),
            ),
            if (i < _rows.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 47),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFEAF1EF)),
              ),
          ],
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
