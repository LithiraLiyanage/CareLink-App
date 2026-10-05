import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_avatar.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../models/match_preferences.dart';
import '../services/companion_recommendations.dart';
import '../widgets/carelink_brand_header.dart';
import 'send_match_request_screen.dart';

class CompanionProfileScreen extends StatelessWidget {
  const CompanionProfileScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
    this.preferences,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;
  final MatchPreferences? preferences;

  MatchPreferences get _effectivePreferences =>
      preferences ??
      MatchPreferences(
        preferredLanguage: selectedLanguage.storedValue,
        interests: const [],
        availability: '',
        preferredTime: '',
        checkInType: '',
      );

  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);
  static const Color _chipBorderColor = Color(0xFFE7E0EC);

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final reasons = CompanionRecommendations.reasonsFor(
      profile,
      _effectivePreferences,
    );
    final sharedCount = CompanionRecommendations.sharedInterestCount(
      profile,
      _effectivePreferences,
    );

    return CompanionScaffold(
      body: CompanionEntrance(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: strings.backToRecommendations,
                          color: _careLinkTeal,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: CompanionPalette.border,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: const CareLinkBrandHeader()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProfileHeader(context, strings),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: strings.about,
                      child: Text(
                        strings.profileAbout(profile),
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: strings.languages,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.languages
                            .map((language) => _buildChip(language))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: strings.interests,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.interests
                            .map(
                              (interest) => _buildChip(
                                strings.interestLabel(interest),
                                highlighted: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: strings.availability,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            color: _careLinkTeal,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              strings.profileAvailability(profile),
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: strings.whyGoodMatch,
                      highlighted: true,
                      child: reasons.isEmpty
                          ? Text(
                              strings.noPreferenceOverlap,
                              style: textTheme.bodyMedium,
                            )
                          : Column(
                              children: [
                                for (final reason in reasons)
                                  _buildReason(
                                    strings.recommendationReason(
                                      reason,
                                      sharedCount: sharedCount,
                                      forProfile: true,
                                    ),
                                  ),
                              ],
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: CareLinkTheme.surfaceColor,
            border: Border(top: BorderSide(color: _chipBorderColor)),
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
                          builder: (_) => SendMatchRequestScreen(
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
                      strings.sendMatchRequest,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _careLinkTeal,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      strings.backToRecommendations,
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

  Widget _buildProfileHeader(BuildContext context, CompanionStrings strings) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CompanionAvatar(
                name: profile.name,
                size: 84,
                imagePath: profile.imagePath,
                heroTag: 'companion-avatar-${profile.id}',
              ),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall,
                ),
              ),
              if (profile.verified) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _careLinkTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: _careLinkTeal,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          strings.verifiedStudentCompanion,
                          style: const TextStyle(
                            color: _careLinkTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    bool highlighted = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: highlighted ? CompanionPalette.mint : null,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? _careLinkCoral.withValues(alpha: 0.12)
            : CareLinkTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? _careLinkCoral : _chipBorderColor,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CareLinkTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildReason(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: _careLinkTeal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 14,
                color: CareLinkTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
