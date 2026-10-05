import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../models/match_preferences.dart';
import '../services/companion_recommendations.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_interest_icon.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'companion_profile_screen.dart';
import 'send_match_request_screen.dart';

class RecommendedCompanionsScreen extends StatelessWidget {
  const RecommendedCompanionsScreen({
    super.key,
    required this.selectedLanguage,
    this.preferences,
  });

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

  void _openProfile(BuildContext context, CompanionProfile profile) {
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        builder: (_) => CompanionProfileScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          preferences: _effectivePreferences,
        ),
      ),
    );
  }

  void _openRequest(BuildContext context, CompanionProfile profile) {
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        builder: (_) => SendMatchRequestScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final profiles = CompanionRecommendations.ordered(_effectivePreferences);
    final featuredProfile = profiles.first;

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
                    _buildHeader(context, strings),
                    const SizedBox(height: 18),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.recommendedCompanions,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 27,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.recommendationSubtitle,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CompanionPalette.coral,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: TextButton.styleFrom(
                                foregroundColor: CompanionPalette.teal,
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              child: Text(
                                '${strings.adjustPreferences} →',
                                textAlign: TextAlign.end,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CompanionEntrance(
                      child: _buildFeaturedCard(
                        context,
                        strings,
                        featuredProfile,
                      ),
                    ),
                    for (var index = 1; index < profiles.length; index++) ...[
                      const SizedBox(height: 12),
                      CompanionEntrance(
                        delay: Duration(milliseconds: 55 * index),
                        child: _buildSmallCard(
                          context,
                          strings,
                          profile: profiles[index],
                        ),
                      ),
                    ],
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

  Widget _buildHeader(BuildContext context, CompanionStrings strings) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: strings.adjustPreferences,
          icon: const Icon(Icons.chevron_left),
          color: CompanionPalette.teal,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: CompanionPalette.border),
          ),
        ),
        Expanded(
          child: Center(
            child: Semantics(
              label: 'CareLink',
              child: ExcludeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 3,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CompanionPalette.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      'CareLink',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CompanionPalette.teal,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: CompanionPalette.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Decorative only until the notifications flow is connected.
        ExcludeSemantics(
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: CompanionPalette.border),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: CompanionPalette.teal,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    CompanionStrings strings,
    CompanionProfile profile,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final compactEnglish =
        selectedLanguage == CompanionLanguage.english &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.2;
    final reasons = CompanionRecommendations.reasonsFor(
      profile,
      _effectivePreferences,
    );
    final sharedCount = CompanionRecommendations.sharedInterestCount(
      profile,
      _effectivePreferences,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        size: 58,
                        imagePath: profile.imagePath,
                        heroTag: 'companion-avatar-${profile.id}',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (profile.verified) ...[
                              const SizedBox(height: 5),
                              _buildVerifiedBadge(strings.verifiedStudent),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${profile.languages.join(', ')} • ${strings.profileAvailability(profile, short: true)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: CompanionPalette.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests
                        .take(2)
                        .map(
                          (interest) => _buildInterestChip(
                            strings.interestLabel(interest),
                            companionInterestIcon(interest),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CompanionPalette.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            strings.whyThisMatch,
                            style: textTheme.titleMedium?.copyWith(
                              color: CompanionPalette.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (reasons.isEmpty)
                          Text(
                            strings.noPreferenceOverlap,
                            style: textTheme.bodySmall,
                          )
                        else
                          for (final reason in reasons)
                            _buildReason(
                              strings.recommendationReason(
                                reason,
                                sharedCount: sharedCount,
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final profileButton = OutlinedButton(
                        onPressed: () => _openProfile(context, profile),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CompanionPalette.teal,
                          side: const BorderSide(
                            color: CompanionPalette.teal,
                            width: 1.5,
                          ),
                          minimumSize: const Size(0, 48),
                        ),
                        child: Text(
                          strings.viewProfile,
                          textAlign: TextAlign.center,
                        ),
                      );
                      final requestButton = ElevatedButton(
                        onPressed: () => _openRequest(context, profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CompanionPalette.teal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                        ),
                        child: Text(
                          strings.sendRequest,
                          textAlign: TextAlign.center,
                        ),
                      );

                      if (!compactEnglish || constraints.maxWidth < 300) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            profileButton,
                            const SizedBox(height: 8),
                            requestButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: profileButton),
                          const SizedBox(width: 10),
                          Expanded(child: requestButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context,
    CompanionStrings strings, {
    required CompanionProfile profile,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final metadata = [
      if (profile.languages.isNotEmpty) profile.languages.first,
      if (profile.interests.isNotEmpty)
        strings.interestLabel(profile.interests.first),
      strings.profileAvailability(profile, short: true),
    ].join(' • ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '${strings.viewProfile}: ${profile.name}',
        child: InkWell(
          onTap: () => _openProfile(context, profile),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CompanionAvatar(
                  name: profile.name,
                  size: 48,
                  imagePath: profile.imagePath,
                  heroTag: 'companion-avatar-${profile.id}',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(height: 4),
                        _buildVerifiedBadge(strings.verified),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        metadata,
                        softWrap: true,
                        style: textTheme.bodySmall?.copyWith(
                          color: CompanionPalette.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: CompanionPalette.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: CompanionPalette.mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: CompanionPalette.teal),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: CompanionPalette.teal,
                fontSize: 12,
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
        border: Border.all(color: CompanionPalette.coral, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: CompanionPalette.coral),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: const TextStyle(
                color: CompanionPalette.coral,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReason(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 15, color: CompanionPalette.teal),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 12.5,
                color: CompanionPalette.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
