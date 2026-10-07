import 'package:flutter/material.dart';

import '../controllers/companion_controller.dart';
import '../models/companion_connection.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
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
    this.controller,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;
  final CompanionController? controller;

  CompanionProfile get selectedCompanion =>
      controller?.selectedCompanion ?? profile;

  /// True when W07 is directly underneath H01 on the navigation stack.
  final bool fromCurrentConnection;

  /// Minimum data a future, agreed scheduling route would need. Nothing is
  /// sent until that route exists; the full profile stays in this module.
  ({
    String companionId,
    String companionName,
    String? connectionId,
    String? elderId,
    String? preferredCheckInType,
  })
  get schedulingDetails => (
    companionId: selectedCompanion.id,
    companionName: selectedCompanion.name,
    connectionId: controller?.currentConnection?.id,
    elderId: controller?.currentConnection?.elderId,
    preferredCheckInType: controller?.currentPreferences?.checkInType,
  );

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
          profile: selectedCompanion,
          selectedLanguage: selectedLanguage,
          controller: controller,
        ),
      ),
    );
  }

  void _continueToScheduling(BuildContext context, CompanionStrings strings) {
    if (controller != null &&
        controller?.currentConnection?.status != ConnectionStatus.active) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.connectionNotActive)));
      return;
    }
    // TODO: When the team's scheduling route is registered, pass only
    // schedulingDetails after confirming the connection is still active.
    // Never pass private conversation content.
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
    final firstName = selectedCompanion.firstName;

    return CompanionScaffold(
      body: SafeArea(
        child: CompanionEntrance(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanionFlowHeader(
                      onBack: () => _backToConnection(context),
                      backTooltip: strings.backToConnection,
                      trailingIcon: null,
                      showCoralDot: true,
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.scheduleCheckIn,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 27,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.schedulingHandoffSubtitle,
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
                    const SizedBox(height: 10),
                    Center(
                      child: ExcludeSemantics(
                        child: SizedBox(
                          width: double.infinity,
                          height: 160,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CompanionAvatar(
                                name: selectedCompanion.name,
                                size: 96,
                                imagePath: selectedCompanion.imagePath,
                              ),
                              const SizedBox(width: 20),
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: CompanionPalette.coral,
                                size: 74,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: CompanionPalette.coral.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Semantics(
                          header: true,
                          child: Text(
                            strings.systemHandoff,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CompanionPalette.coral,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        selectedCompanion.name,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        strings.readyToSchedule(firstName),
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 310),
                        child: Text(
                          strings.acceptedConnectionHandoffDescription,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildNextModuleCard(context, strings),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                    child: Text(
                      strings.continueToScheduling,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: () => _backToConnection(context),
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

  Widget _buildNextModuleCard(BuildContext context, CompanionStrings strings) {
    final textTheme = CompanionScaffold.textTheme(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CompanionPalette.border),
        boxShadow: [
          BoxShadow(
            color: CompanionPalette.ink.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
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
            child: const Icon(
              Icons.calendar_month_outlined,
              color: CompanionPalette.coral,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    strings.nextModule,
                    style: textTheme.titleMedium?.copyWith(
                      color: CompanionPalette.coral,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  strings.schedulingNextSteps,
                  style: textTheme.bodyMedium?.copyWith(
                    color: CompanionPalette.ink,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
