// Keep the existing `profile:` route argument while using controller state.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../controllers/companion_controller.dart';
import '../models/companion_connection.dart';
import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'recommended_companions_screen.dart';

/// W08B: the connection keeps its current state until End is explicitly tapped.
class EndConnectionConfirmationScreen extends StatelessWidget {
  const EndConnectionConfirmationScreen({
    super.key,
    required CompanionProfile profile,
    required this.selectedLanguage,
    this.connectionStatus = MatchStatus.accepted,
    this.controller,
  }) : _profile = profile,
       assert(
         connectionStatus == MatchStatus.accepted ||
             connectionStatus == MatchStatus.paused,
       );

  final CompanionProfile _profile;
  CompanionProfile get profile => controller?.selectedCompanion ?? _profile;
  final CompanionLanguage selectedLanguage;
  final MatchStatus connectionStatus;
  final CompanionController? controller;

  bool get _isPaused => controller == null
      ? connectionStatus == MatchStatus.paused
      : controller?.currentConnection?.status == ConnectionStatus.paused;

  Future<void> _endConnection(
    BuildContext context,
    CompanionStrings strings,
  ) async {
    if (controller != null) {
      if (controller!.isLoading) return;
      await controller!.endCurrentConnection();
      if (!context.mounted) return;
      if (controller!.errorMessage != null ||
          controller!.currentConnection?.status != ConnectionStatus.ended) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.connectionUpdateError)));
        return;
      }
    }
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var foundRecommendations = false;

    // Remove stale connection routes so Back cannot reveal a former Active UI.
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
    final currentController = controller;
    if (currentController == null) return _build(context);
    return ListenableBuilder(
      listenable: currentController,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final firstName = profile.firstName;
    // W08 remains visible behind the transparent route. A direct preview still
    // shows the companion summary because no W08 route is underneath it.
    final standalone = ModalRoute.of(context)?.opaque ?? true;

    return Material(
      color: standalone ? CompanionPalette.background : Colors.transparent,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  color: Colors.white,
                  elevation: 10,
                  shadowColor: CompanionPalette.ink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(23),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        height: 4,
                        child: ColoredBox(color: CompanionPalette.coral),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: controller?.isLoading == true
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                tooltip: strings.keepConnection,
                                icon: const Icon(Icons.close, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: CompanionPalette.mint,
                                  foregroundColor: CompanionPalette.muted,
                                  minimumSize: const Size(44, 44),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 66,
                              height: 66,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: CompanionPalette.coral.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: CareLinkTheme.errorColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Semantics(
                              header: true,
                              child: Text(
                                strings.endThisConnection,
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              strings.endConnectionDescription(firstName),
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            if (standalone) ...[
                              const SizedBox(height: 12),
                              Text(
                                profile.name,
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isPaused
                                        ? Icons.pause_circle_outline
                                        : Icons.check_circle_outline,
                                    color: CompanionPalette.teal,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _isPaused
                                          ? strings.paused
                                          : strings.currentConnectionActive,
                                      style: textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 7),
                            Text(
                              strings.companionSince,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: controller?.isLoading == true
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: CompanionPalette.teal,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(
                                  strings.keepConnection,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            SizedBox(
                              width: double.infinity,
                              child: Semantics(
                                hint: strings.endThisConnection,
                                child: OutlinedButton.icon(
                                  onPressed: controller?.isLoading == true
                                      ? null
                                      : () => _endConnection(context, strings),
                                  icon: const Icon(Icons.link_off, size: 18),
                                  label: Text(
                                    strings.endConnection,
                                    textAlign: TextAlign.center,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    foregroundColor: CareLinkTheme.errorColor,
                                    side: const BorderSide(
                                      color: CareLinkTheme.errorColor,
                                      width: 1.4,
                                    ),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
