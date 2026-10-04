import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'connection_accepted_screen.dart';
import 'request_declined_screen.dart';

class RequestPendingScreen extends StatelessWidget {
  const RequestPendingScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  static const Color _amber = Color(0xFFEC9E00);
  static const Color _amberInk = Color(0xFF9A6200);
  static const Color _green = Color(0xFF2F855F);
  static const Color _mutedStep = Color(0xFF8DB0B1);

  void _backToMatches(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) =>
          route.settings.name == '/companion-recommendations' || route.isFirst,
    );
  }

  void _simulateAccept(BuildContext context) {
    Navigator.of(context).pushReplacement(
      CompanionRoute<void>(
        context: context,
        builder: (_) => ConnectionAcceptedScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
        ),
      ),
    );
  }

  void _simulateDecline(BuildContext context) {
    Navigator.of(context).pushReplacement(
      CompanionRoute<void>(
        context: context,
        builder: (_) => RequestDeclinedScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final textTheme = CompanionScaffold.textTheme(context);
    final firstName = profile.name.split(' ').first;

    return CompanionScaffold(
      body: SafeArea(
        bottom: false,
        child: CompanionEntrance(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanionFlowHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      backTooltip: strings.backToMatches,
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.matchRequest,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 27,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.matchingRequiresAgreement,
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
                    const SizedBox(height: 4),
                    _buildIdentity(context, strings),
                    const SizedBox(height: 12),
                    _buildSentNotice(context, strings, firstName),
                    const SizedBox(height: 18),
                    _buildProgress(context, strings),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: CompanionPalette.background,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Development-only response simulation; no backend request is sent.
                  Text(
                    strings.developmentOnly,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 11, color: CompanionPalette.muted),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _simulateAccept(context),
                    child: Text(
                      strings.simulateAccept,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBottomActions(context, strings),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, CompanionStrings strings) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        children: [
          CompanionAvatar(
            name: profile.name,
            size: 76,
            imagePath: profile.imagePath,
          ),
          const SizedBox(height: 8),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: CompanionPalette.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 9, color: _amber),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    strings.pending,
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
    );
  }

  Widget _buildSentNotice(
    BuildContext context,
    CompanionStrings strings,
    String firstName,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD88C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.yourRequestSent,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _amberInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.waitingForCompanion(firstName),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: _amberInk, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, CompanionStrings strings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              strings.requestProgress,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          _buildProgressStep(
            context,
            title: strings.requestSentStep,
            status: strings.completed,
            number: '1',
            color: _green,
            completed: true,
          ),
          _buildConnector(),
          _buildProgressStep(
            context,
            title: strings.waitingForResponse,
            status: strings.inProgress,
            number: '2',
            color: _amber,
          ),
          _buildConnector(),
          _buildProgressStep(
            context,
            title: strings.connectionDecision,
            status: strings.pending,
            number: '3',
            color: _mutedStep,
            trailing: TextButton.icon(
              // Development-only declined response preview.
              onPressed: () => _simulateDecline(context),
              style: TextButton.styleFrom(
                foregroundColor: CompanionPalette.coral,
                minimumSize: const Size(0, 44),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              label: Text(strings.simulateDecline),
              icon: const Icon(Icons.arrow_forward, size: 15),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(width: 2, height: 14, color: CompanionPalette.border),
    );
  }

  Widget _buildProgressStep(
    BuildContext context, {
    required String title,
    required String status,
    required String number,
    required Color color,
    bool completed = false,
    Widget? trailing,
  }) {
    return Semantics(
      label: '$title: $status',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.94, end: 1),
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: completed
                  ? Icon(Icons.check, size: 18, color: color)
                  : Text(
                      number,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: completed ? _green : CompanionPalette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, CompanionStrings strings) {
    final cancelButton = OutlinedButton(
      onPressed: () => Navigator.of(context).maybePop(),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB43F42),
        side: const BorderSide(color: Color(0xFFB43F42), width: 1.5),
        minimumSize: const Size(0, 48),
      ),
      child: Text(strings.cancelRequest, textAlign: TextAlign.center),
    );
    final matchesButton = OutlinedButton(
      onPressed: () => _backToMatches(context),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(strings.backToMatches, textAlign: TextAlign.center),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactEnglish =
            selectedLanguage == CompanionLanguage.english &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.2 &&
            constraints.maxWidth >= 320;
        if (!compactEnglish) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [cancelButton, const SizedBox(height: 8), matchesButton],
          );
        }
        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: 10),
            Expanded(child: matchesButton),
          ],
        );
      },
    );
  }
}
