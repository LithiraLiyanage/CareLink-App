import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_avatar.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/carelink_brand_header.dart';
import 'companion_profile_screen.dart';

class RecommendedCompanionsScreen extends StatelessWidget {
  const RecommendedCompanionsScreen({
    super.key,
    required this.selectedLanguage,
  });

  final CompanionLanguage selectedLanguage;

  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);

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
      imagePath: '',
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CareLinkBrandHeader(large: true),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.recommendedCompanions,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.recommendationSubtitle,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.tune, size: 20),
                      label: Text(strings.adjustPreferences),
                      style: TextButton.styleFrom(
                        foregroundColor: _careLinkTeal,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CompanionEntrance(
                      child: _buildFeaturedCard(
                        context,
                        strings,
                        featuredProfile,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CompanionEntrance(
                      delay: const Duration(milliseconds: 55),
                      child: _buildSmallCard(context, strings, 'Amaya Perera'),
                    ),
                    const SizedBox(height: 14),
                    CompanionEntrance(
                      delay: const Duration(milliseconds: 110),
                      child: _buildSmallCard(context, strings, 'Kavindu Silva'),
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
          onDestinationSelected: (index) {
            if (index != 1) {
              _showPlaceholder(context, strings.navigationComingSoon);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    CompanionStrings strings,
    CompanionProfile profile,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CompanionAvatar(
                  name: profile.name,
                  size: 64,
                  imagePath: profile.imagePath,
                  heroTag: 'companion-${profile.id}',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (profile.verified) _buildVerifiedBadge(strings),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildDetailRow(Icons.translate, strings.spokenLanguages),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.schedule_outlined, strings.sundayEvenings),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInterestChip(strings.gardening),
                _buildInterestChip(strings.music),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildReason(strings.sameLanguage),
                  _buildReason(strings.twoSharedInterests),
                  _buildReason(strings.availableAtPreferredTime),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                    foregroundColor: _careLinkTeal,
                    side: const BorderSide(color: _careLinkTeal),
                  ),
                  child: Text(strings.viewProfile, textAlign: TextAlign.center),
                );
                final requestButton = ElevatedButton(
                  onPressed: () =>
                      _showPlaceholder(context, strings.requestComingSoon),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _careLinkTeal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(strings.sendRequest, textAlign: TextAlign.center),
                );

                if (constraints.maxWidth < 460) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      profileButton,
                      const SizedBox(height: 10),
                      requestButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: profileButton),
                    const SizedBox(width: 12),
                    Expanded(child: requestButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(
    BuildContext context,
    CompanionStrings strings,
    String name,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CompanionAvatar(name: name, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(
                    strings.verifiedStudent,
                    style: textTheme.bodySmall?.copyWith(color: _careLinkTeal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge(CompanionStrings strings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _careLinkTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, size: 17, color: _careLinkTeal),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              strings.verifiedStudent,
              style: const TextStyle(
                color: _careLinkTeal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _careLinkTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: CareLinkTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _careLinkCoral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 19,
            color: _careLinkTeal,
          ),
          const SizedBox(width: 9),
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
