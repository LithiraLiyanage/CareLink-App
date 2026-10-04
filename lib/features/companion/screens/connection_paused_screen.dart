import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'current_connection_screen.dart';

/// W08C: pausing keeps the connection; only Resume returns it to Active.
class ConnectionPausedScreen extends StatelessWidget {
  const ConnectionPausedScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
    required this.connectionStatus,
  }) : assert(connectionStatus == MatchStatus.paused);

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;
  final MatchStatus connectionStatus;

  void _openConnection(BuildContext context, MatchStatus nextStatus) {
    Navigator.of(context).pushAndRemoveUntil(
      CompanionRoute<void>(
        context: context,
        builder: (_) => CurrentConnectionScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          connectionStatus: nextStatus,
        ),
      ),
      // Discard older Active screens. W02 remains as the companion-flow base.
      (route) => route.settings.name == '/companion-recommendations',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final motionDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    // System Back cannot uncover the older Active route underneath W08C.
    // The two visible actions explicitly carry the chosen status to W07.
    return PopScope(
      canPop: false,
      child: CompanionScaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('CareLink'),
        ),
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
                          strings.connectionPaused,
                          style: textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.pausedActivitySubtitle,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CompanionAvatar(
                                name: profile.name,
                                size: 76,
                                imagePath: profile.imagePath,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                profile.name,
                                style: textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              AnimatedContainer(
                                duration: motionDuration,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: CompanionPalette.mint,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: CompanionPalette.teal.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.pause_circle_outline,
                                      size: 20,
                                      color: CompanionPalette.teal,
                                    ),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        strings.paused,
                                        style: const TextStyle(
                                          color: CompanionPalette.ink,
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
                      ),
                      const SizedBox(height: 16),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: CompanionPalette.teal,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        strings.whatThisMeans,
                                        style: textTheme.titleMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                strings.pausedMeaning,
                                style: textTheme.bodyMedium,
                              ),
                            ],
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _openConnection(context, MatchStatus.accepted),
                      child: Text(
                        strings.resumeConnection,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () =>
                          _openConnection(context, MatchStatus.paused),
                      child: Text(
                        strings.backToConnection,
                        textAlign: TextAlign.center,
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
