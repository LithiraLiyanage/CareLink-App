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

import '../../elder/screens/my_schedule_screen.dart';

import '../../elder/screens/new_recurring_checkin_screen.dart';

import 'current_connection_screen.dart';

/// H01 — Scheduling Hand-off

///

/// This screen preserves the existing scheduling navigation.

/// Only the visual layout has been redesigned to match Figma.

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

  final bool fromCurrentConnection;

  CompanionProfile get selectedCompanion =>
      controller?.selectedCompanion ?? profile;

  // =====================================================

  // FIGMA COLOR SYSTEM

  // =====================================================

  static const Color _background = Color(0xFFF6FAF9);

  static const Color _darkTeal = Color(0xFF173F42);

  static const Color _primaryTeal = Color(0xFF0D605D);

  static const Color _coral = Color(0xFFFF655F);

  static const Color _muted = Color(0xFF688080);

  static const Color _border = Color(0xFFD5E9E4);

  static const Color _lightCoral = Color(0xFFFFECEB);

  static const String _illustrationAsset =
      'assets/images/scheduling_handoff_illustration.png';

  // =====================================================

  // ORIGINAL CONNECTION DATA — PRESERVED

  // =====================================================

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

  // =====================================================

  // ORIGINAL BACK NAVIGATION — PRESERVED

  // =====================================================

  void _backToConnection(BuildContext context) {
    final navigator = Navigator.of(context);

    if (fromCurrentConnection && navigator.canPop()) {
      navigator.pop();

      return;
    }

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

  // =====================================================

  // ORIGINAL SCHEDULING FLOW — PRESERVED

  // =====================================================

  Future<void> _continueToScheduling(
    BuildContext context,

    CompanionStrings strings,
  ) async {
    final connection = controller?.currentConnection;

    if (connection == null || connection.status != ConnectionStatus.active) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.connectionNotActive)));

      return;
    }

    final details = schedulingDetails;

    final created = await Navigator.of(context).push<bool>(
      CompanionRoute<bool>(
        context: context,

        builder: (_) => NewRecurringCheckInScreen(
          connectionId: details.connectionId,

          elderId: details.elderId,

          elderName: controller?.currentRequest?.elderDisplayName ?? '',

          companionId: details.companionId,

          companionName: details.companionName,

          preferredCheckInType: details.preferredCheckInType,
        ),
      ),
    );

    if (!context.mounted || created != true) {
      return;
    }

    Navigator.of(context).pushReplacement(
      CompanionRoute<void>(
        context: context,

        builder: (_) => MyScheduleScreen(
          connectionId: details.connectionId,

          elderId: details.elderId,

          elderName: controller?.currentRequest?.elderDisplayName ?? '',

          companionId: details.companionId,

          companionName: details.companionName,

          companionImageUrl: selectedCompanion.profileImageUrl,

          preferredCheckInType: details.preferredCheckInType,
        ),
      ),
    );
  }

  // =====================================================

  // MAIN FIGMA UI

  // =====================================================

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);

    final firstName = selectedCompanion.firstName;

    return CompanionScaffold(
      body: ColoredBox(
        color: _background,

        child: SafeArea(
          bottom: false,

          child: CompanionEntrance(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // -------------------------

                      // HEADER

                      // -------------------------
                      CompanionFlowHeader(
                        onBack: () => _backToConnection(context),

                        backTooltip: strings.backToConnection,

                        trailingIcon: null,

                        showCoralDot: true,
                      ),

                      const SizedBox(height: 21),

                      // -------------------------

                      // TITLE

                      // -------------------------
                      Semantics(
                        header: true,

                        child: Text(
                          strings.scheduleCheckIn,

                          style: const TextStyle(
                            color: _darkTeal,

                            fontSize: 27,

                            fontWeight: FontWeight.w900,

                            letterSpacing: -0.65,

                            height: 1.15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        strings.schedulingHandoffSubtitle,

                        style: const TextStyle(
                          color: _muted,

                          fontSize: 13,

                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        width: 34,

                        height: 4,

                        decoration: BoxDecoration(
                          color: _coral,

                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -------------------------

                      // FIGMA ILLUSTRATION

                      // -------------------------
                      _buildIllustration(),

                      // -------------------------

                      // HAND-OFF BADGE

                      // -------------------------
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,

                            vertical: 7,
                          ),

                          decoration: BoxDecoration(
                            color: _lightCoral,

                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: Text(
                            strings.systemHandoff,

                            style: const TextStyle(
                              color: _coral,

                              fontSize: 12,

                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // -------------------------

                      // READY TO SCHEDULE

                      // -------------------------
                      Center(
                        child: Text(
                          strings.readyToSchedule(firstName),

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            color: _darkTeal,

                            fontSize: 21,

                            height: 1.2,

                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      // Show the selected companion's full name so the
                      // Elder can confirm who the check-in is with.
                      // Uses the live profile/controller value, never a hardcoded name.
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          selectedCompanion.name,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),

                      const SizedBox(height: 13),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 290),

                          child: Text(
                            strings.acceptedConnectionHandoffDescription,

                            textAlign: TextAlign.center,

                            style: const TextStyle(
                              color: _muted,

                              fontSize: 13,

                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------------------------

                      // NEXT MODULE CARD

                      // -------------------------
                      _buildNextModuleCard(strings),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // =================================================

      // FIXED BOTTOM BUTTONS — FIGMA LAYOUT

      // =================================================
      bottomNavigationBar: SafeArea(
        top: false,

        child: Container(
          color: _background,

          padding: const EdgeInsets.fromLTRB(20, 10, 20, 44),

          child: Center(
            heightFactor: 1,

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  _primaryButton(
                    label: strings.continueToScheduling,

                    onPressed: () => _continueToScheduling(context, strings),
                  ),

                  const SizedBox(height: 18),

                  _outlineButton(
                    label: strings.backToConnection,

                    onPressed: () => _backToConnection(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================

  // FIGMA ILLUSTRATION

  // =====================================================

  Widget _buildIllustration() {
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,

        height: 175,

        child: Image.asset(
          _illustrationAsset,

          width: double.infinity,

          height: 175,

          fit: BoxFit.contain,

          filterQuality: FilterQuality.high,

          errorBuilder: (_, _, _) {
            return _buildIllustrationFallback();
          },
        ),
      ),
    );
  }

  // If the Figma PNG has not been exported yet,

  // use the existing companion image and a calendar.

  // This is only a visual fallback.

  Widget _buildIllustrationFallback() {
    return SizedBox(
      height: 175,

      child: Stack(
        alignment: Alignment.center,

        children: [
          Positioned(
            left: 8,

            bottom: 8,

            child: CircleAvatar(
              radius: 58,

              backgroundColor: const Color(0xFFD9EEE7),

              child: const Icon(
                Icons.elderly_woman_rounded,

                color: _primaryTeal,

                size: 73,
              ),
            ),
          ),

          Positioned(
            right: 8,

            bottom: 8,

            child: CircleAvatar(
              radius: 58,

              backgroundColor: const Color(0xFFE7F2EC),

              child: CompanionAvatar(
                name: selectedCompanion.name,

                size: 92,

                imagePath: selectedCompanion.imagePath,

                imageUrl: selectedCompanion.profileImageUrl,
              ),
            ),
          ),

          Positioned(
            top: 16,

            child: Container(
              width: 82,

              height: 86,

              decoration: BoxDecoration(
                color: const Color(0xFFFFB3A7),

                borderRadius: BorderRadius.circular(15),

                boxShadow: [
                  BoxShadow(
                    color: _coral.withValues(alpha: 0.13),

                    blurRadius: 13,

                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                children: [
                  const SizedBox(height: 9),

                  const Icon(
                    Icons.calendar_month_rounded,

                    color: Colors.white,

                    size: 20,
                  ),

                  const SizedBox(height: 3),

                  Container(
                    width: 55,

                    height: 48,

                    alignment: Alignment.center,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: const Text(
                      '31',

                      style: TextStyle(
                        color: _darkTeal,

                        fontSize: 27,

                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================

  // NEXT MODULE CARD

  // =====================================================

  Widget _buildNextModuleCard(CompanionStrings strings) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: _border),

        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.065),

            blurRadius: 16,

            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            height: 42,

            width: 42,

            decoration: const BoxDecoration(
              color: _lightCoral,

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.calendar_month_rounded,

              color: _coral,

              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  strings.nextModule,

                  style: const TextStyle(
                    color: _coral,

                    fontSize: 13,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  strings.schedulingNextSteps,

                  style: const TextStyle(
                    color: _darkTeal,

                    fontSize: 12.5,

                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================

  // FIGMA BUTTONS

  // =====================================================

  Widget _primaryButton({
    required String label,

    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 53,

      width: double.infinity,

      child: ElevatedButton(
        onPressed: onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryTeal,

          foregroundColor: Colors.white,

          elevation: 3,

          shadowColor: _darkTeal.withValues(alpha: 0.13),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        child: Text(
          label,

          textAlign: TextAlign.center,

          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,

    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 53,

      width: double.infinity,

      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryTeal,

          backgroundColor: Colors.white,

          side: const BorderSide(color: _primaryTeal, width: 1.5),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),

        child: Text(
          label,

          textAlign: TextAlign.center,

          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
