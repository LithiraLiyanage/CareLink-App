import 'package:flutter/material.dart';

import '../controllers/companion_controller.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_interest_icon.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'current_connection_screen.dart';
import 'scheduling_handoff_screen.dart';

class ConnectionAcceptedScreen extends StatelessWidget {
  const ConnectionAcceptedScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
    this.controller,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;
  final CompanionController? controller;

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final firstName = profile.firstName;

    return CompanionScaffold(
      body: Stack(
        children: [
          if (profile.id.endsWith('nethmi'))
            Positioned(
              left: 0,
              right: 0,
              bottom: -40,
              height: MediaQuery.sizeOf(context).height * 0.8,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.asset(
                      'assets/images/companion_accepted_illustration.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: CompanionEntrance(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CompanionFlowHeader(
                          onBack: () => Navigator.of(context).maybePop(),
                          backTooltip: strings.backToMatches,
                          trailingIcon: Icons.celebration_outlined,
                          trailingColor: CompanionPalette.coral,
                        ),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 290),
                          child: Semantics(
                            header: true,
                            child: Text(
                              strings.connectionAccepted,
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 29,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: 34,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CompanionPalette.coral,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 14,
                          runSpacing: 8,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 170),
                              child: Text(
                                strings.youAndCompanionConnected(firstName),
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: CompanionPalette.coral,
                                ),
                              ),
                              child: Text(
                                strings.greatConnection,
                                style: const TextStyle(
                                  color: CompanionPalette.coral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        _buildCompanionCard(context, strings),
                        const SizedBox(height: 18),
                        CompanionEntrance(
                          delay: const Duration(milliseconds: 70),
                          child: _buildAgreementPanel(context, strings),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: CompanionPalette.background,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      CompanionRoute<void>(
                        context: context,
                        builder: (_) => CurrentConnectionScreen(
                          profile: profile,
                          selectedLanguage: selectedLanguage,
                          controller: controller,
                        ),
                      ),
                    ),
                    child: Text(
                      strings.viewConnection,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 9),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      CompanionRoute<void>(
                        context: context,
                        builder: (_) => SchedulingHandoffScreen(
                          profile: profile,
                          selectedLanguage: selectedLanguage,
                          controller: controller,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.event_available_outlined, size: 20),
                    label: Text(
                      strings.scheduleCheckIn,
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

  Widget _buildCompanionCard(BuildContext context, CompanionStrings strings) {
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
              padding: const EdgeInsets.all(14),
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
                              _buildVerifiedBadge(strings.verifiedCompanion),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 20,
                        color: CompanionPalette.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.sharedInterests,
                          style: textTheme.bodySmall?.copyWith(
                            color: CompanionPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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

  Widget _buildVerifiedBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CompanionPalette.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 13, color: CompanionPalette.teal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: CompanionPalette.teal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CompanionPalette.coral),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: CompanionPalette.coral),
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

  Widget _buildAgreementPanel(BuildContext context, CompanionStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CompanionPalette.mint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CompanionPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_alt_rounded,
            color: CompanionPalette.teal,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.bothPeopleAgreed,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CompanionPalette.teal,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF2F855F),
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        strings.connectionStatusActive,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CompanionPalette.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
