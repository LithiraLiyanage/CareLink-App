import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_avatar.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import 'current_connection_screen.dart';

/// H01: a companion-owned hand-off, not a scheduling form.
///
/// Only accepted/current connection screens open this screen in the mock flow.
class SchedulingHandoffScreen extends StatelessWidget {
  const SchedulingHandoffScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
    this.fromCurrentConnection = false,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  /// True when W07 is directly underneath H01 on the navigation stack.
  final bool fromCurrentConnection;

  /// Minimum data a future, agreed scheduling route would need. Nothing is
  /// sent until that route exists; the full profile stays in this module.
  ({String companionId, String companionName, CompanionLanguage language})
  get schedulingDetails => (
    companionId: profile.id,
    companionName: profile.name,
    language: selectedLanguage,
  );

  static const Color _teal = Color(0xFF087F83);
  static const Color _border = Color(0xFFE7E0EC);

  void _backToConnection(BuildContext context) {
    final navigator = Navigator.of(context);
    if (fromCurrentConnection && navigator.canPop()) {
      navigator.pop();
      return;
    }

    // W06 is below H01 in this path. Replace only H01 with W07 so the Back to
    // Connection action always lands on the accepted current connection.
    navigator.pushReplacement(
      CompanionRoute<void>(
        context: context,
        builder: (_) => CurrentConnectionScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
        ),
      ),
    );
  }

  void _continueToScheduling(BuildContext context, CompanionStrings strings) {
    // TODO: When the team's scheduling route is registered, pass only
    // schedulingDetails (ID, display name, language) after confirming the
    // connection is still active. Never pass private conversation content.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(strings.schedulingIntegrationPending)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final firstName = profile.name.trim().split(RegExp(r'\s+')).first;

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
                        strings.scheduleCheckIn,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.schedulingHandoffSubtitle,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      color: CompanionPalette.mint,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.sync_alt,
                                  color: _teal,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      strings.systemHandoff,
                                      style: textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CompanionAvatar(
                                  name: profile.name,
                                  size: 50,
                                  imagePath: profile.imagePath,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.name,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: CareLinkTheme.successColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              strings.currentConnectionActive,
                                              style: textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              strings.readyToSchedule(firstName),
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              strings.acceptedConnectionHandoffDescription,
                              style: textTheme.bodyMedium,
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
                                  Icons.event_available_outlined,
                                  color: _teal,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      strings.nextModule,
                                      style: textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strings.schedulingNextSteps,
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: CareLinkTheme.surfaceColor,
            border: Border(top: BorderSide(color: _border)),
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
                    onPressed: () => _continueToScheduling(context, strings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      strings.continueToScheduling,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _backToConnection(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _teal,
                      side: const BorderSide(color: _teal),
                      minimumSize: const Size(double.infinity, 52),
                    ),
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
    );
  }
}
