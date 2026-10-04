import 'package:flutter/material.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';
import '../widgets/companion_entrance.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import 'recommended_companions_screen.dart';

/// W08B: the connection stays active unless End Connection is explicitly tapped.
class EndConnectionConfirmationScreen extends StatelessWidget {
  const EndConnectionConfirmationScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  static const Color _teal = Color(0xFF087F83);

  void _endConnection(BuildContext context, CompanionStrings strings) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var foundRecommendations = false;

    // This mock flow has no backend state. Remove every Active screen from
    // the stack and return to the existing W02 route, preserving its language.
    navigator.popUntil((route) {
      if (route.settings.name == '/companion-recommendations') {
        foundRecommendations = true;
        return true;
      }
      return route.isFirst;
    });

    // Also support opening W08B directly during development or widget tests.
    if (!foundRecommendations) {
      navigator.pushAndRemoveUntil(
        CompanionRoute<void>(
          context: context,
          settings: const RouteSettings(name: '/companion-recommendations'),
          builder: (_) =>
              RecommendedCompanionsScreen(selectedLanguage: selectedLanguage),
        ),
        (_) => false,
      );
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.connectionEnded)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final firstName = profile.name.trim().split(RegExp(r'\s+')).first;

    return CompanionScaffold(
      appBar: AppBar(title: const Text('CareLink')),
      body: CompanionEntrance(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        strings.manageConnectionTitle,
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.confirmationProtects,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name, style: textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: CareLinkTheme.successColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    strings.currentConnectionActive,
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strings.companionSince,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      color: CompanionPalette.coral.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: CareLinkTheme.errorColor,
                                  size: 26,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      strings.endThisConnection,
                                      style: textTheme.titleLarge,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strings.endConnectionDescription(firstName),
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.favorite_outline),
                      label: Text(
                        strings.keepConnection,
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      hint: strings.endThisConnection,
                      child: OutlinedButton.icon(
                        onPressed: () => _endConnection(context, strings),
                        icon: const Icon(Icons.link_off),
                        label: Text(
                          strings.endConnection,
                          textAlign: TextAlign.center,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CareLinkTheme.errorColor,
                          side: const BorderSide(
                            color: CareLinkTheme.errorColor,
                          ),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
