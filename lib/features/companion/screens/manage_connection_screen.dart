import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'connection_paused_screen.dart';
import 'end_connection_confirmation_screen.dart';

/// W08: review an active connection before choosing whether to end it.
class ManageConnectionScreen extends StatelessWidget {
  const ManageConnectionScreen({
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

  static const Color _danger = Color(0xFFB43F42);

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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanionFlowHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      backTooltip: strings.viewConnection,
                      trailingIcon: null,
                      showCoralDot: true,
                    ),
                    const SizedBox(height: 18),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.manageConnectionTitle,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 27,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.manageConnectionSubtitle,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CompanionPalette.coral,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCompanionCard(context, strings, isPaused),
                    const SizedBox(height: 16),
                    _buildPausePanel(context, strings, isPaused),
                    const SizedBox(height: 16),
                    _buildEndPanel(context, strings),
                    const SizedBox(height: 14),
                    _buildReassurancePanel(context, strings),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: CompanionPalette.teal,
                        minimumSize: const Size(0, 48),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(strings.viewConnection),
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
              child: Row(
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
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: MediaQuery.of(context).disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
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
                                size: 10,
                                color: isPaused
                                    ? CompanionPalette.teal
                                    : const Color(0xFF2F855F),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  isPaused
                                      ? strings.paused
                                      : strings.currentConnectionActive,
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

  Widget _buildPausePanel(
    BuildContext context,
    CompanionStrings strings,
    bool isPaused,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CompanionPalette.mint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CompanionPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: CompanionPalette.teal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaused
                          ? strings.resumeConnection
                          : strings.pauseConnection,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CompanionPalette.teal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isPaused
                          ? strings.pausedMeaning
                          : strings.pauseConnectionDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  CompanionRoute<void>(
                    context: context,
                    builder: (_) => ConnectionPausedScreen(
                      profile: profile,
                      selectedLanguage: selectedLanguage,
                      connectionStatus: MatchStatus.paused,
                    ),
                  ),
                ),
                child: Text(
                  isPaused ? strings.resumeConnection : strings.pauseConnection,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndPanel(BuildContext context, CompanionStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CompanionPalette.coral.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CompanionPalette.coral.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: _danger, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.endConnection,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CompanionPalette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.endConnectionCardDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  CompanionRoute<void>(
                    context: context,
                    builder: (_) => EndConnectionConfirmationScreen(
                      profile: profile,
                      selectedLanguage: selectedLanguage,
                      connectionStatus: connectionStatus,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _danger,
                  side: const BorderSide(color: _danger, width: 1.5),
                ),
                child: Text(
                  strings.reviewEndConnection,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReassurancePanel(
    BuildContext context,
    CompanionStrings strings,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8E2BD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.noAccidentalEnding,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF9A6200),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.confirmationProtects,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
