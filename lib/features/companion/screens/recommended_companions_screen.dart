import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'companion_profile_screen.dart';

class RecommendedCompanionsScreen extends StatelessWidget {
  const RecommendedCompanionsScreen({
    super.key,
    required this.selectedLanguage,
  });

  final CompanionLanguage selectedLanguage;

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final featuredProfile = CompanionProfile(
      id: 'nethmi-jayasooriya',
      name: 'Nethmi Jayasooriya',
      imagePath: 'assets/images/companion_nethmi.png',
      verified: true,
      languages: const ['Sinhala', 'English', 'Tamil'],
      interests: [strings.gardening, strings.music, strings.traditionalFood],
      availability: strings.sundayAvailability,
      about: strings.volunteerAbout,
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
                    const SizedBox(height: 12),
                    CompanionEntrance(
                      delay: const Duration(milliseconds: 55),
                      child: _buildSmallCard(
                        context,
                        strings,
                        name: 'Amaya Perera',
                        imagePath: 'assets/images/companion_amaya.png',
                        metadata: strings.amayaRecommendationDetails,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CompanionEntrance(
                      delay: const Duration(milliseconds: 110),
                      child: _buildSmallCard(
                        context,
                        strings,
                        name: 'Kavindu Silva',
                        imagePath: 'assets/images/companion_kavindu.png',
                        metadata: strings.kavinduRecommendationDetails,
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
                        heroTag: 'companion-${profile.id}',
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
                    '${strings.spokenLanguages} • ${strings.sundayEvenings}',
                    style: textTheme.bodySmall?.copyWith(
                      color: CompanionPalette.muted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInterestChip(strings.gardening, Icons.spa_outlined),
                      _buildInterestChip(strings.music, Icons.music_note),
                    ],
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
                        if (compactEnglish)
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildCompactReason(strings.sameLanguage),
                              _buildCompactReason(strings.twoSharedInterests),
                            ],
                          )
                        else ...[
                          _buildReason(strings.sameLanguage),
                          _buildReason(strings.twoSharedInterests),
                        ],
                        _buildReason(strings.availableAtPreferredTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final profileButton = OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            CompanionRoute<void>(
                              context: context,
                              builder: (_) => CompanionProfileScreen(
                                profile: profile,
                                selectedLanguage: selectedLanguage,
                              ),
                            ),
                          );
                        },
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
                        onPressed: () => _showPlaceholder(
                          context,
                          strings.requestComingSoon,
                        ),
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
    required String name,
    required String imagePath,
    required String metadata,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CompanionAvatar(name: name, size: 48, imagePath: imagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildVerifiedBadge(strings.verified),
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
          ],
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

  Widget _buildCompactReason(String reason) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check, size: 15, color: CompanionPalette.teal),
        const SizedBox(width: 3),
        Text(
          reason,
          style: const TextStyle(fontSize: 12.5, color: CompanionPalette.teal),
        ),
      ],
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
