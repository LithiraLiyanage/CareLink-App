import 'package:flutter/material.dart';

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
    required this.profile,
    required this.selectedLanguage,
    this.connectionStatus = MatchStatus.accepted,
  }) : assert(
         connectionStatus == MatchStatus.accepted ||
             connectionStatus == MatchStatus.paused,
       );

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;
  final MatchStatus connectionStatus;

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final isPaused = connectionStatus == MatchStatus.paused;

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
                    _buildNextCheckInCard(context, strings),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isPaused
                            ? null
                            : () => Navigator.of(context).push(
                                CompanionRoute<void>(
                                  context: context,
                                  builder: (_) => SchedulingHandoffScreen(
                                    profile: profile,
                                    selectedLanguage: selectedLanguage,
                                    fromCurrentConnection: true,
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
                            connectionStatus: connectionStatus,
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
    final interests = profile.interests.take(2).toList();

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

  Widget _buildNextCheckInCard(BuildContext context, CompanionStrings strings) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.id == 'nethmi'
                      ? strings.nextCheckInTime
                      : strings.checkInNotScheduled,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: CompanionPalette.teal,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
