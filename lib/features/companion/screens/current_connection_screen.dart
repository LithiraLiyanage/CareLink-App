// Keep the existing `profile:` route argument while using controller state.
// ignore_for_file: prefer_initializing_formals

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
  CompanionProfile get profile => controller?.selectedCompanion ?? _profile;
  final CompanionLanguage selectedLanguage;
  final MatchStatus connectionStatus;
  final CompanionController? controller;

  bool get _isPaused => controller == null
      ? connectionStatus == MatchStatus.paused
      : controller?.currentConnection?.status == ConnectionStatus.paused;

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentController = controller;
    if (currentController == null) return _build(context);
    return ListenableBuilder(
      listenable: currentController,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    if (controller != null &&
        controller?.currentConnection?.status != ConnectionStatus.active &&
        controller?.currentConnection?.status != ConnectionStatus.paused) {
      return CompanionScaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller?.currentConnection?.status == ConnectionStatus.ended
                    ? strings.connectionEnded
                    : strings.backToMatches,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
            ),
          ),
        ),
      );
    }
    final isPaused = _isPaused;
    final isActive =
        controller == null ||
        controller?.currentConnection?.status == ConnectionStatus.active;

    return CompanionScaffold(
      body: SafeArea(
        bottom: false,
        child: CompanionEntrance(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanionFlowHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      backTooltip: strings.backToMatches,
                      trailingIcon: null,
                      showCoralDot: true,
                    ),
                    const SizedBox(height: 18),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.myConnection,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 27,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isPaused
                          ? strings.pausedActivitySubtitle
                          : strings.activeCompanionSubtitle,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CompanionPalette.coral,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildCompanionCard(context, strings, isPaused),
                    const SizedBox(height: 24),
                    _buildNextCheckInCard(
                      context,
                      strings,
                      controller?.currentConnection,
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: !isActive
                            ? null
                            : () => Navigator.of(context).push(
                                CompanionRoute<void>(
                                  context: context,
                                  builder: (_) => SchedulingHandoffScreen(
                                    profile: profile,
                                    selectedLanguage: selectedLanguage,
                                    fromCurrentConnection: true,
                                    controller: controller,
                                  ),
                                ),
                              ),
                        child: Text(
                          strings.viewOrScheduleCheckIn,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        CompanionRoute<void>(
                          context: context,
                          builder: (_) => ManageConnectionScreen(
                            profile: profile,
                            selectedLanguage: selectedLanguage,
                            connectionStatus: isPaused
                                ? MatchStatus.paused
                                : MatchStatus.accepted,
                            controller: controller,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: CompanionPalette.ink,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        alignment: Alignment.centerLeft,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: Text(strings.manageConnection),
                    ),
                    Text(
                      strings.completedCheckInsUnaffected,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CompanionBottomNavigation(
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
      ),
    );
  }

  Widget _buildCompanionCard(
    BuildContext context,
    CompanionStrings strings,
    bool isPaused,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final interests =
        controller?.sharedInterests ?? profile.interests.take(2).toList();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(
              width: double.infinity,
              height: 3,
              child: ColoredBox(color: CompanionPalette.teal),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CompanionAvatar(
                        name: profile.name,
                        size: 54,
                        imagePath: profile.imagePath,
                        imageUrl: profile.profileImageUrl,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (profile.verified) ...[
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CompanionPalette.mint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      size: 13,
                                      color: CompanionPalette.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        strings.verifiedCompanion,
                                        style: const TextStyle(
                                          color: CompanionPalette.teal,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: MediaQuery.of(context).disableAnimations
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CompanionPalette.mint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPaused ? Icons.pause_circle : Icons.circle,
                              color: isPaused
                                  ? CompanionPalette.teal
                                  : const Color(0xFF2F855F),
                              size: 11,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                isPaused
                                    ? strings.paused
                                    : strings.currentConnectionActive,
                                softWrap: true,
                                style: const TextStyle(
                                  color: CompanionPalette.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var i = 0; i < interests.length; i++)
                        _buildInterestChip(
                          strings.interestLabel(interests[i]),
                          companionInterestIcon(interests[i]),
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

  Widget _buildInterestChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CompanionPalette.coral),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CompanionPalette.coral),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: CompanionPalette.coral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildNextCheckInCard(
    BuildContext context,
    CompanionStrings strings,
    CompanionConnection? connection,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CompanionPalette.mint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CompanionPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              strings.nextCheckIn,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CompanionPalette.teal,
              ),
            ),
          ),
          const SizedBox(height: 7),
          if (connection == null ||
              connection.status != ConnectionStatus.active)
            Text(
              connection?.status == ConnectionStatus.paused
                  ? strings.connectionPaused
                  : strings.checkInNotScheduled,
              style: textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            StreamBuilder<ElderScheduleData>(
              stream: _watchSchedule(connection),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Could not load check-in schedule: ${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 28,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final data = snapshot.data!;
                final now = DateTime.now();
                final upcoming =
                    data.checkIns
                        .where(
                          (checkIn) =>
                              (checkIn.status == CheckInStatus.ready ||
                                  checkIn.status == CheckInStatus.scheduled ||
                                  checkIn.status == CheckInStatus.inProgress) &&
                              !checkIn.scheduledAt.isBefore(now),
                        )
                        .toList()
                      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
                if (upcoming.isNotEmpty) {
                  final next = upcoming.first;
                  return Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(next.scheduledAt)} · '
                    '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(next.scheduledAt))} · '
                    '${next.durationMinutes} min · ${next.mode}',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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
                  return Text(
                    strings.checkInNotScheduled,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }
                final next = recurring.first;
                return Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(next.next!)} · '
                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(next.next!))} · '
                  '${next.schedule.durationMinutes} min · ${next.schedule.mode}',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
