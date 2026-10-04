import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/carelink_brand_header.dart';
import 'request_pending_screen.dart';

class SendMatchRequestScreen extends StatelessWidget {
  const SendMatchRequestScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);
  static const Color _borderColor = Color(0xFFE7E0EC);

  void _onSendRequest(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RequestPendingScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
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
                        tooltip: strings.cancel,
                        color: _careLinkTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: const CareLinkBrandHeader()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      strings.sendMatchRequest,
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.requestReviewSubtitle,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _buildCompanionCard(context, strings),
                  const SizedBox(height: 16),
                  _buildNotice(context, strings),
                  const SizedBox(height: 16),
                  _buildPrivacyCard(
                    context,
                    title: strings.informationShared,
                    items: [
                      strings.firstName,
                      strings.approvedInterests,
                      strings.preferredLanguage,
                    ],
                    isShared: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacyCard(
                    context,
                    title: strings.notShared,
                    items: [
                      strings.phoneNumber,
                      strings.homeAddress,
                      strings.privateConversationContent,
                    ],
                    isShared: false,
                  ),
                ],
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
                    onPressed: () => _onSendRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _careLinkTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      strings.reviewSendRequest,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _careLinkTeal,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(strings.cancel),
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
    final initials = profile.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: _careLinkCoral.withValues(alpha: 0.16),
              child: Text(
                initials,
                style: const TextStyle(
                  color: _careLinkTeal,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: textTheme.titleMedium),
                  if (profile.verified) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 17,
                          color: _careLinkTeal,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            strings.verified,
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
      ),
    );
  }

  Widget _buildNotice(BuildContext context, CompanionStrings strings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _careLinkTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _careLinkTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.connectionRequestMessage,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: CareLinkTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(
    BuildContext context, {
    required String title,
    required List<String> items,
    required bool isShared,
  }) {
    return Card(
      margin: EdgeInsets.zero,
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
              const SizedBox(height: 14),
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                _buildPrivacyItem(items[index], title, isShared: isShared),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyItem(
    String label,
    String sectionTitle, {
    required bool isShared,
  }) {
    return Semantics(
      label: '$label, $sectionTitle',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isShared ? Icons.check_circle_outline : Icons.block_outlined,
              color: isShared ? _careLinkTeal : _careLinkCoral,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: CareLinkTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
