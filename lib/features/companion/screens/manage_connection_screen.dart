import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
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

  static const Color _teal = Color(0xFF087F83);

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final isPaused = connectionStatus == MatchStatus.paused;

    return CompanionScaffold(
      appBar: AppBar(title: const Text('CareLink')),
      body: CompanionEntrance(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        strings.manageConnectionTitle,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CompanionPalette.amber,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: CompanionPalette.ink,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.confirmationProtects,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name, style: textTheme.titleLarge),
                            const SizedBox(height: 12),
                            AnimatedContainer(
                              duration: MediaQuery.of(context).disableAnimations
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isPaused
                                    ? CompanionPalette.mint
                                    : CareLinkTheme.successColor.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPaused
                                        ? Icons.pause_circle_outline
                                        : Icons.check_circle,
                                    color: isPaused
                                        ? CompanionPalette.teal
                                        : CareLinkTheme.successColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isPaused
                                          ? strings.paused
                                          : strings.currentConnectionActive,
                                      style: textTheme.bodyLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strings.companionSince,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      margin: EdgeInsets.zero,
                      color: CompanionPalette.mint,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: CompanionPalette.teal
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    isPaused
                                        ? Icons.play_arrow_outlined
                                        : Icons.pause_outlined,
                                    color: CompanionPalette.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPaused
                                            ? strings.resumeConnection
                                            : strings.pauseConnection,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isPaused
                                            ? strings.pausedMeaning
                                            : strings
                                                  .pauseConnectionDescription,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushReplacement(
                                    CompanionRoute<void>(
                                      context: context,
                                      builder: (_) => ConnectionPausedScreen(
                                        profile: profile,
                                        selectedLanguage: selectedLanguage,
                                        connectionStatus: MatchStatus.paused,
                                      ),
                                    ),
                                  ),
                              icon: Icon(
                                isPaused
                                    ? Icons.play_arrow_outlined
                                    : Icons.pause_outlined,
                              ),
                              label: Text(
                                isPaused
                                    ? strings.resumeConnection
                                    : strings.pauseConnection,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text(
                        strings.viewConnection,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      color: CompanionPalette.coral.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
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
                          icon: const Icon(Icons.rate_review_outlined),
                          label: Text(
                            strings.reviewEndConnection,
                            textAlign: TextAlign.center,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CareLinkTheme.errorColor,
                            side: const BorderSide(
                              color: CareLinkTheme.errorColor,
                            ),
                            minimumSize: const Size(double.infinity, 52),
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
      ),
    );
  }
}
