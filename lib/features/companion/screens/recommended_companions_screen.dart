import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_strings.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandHeader(),
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
                  _buildFeaturedCard(context, strings),
                  const SizedBox(height: 14),
                  _buildSmallCard(context, strings, 'Amaya Perera', 'AP'),
                  const SizedBox(height: 14),
                  _buildSmallCard(context, strings, 'Kavindu Silva', 'KS'),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          selectedIndex: 1,
          backgroundColor: CareLinkTheme.surfaceColor,
          indicatorColor: _careLinkCoral.withValues(alpha: 0.16),
          onDestinationSelected: (index) {
            if (index != 1) {
              _showPlaceholder(context, strings.navigationComingSoon);
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: strings.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: const Icon(Icons.people, color: _careLinkTeal),
              label: strings.matches,
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_outlined),
              selectedIcon: const Icon(Icons.event, color: _careLinkTeal),
              label: strings.checkIns,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Semantics(
      container: true,
      label: 'CareLink',
      child: ExcludeSemantics(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/carelink_logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Care',
                    style: TextStyle(color: _careLinkTeal),
                  ),
                  TextSpan(
                    text: 'Link',
                    style: TextStyle(color: _careLinkCoral),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, CompanionStrings strings) {
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
                _buildAvatar('NJ', size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nethmi Jayasooriya', style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _buildVerifiedBadge(strings),
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
            const Divider(height: 1),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(strings.whyThisMatch, style: textTheme.titleMedium),
            ),
            const SizedBox(height: 10),
            _buildReason(strings.sameLanguage),
            _buildReason(strings.twoSharedInterests),
            _buildReason(strings.availableAtPreferredTime),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final profileButton = OutlinedButton(
                  onPressed: () =>
                      _showPlaceholder(context, strings.profileComingSoon),
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
    String initials,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(initials, size: 48),
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

  Widget _buildAvatar(String initials, {required double size}) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _careLinkCoral.withValues(alpha: 0.16),
      child: Text(
        initials,
        style: TextStyle(
          color: _careLinkTeal,
          fontSize: size * 0.3,
          fontWeight: FontWeight.w700,
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
