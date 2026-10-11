// ignore_for_file: prefer_initializing_formals
// Keep the public `profile:` parameter while storing a private fallback.
import 'package:flutter/material.dart';

import '../../elder/models/check_in.dart';
import '../../elder/services/firebase_elder_service.dart';
import '../controllers/companion_controller.dart';
import '../models/companion_connection.dart';
import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_interest_icon.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'manage_connection_screen.dart';
import 'scheduling_handoff_screen.dart';

class CurrentConnectionScreen extends StatelessWidget {
  const CurrentConnectionScreen({
    super.key,
    required CompanionProfile profile,
    required this.selectedLanguage,
    this.connectionStatus = MatchStatus.accepted,
    this.controller,
  }) : _profile = profile,
       assert(
         connectionStatus == MatchStatus.accepted ||
             connectionStatus == MatchStatus.paused,
       );
  final CompanionProfile _profile;
  final CompanionLanguage selectedLanguage;
  final MatchStatus connectionStatus;
  final CompanionController? controller;
  CompanionProfile get profile => controller?.selectedCompanion ?? _profile;
  // ====================================================
  // W07 FIGMA COLORS
  // ====================================================
  static const Color _background = Color(0xFFF6FAF9);
  static const Color _darkTeal = Color(0xFF173F42);
  static const Color _primaryTeal = Color(0xFF0D6461);
  static const Color _mint = Color(0xFFEAF8F4);
  static const Color _coral = Color(0xFFFF625F);
  static const Color _muted = Color(0xFF688080);
  static const Color _border = Color(0xFFD5E9E4);
  static const Color _activeGreen = Color(0xFF2E9D70);
  bool get _isPaused {
    if (controller == null) {
      return connectionStatus == MatchStatus.paused;
    }
    return controller?.currentConnection?.status == ConnectionStatus.paused;
  }

  bool get _isActive =>
      controller == null ||
      controller?.currentConnection?.status == ConnectionStatus.active;
  // ====================================================
  // NAVIGATION
  // ====================================================
  void _openScheduling(BuildContext context) {
    if (!_isActive) return;
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        builder: (_) => SchedulingHandoffScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          fromCurrentConnection: true,
          controller: controller,
        ),
      ),
    );
  }

  void _openManageConnection(BuildContext context) {
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        builder: (_) => ManageConnectionScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          connectionStatus: _isPaused
              ? MatchStatus.paused
              : MatchStatus.accepted,
          controller: controller,
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ====================================================
  // MAIN SCREEN
  // ====================================================
  @override
  Widget build(BuildContext context) {
    final currentController = controller;
    if (currentController == null) {
      return _buildContent(context);
    }
    return ListenableBuilder(
      listenable: currentController,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final currentStatus = controller?.currentConnection?.status;
    if (controller != null &&
        currentStatus != ConnectionStatus.active &&
        currentStatus != ConnectionStatus.paused) {
      return CompanionScaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                currentStatus == ConnectionStatus.ended
                    ? strings.connectionEnded
                    : strings.backToMatches,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _darkTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return CompanionScaffold(
      body: ColoredBox(
        color: _background,
        child: SafeArea(
          bottom: false,
          child: CompanionEntrance(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============================
                      // CARELINK HEADER
                      // ============================
                      CompanionFlowHeader(
                        onBack: () {
                          Navigator.of(context).maybePop();
                        },
                        backTooltip: strings.backToMatches,
                        trailingIcon: null,
                        showCoralDot: true,
                      ),
                      const SizedBox(height: 19),
                      // ============================
                      // PAGE TITLE
                      // ============================
                      Semantics(
                        header: true,
                        child: Text(
                          strings.myConnection,
                          style: const TextStyle(
                            color: _darkTeal,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _isPaused
                            ? strings.pausedActivitySubtitle
                            : strings.activeCompanionSubtitle,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        width: 34,
                        decoration: BoxDecoration(
                          color: _coral,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // ============================
                      // COMPANION PROFILE CARD
                      // ============================
                      _buildCompanionCard(context, strings, _isPaused),
                      const SizedBox(height: 22),
                      // ============================
                      // NEXT CHECK-IN
                      // ============================
                      _buildNextCheckInCard(
                        context,
                        strings,
                        controller?.currentConnection,
                      ),
                      const SizedBox(height: 33),
                      // ============================
                      // MAIN ACTION BUTTON
                      // ============================
                      _buildScheduleButton(context, strings),
                      const SizedBox(height: 28),
                      // ============================
                      // MANAGE CONNECTION
                      // ============================
                      _buildManageSection(context, strings),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      // ================================
      // FIGMA BOTTOM NAVIGATION
      // ================================
      bottomNavigationBar: SafeArea(
        top: false,
        child: Stack(
          children: [
            CompanionBottomNavigation(
              selectedLanguage: selectedLanguage,
              selectedIndex: 1,
              matchesIcon: Icons.favorite_border,
              selectedMatchesIcon: Icons.favorite_border,
              onDestinationSelected: (index) {
                if (index != 1) {
                  _showPlaceholder(context, strings.navigationComingSoon);
                }
              },
            ),
            // Slim Figma active-tab indicator.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  children: [
                    const Expanded(child: SizedBox.shrink()),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 2,
                          decoration: BoxDecoration(
                            color: _primaryTeal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // COMPANION PROFILE CARD
  // ====================================================
  Widget _buildCompanionCard(
    BuildContext context,
    CompanionStrings strings,
    bool isPaused,
  ) {
    // Use the existing matched interests.
    // Do not insert fake interests from Figma.
    final interests =
        controller?.sharedInterests ?? profile.interests.take(2).toList();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.075),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 2, child: ColoredBox(color: _primaryTeal)),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Actual Firebase profile image
                      CompanionAvatar(
                        name: profile.name,
                        size: 55,
                        imagePath: profile.imagePath,
                        imageUrl: profile.profileImageUrl,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _darkTeal,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (profile.verified) ...[
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      color: _primaryTeal,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        strings.verifiedCompanion,
                                        style: const TextStyle(
                                          color: _primaryTeal,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  // Active / Paused + Shared Interest Chips
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _statusChip(
                          isPaused: isPaused,
                          strings: strings,
                          maxWidth: constraints.maxWidth,
                        ),
                        for (final interest in interests)
                          _interestChip(
                            label: strings.interestLabel(interest),
                            icon: companionInterestIcon(interest),
                            maxWidth: constraints.maxWidth,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // STATUS CHIP
  // ====================================================
  Widget _statusChip({
    required bool isPaused,
    required CompanionStrings strings,
    required double maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPaused ? Icons.pause_circle_filled_rounded : Icons.circle,
              size: 11,
              color: isPaused ? _primaryTeal : _activeGreen,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                isPaused ? strings.paused : strings.currentConnectionActive,
                softWrap: true,
                style: const TextStyle(
                  color: _primaryTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // SHARED INTEREST CHIP
  // ====================================================
  Widget _interestChip({
    required String label,
    required IconData icon,
    required double maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _coral, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _coral, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: const TextStyle(
                  color: _coral,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // NEXT CHECK-IN FIREBASE STREAM
  // ====================================================
  Stream<ElderScheduleData> _watchSchedule(
    CompanionConnection connection,
  ) async* {
    final service = FirebaseElderService.instance;
    yield* service.watchScheduleForConnection(
      elderId: connection.elderId,
      companionId: connection.companionId,
      connectionId: connection.id,
    );
  }

  // ====================================================
  // NEXT CHECK-IN CARD
  // ====================================================
  Widget _buildNextCheckInCard(
    BuildContext context,
    CompanionStrings strings,
    CompanionConnection? connection,
  ) {
    return Material(
      color: _mint,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: _isActive ? () => _openScheduling(context) : null,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.fromLTRB(15, 12, 13, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.nextCheckIn,
                style: const TextStyle(
                  color: _primaryTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              if (connection == null ||
                  connection.status != ConnectionStatus.active)
                _nextCheckInRow(
                  text: connection?.status == ConnectionStatus.paused
                      ? strings.connectionPaused
                      : strings.checkInNotScheduled,
                )
              else
                StreamBuilder<ElderScheduleData>(
                  stream: _watchSchedule(connection),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _nextCheckInRow(text: 'Could not load check-in.');
                    }
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 25,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primaryTeal,
                            ),
                          ),
                        ),
                      );
                    }
                    final now = DateTime.now();
                    final data = snapshot.data!;
                    // Preserve the current Firestore
                    // scheduling status filters.
                    final upcoming =
                        data.checkIns
                            .where(
                              (item) =>
                                  (item.status == CheckInStatus.ready ||
                                      item.status == CheckInStatus.scheduled ||
                                      item.status ==
                                          CheckInStatus.inProgress) &&
                                  !item.scheduledAt.isBefore(now),
                            )
                            .toList()
                          ..sort(
                            (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
                          );
                    if (upcoming.isNotEmpty) {
                      final next = upcoming.first;
                      return _nextCheckInRow(
                        text: _formatNextCheckIn(context, next.scheduledAt),
                        semanticDetails:
                            '${next.durationMinutes} minutes, '
                            '${next.mode} check-in',
                      );
                    }
                    final recurring =
                        data.recurringSchedules
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
                      return _nextCheckInRow(text: strings.checkInNotScheduled);
                    }
                    final next = recurring.first;
                    return _nextCheckInRow(
                      text: _formatNextCheckIn(context, next.next!),
                      semanticDetails:
                          '${next.schedule.durationMinutes} minutes, '
                          '${next.schedule.mode} recurring check-in',
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================
  // FIGMA DAY + TIME FORMAT
  // ====================================================
  String _formatNextCheckIn(BuildContext context, DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final day = weekdays[date.weekday - 1];
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return '$day • $time';
  }

  Widget _nextCheckInRow({required String text, String? semanticDetails}) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: semanticDetails == null ? text : '$text, $semanticDetails',
            child: ExcludeSemantics(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkTeal,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_isActive)
          const Icon(
            Icons.chevron_right_rounded,
            color: _primaryTeal,
            size: 25,
          ),
      ],
    );
  }

  // ====================================================
  // MAIN SCHEDULE BUTTON
  // ====================================================
  Widget _buildScheduleButton(BuildContext context, CompanionStrings strings) {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton(
        onPressed: _isActive ? () => _openScheduling(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _border,
          disabledForegroundColor: _muted,
          elevation: 3,
          shadowColor: _darkTeal.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          strings.viewOrScheduleCheckIn,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // ====================================================
  // MANAGE CONNECTION SECTION
  // ====================================================
  Widget _buildManageSection(BuildContext context, CompanionStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () => _openManageConnection(context),
          style: TextButton.styleFrom(
            foregroundColor: _darkTeal,
            alignment: Alignment.centerLeft,
            minimumSize: const Size(0, 46),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            strings.manageConnection,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          strings.completedCheckInsUnaffected,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.45),
        ),
      ],
    );
  }
}
