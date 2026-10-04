import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_avatar.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/carelink_brand_header.dart';
import 'current_connection_screen.dart';
import 'scheduling_handoff_screen.dart';

class ConnectionAcceptedScreen extends StatelessWidget {
  const ConnectionAcceptedScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);
  static const Color _borderColor = Color(0xFFE7E0EC);

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final firstName = profile.name.split(' ').first;

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
                    Center(
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.9, end: 1),
                            duration: MediaQuery.of(context).disableAnimations
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) => Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value.clamp(0, 1),
                                child: child,
                              ),
                            ),
                            child: ExcludeSemantics(
                              child: Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: CompanionPalette.mint,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CompanionPalette.coral.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 58,
                                  color: _careLinkTeal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            header: true,
                            child: Text(
                              strings.connectionAccepted,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.greatConnection,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: _careLinkTeal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.youAndCompanionConnected(firstName),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCompanionCard(context, strings),
                    const SizedBox(height: 16),
                    _buildAgreementCard(context, strings),
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
                    onPressed: () {
                      Navigator.of(context).push(
                        CompanionRoute<void>(
                          context: context,
                          builder: (_) => CurrentConnectionScreen(
                            profile: profile,
                            selectedLanguage: selectedLanguage,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _careLinkTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      strings.viewConnection,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      CompanionRoute<void>(
                        context: context,
                        builder: (_) => SchedulingHandoffScreen(
                          profile: profile,
                          selectedLanguage: selectedLanguage,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _careLinkTeal,
                      side: const BorderSide(color: _careLinkTeal),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
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

  Widget _buildAgreementCard(BuildContext context, CompanionStrings strings) {
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: CareLinkTheme.successColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.bothPeopleAgreed,
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: CareLinkTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 17,
                      color: CareLinkTheme.successColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        strings.active,
                        style: const TextStyle(
                          color: CareLinkTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(strings.connectionStatusActive, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
