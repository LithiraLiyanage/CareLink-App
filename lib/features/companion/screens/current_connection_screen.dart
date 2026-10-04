import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_bottom_navigation.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/carelink_brand_header.dart';
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

  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);
  static const Color _borderColor = Color(0xFFE7E0EC);

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
      body: CompanionEntrance(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CareLinkBrandHeader(),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.myConnection,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPaused
                          ? strings.pausedActivitySubtitle
                          : strings.activeCompanionSubtitle,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    _buildCompanionCard(context, strings),
                    const SizedBox(height: 16),
                    _buildNextCheckInCard(context, strings),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: CareLinkTheme.surfaceColor,
                border: Border(top: BorderSide(color: _borderColor)),
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _careLinkTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: Text(
                          strings.viewOrScheduleCheckIn,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _careLinkTeal,
                          side: const BorderSide(color: _careLinkTeal),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: Text(
                          strings.manageConnection,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.completedCheckInsUnaffected,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CompanionBottomNavigation(
              selectedLanguage: selectedLanguage,
              selectedIndex: 1,
              onDestinationSelected: (index) {
                if (index != 1) {
                  _showPlaceholder(context, strings.navigationComingSoon);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionCard(BuildContext context, CompanionStrings strings) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CompanionAvatar(
                    name: profile.name,
                    size: 56,
                    imagePath: profile.imagePath,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: textTheme.titleLarge),
                        if (profile.verified) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 18,
                                color: _careLinkTeal,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  strings.verifiedCompanion,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: _careLinkTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: connectionStatus == MatchStatus.paused
                      ? CompanionPalette.mint
                      : CareLinkTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectionStatus == MatchStatus.paused
                          ? Icons.pause_circle_outline
                          : Icons.check_circle,
                      size: 18,
                      color: connectionStatus == MatchStatus.paused
                          ? CompanionPalette.teal
                          : CareLinkTheme.successColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        connectionStatus == MatchStatus.paused
                            ? strings.paused
                            : strings.currentConnectionActive,
                        style: const TextStyle(
                          color: CareLinkTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Semantics(
                header: true,
                child: Text(
                  strings.sharedInterests,
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.interests.take(2).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _careLinkCoral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        color: CareLinkTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextCheckInCard(BuildContext context, CompanionStrings strings) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: CompanionPalette.mint,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(strings.nextCheckIn, style: textTheme.titleMedium),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    size: 24,
                    color: _careLinkTeal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.nextCheckInTime,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: _careLinkTeal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
