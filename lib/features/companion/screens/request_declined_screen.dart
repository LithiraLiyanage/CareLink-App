import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/carelink_brand_header.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'recommended_companions_screen.dart';

/// W06B: a declined request never creates an active connection.
class RequestDeclinedScreen extends StatelessWidget {
  const RequestDeclinedScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  static const MatchStatus status = MatchStatus.declined;

  void _returnToRecommendations(BuildContext context) {
    final navigator = Navigator.of(context);
    final fallbackRoute = CompanionRoute<void>(
      context: context,
      settings: const RouteSettings(name: '/companion-recommendations'),
      builder: (_) =>
          RecommendedCompanionsScreen(selectedLanguage: selectedLanguage),
    );
    var foundRecommendations = false;

    // W05 was replaced by W06B. Remove any remaining profile/request routes
    // so Back cannot reveal the declined request as Pending.
    navigator.popUntil((route) {
      if (route.settings.name == '/companion-recommendations') {
        foundRecommendations = true;
        return true;
      }
      return route.isFirst;
    });

    // Direct previews may not have a W02 route underneath this screen.
    if (!foundRecommendations) navigator.pushReplacement(fallbackRoute);
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final motionDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return CompanionScaffold(
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
                    const CareLinkBrandHeader(),
                    const SizedBox(height: 28),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.requestNotAccepted,
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.requestDeclinedMessage,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CompanionAvatar(
                              name: profile.name,
                              size: 76,
                              imagePath: profile.imagePath,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              profile.name,
                              style: textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            AnimatedContainer(
                              duration: motionDuration,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: CompanionPalette.coral.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: CompanionPalette.coral.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cancel_outlined,
                                    size: 19,
                                    color: CompanionPalette.ink,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      strings.declined,
                                      style: const TextStyle(
                                        color: CompanionPalette.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      color: CompanionPalette.mint,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: CompanionPalette.teal,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                strings.declinedPrivacyMessage,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => _returnToRecommendations(context),
                    child: Text(
                      strings.findAnotherCompanion,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _returnToRecommendations(context),
                    child: Text(
                      strings.backToMatches,
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
}
