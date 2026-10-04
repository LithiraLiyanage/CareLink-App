import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/carelink_brand_header.dart';
import 'connection_accepted_screen.dart';

class RequestPendingScreen extends StatelessWidget {
  const RequestPendingScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);
  static const Color _borderColor = Color(0xFFE7E0EC);

  void _backToMatches(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) =>
          route.settings.name == '/companion-recommendations' || route.isFirst,
    );
  }

  void _showSimulationPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = Theme.of(context).textTheme;
    final firstName = profile.name.split(' ').first;

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
                  const CareLinkBrandHeader(),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      strings.matchRequest,
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.matchingRequiresAgreement,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _buildRequestCard(context, strings, firstName),
                  const SizedBox(height: 16),
                  _buildProgressCard(context, strings),
                  const SizedBox(height: 16),
                  _buildDevelopmentControls(context, strings),
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
                    onPressed: () => _backToMatches(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _careLinkTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      strings.backToMatches,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: TextButton.styleFrom(
                      foregroundColor: CareLinkTheme.errorColor,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      strings.cancelRequest,
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

  Widget _buildRequestCard(
    BuildContext context,
    CompanionStrings strings,
    String firstName,
  ) {
    final initials = profile.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
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
                    child: Text(profile.name, style: textTheme.titleLarge),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _careLinkCoral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_top_outlined,
                      size: 18,
                      color: _careLinkCoral,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        strings.pending,
                        style: const TextStyle(
                          color: CareLinkTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(strings.yourRequestSent, style: textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                strings.waitingForCompanion(firstName),
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, CompanionStrings strings) {
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  strings.requestProgress,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              _buildProgressStep(
                title: strings.requestSentStep,
                status: strings.completed,
                icon: Icons.check_circle_outline,
                color: _careLinkTeal,
              ),
              const Divider(height: 22),
              _buildProgressStep(
                title: strings.waitingForResponse,
                status: strings.inProgress,
                icon: Icons.hourglass_top_outlined,
                color: _careLinkCoral,
              ),
              const Divider(height: 22),
              _buildProgressStep(
                title: strings.connectionDecision,
                status: strings.pending,
                icon: Icons.radio_button_unchecked,
                color: CareLinkTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required String title,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Semantics(
      label: '$title: $status',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CareLinkTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CareLinkTheme.textPrimary,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDevelopmentControls(
    BuildContext context,
    CompanionStrings strings,
  ) {
    // Development-only simulation controls; W06B is not implemented yet.
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.developmentOnly,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => ConnectionAcceptedScreen(
                        profile: profile,
                        selectedLanguage: selectedLanguage,
                      ),
                    ),
                  );
                },
                style: _developmentButtonStyle(),
                child: Text(
                  strings.simulateAccept,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                // TODO: Navigate to W06B Request Declined.
                onPressed: () => _showSimulationPlaceholder(
                  context,
                  strings.declinedScreenComingSoon,
                ),
                style: _developmentButtonStyle(),
                child: Text(
                  strings.simulateDecline,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _developmentButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: CareLinkTheme.textSecondary,
      side: const BorderSide(color: _borderColor),
      minimumSize: const Size(double.infinity, 48),
    );
  }
}
