// Keep the existing `profile:` route argument while using controller state.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../controllers/companion_controller.dart';
import '../models/companion_connection.dart';
import '../models/companion_language.dart';
import '../models/companion_match.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'current_connection_screen.dart';

/// W08C: pausing keeps the connection; only Resume returns it to Active.
class ConnectionPausedScreen extends StatelessWidget {
  const ConnectionPausedScreen({
    super.key,
    required CompanionProfile profile,
    required this.selectedLanguage,
    required this.connectionStatus,
    this.controller,
  }) : _profile = profile,
       assert(connectionStatus == MatchStatus.paused);

  final CompanionProfile _profile;
  CompanionProfile get profile => controller?.selectedCompanion ?? _profile;
  final CompanionLanguage selectedLanguage;
  final MatchStatus connectionStatus;
  final CompanionController? controller;

  static const Color _amberInk = Color(0xFF9A6200);

  Future<void> _openConnection(
    BuildContext context,
    MatchStatus nextStatus,
  ) async {
    if (nextStatus == MatchStatus.accepted && controller != null) {
      if (controller!.isLoading) return;
      await controller!.resumeCurrentConnection();
      if (!context.mounted) return;
      if (controller!.errorMessage != null ||
          controller!.currentConnection?.status != ConnectionStatus.active) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              CompanionStrings(selectedLanguage).connectionUpdateError,
            ),
          ),
        );
        return;
      }
    }
    Navigator.of(context).pushAndRemoveUntil(
      CompanionRoute<void>(
        context: context,
        builder: (_) => CurrentConnectionScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          connectionStatus: nextStatus,
          controller: controller,
        ),
      ),
      // Discard older Active screens. W02 remains as the companion-flow base.
      (route) => route.settings.name == '/companion-recommendations',
    );
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
    final motionDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    // System Back cannot uncover the older Active route underneath W08C.
    // The visible actions explicitly carry the chosen status to W07.
    return PopScope(
      canPop: false,
      child: CompanionScaffold(
        body: SafeArea(
          child: CompanionEntrance(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompanionFlowHeader(
                        onBack: () =>
                            _openConnection(context, MatchStatus.paused),
                        backTooltip: strings.backToConnection,
                        trailingIcon: null,
                        showCoralDot: true,
                      ),
                      const SizedBox(height: 18),
                      Semantics(
                        header: true,
                        child: Text(
                          strings.connectionPaused,
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 27,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        strings.pausedActivitySubtitle,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CompanionPalette.coral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Column(
                          children: [
                            _buildPausedIllustration(context),
                            const SizedBox(height: 6),
                            Text(
                              profile.name,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            AnimatedContainer(
                              duration: motionDuration,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: CompanionPalette.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 9,
                                    color: _amberInk,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      strings.paused,
                                      style: const TextStyle(
                                        color: _amberInk,
                                        fontSize: 12,
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
                      const SizedBox(height: 34),
                      _buildMeaningCard(context, strings),
                      const SizedBox(height: 38),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller?.isLoading == true
                              ? null
                              : () => _openConnection(
                                  context,
                                  MatchStatus.accepted,
                                ),
                          child: Text(
                            strings.resumeConnection,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              _openConnection(context, MatchStatus.paused),
                          child: Text(
                            strings.backToConnection,
                            textAlign: TextAlign.center,
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
      ),
    );
  }

  Widget _buildPausedIllustration(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(opacity: scale, child: child),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 166,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Center(
                  child: CompanionAvatar(
                    name: profile.name,
                    size: 116,
                    imagePath: profile.imagePath,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: ExcludeSemantics(
                child: Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD16E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    color: _amberInk,
                    size: 35,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 13,
              top: 65,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.favorite,
                  color: CompanionPalette.coral,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeaningCard(BuildContext context, CompanionStrings strings) {
    final textTheme = Theme.of(context).textTheme;
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
                  strings.whatThisMeans,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.pausedMeaning,
                style: textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
