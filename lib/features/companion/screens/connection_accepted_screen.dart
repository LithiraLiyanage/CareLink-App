// ignore_for_file: prefer_initializing_formals
// Keep the public `profile:` parameter while storing a private fallback.

import 'dart:ui' show ImageFilter, TileMode;

import 'package:flutter/material.dart';

import '../controllers/companion_controller.dart';

import '../models/companion_connection.dart';

import '../models/companion_language.dart';

import '../models/companion_profile.dart';

import '../models/companion_strings.dart';

import '../widgets/companion_avatar.dart';

import '../widgets/companion_entrance.dart';

import '../widgets/companion_interest_icon.dart';

import '../widgets/companion_route.dart';

import '../widgets/companion_scaffold.dart';

import 'current_connection_screen.dart';

import 'scheduling_handoff_screen.dart';

class ConnectionAcceptedScreen extends StatelessWidget {
  const ConnectionAcceptedScreen({
    super.key,

    required CompanionProfile profile,

    required this.selectedLanguage,

    this.controller,
  }) : _profile = profile;

  final CompanionProfile _profile;

  final CompanionLanguage selectedLanguage;

  final CompanionController? controller;

  CompanionProfile get profile => controller?.selectedCompanion ?? _profile;

  // ============================================

  // FIGMA COLORS

  // ============================================

  static const Color _darkTeal = Color(0xFF173F42);

  static const Color _teal = Color(0xFF096A6C);

  static const Color _mint = Color(0xFFE9F8F4);

  static const Color _coral = Color(0xFFFF655F);

  static const Color _muted = Color(0xFF617C7B);

  static const Color _border = Color(0xFFD6EBE5);

  @override
  Widget build(BuildContext context) {
    final currentController = controller;

    if (currentController == null) {
      return _buildContent(context);
    }

    return ListenableBuilder(
      listenable: currentController,

      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);

    final connectionIsActive =
        controller == null ||
        controller?.currentConnection?.status == ConnectionStatus.active;

    return CompanionScaffold(
      body: Stack(
        fit: StackFit.expand,

        children: [
          // ======================================

          // FULL SCREEN BLURRED BACKGROUND

          // ======================================
          const Positioned.fill(child: _BlurredConnectionBackground()),

          // ======================================

          // FOREGROUND CONTENT

          // ======================================
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),

                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),

                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),

                          padding: const EdgeInsets.only(top: 14, bottom: 20),

                          child: CompanionEntrance(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                _buildHeader(context),

                                const SizedBox(height: 32),

                                _buildHeading(strings),

                                const SizedBox(height: 31),

                                _buildCompanionCard(strings),

                                const SizedBox(height: 28),

                                _buildAgreementPanel(strings),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Buttons stay on the same

                      // blurred background, not on

                      // a separate white footer.
                      _buildBottomButtons(context, strings, connectionIsActive),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================

  // TOP HEADER

  // ============================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _roundButton(
          icon: Icons.chevron_left_rounded,

          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),

        const Spacer(),

        Container(
          width: 35,

          height: 35,

          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: _teal,

            borderRadius: BorderRadius.circular(11),

            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.16),

                blurRadius: 10,

                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: const Text(
            'C',

            style: TextStyle(
              color: Colors.white,

              fontSize: 17,

              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(width: 9),

        const Text(
          'CareLink',

          style: TextStyle(
            color: _darkTeal,

            fontSize: 18,

            fontWeight: FontWeight.w900,
          ),
        ),

        const Spacer(),

        _roundButton(
          icon: Icons.celebration_outlined,

          iconColor: _coral,

          onPressed: null,
        ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,

    required VoidCallback? onPressed,

    Color iconColor = _teal,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.93),

      shape: const CircleBorder(),

      child: InkWell(
        onTap: onPressed,

        customBorder: const CircleBorder(),

        child: Container(
          width: 45,

          height: 45,

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(color: _border),
          ),

          child: Icon(icon, color: iconColor, size: 25),
        ),
      ),
    );
  }

  // ============================================

  // CONNECTION ACCEPTED HEADING

  // ============================================

  Widget _buildHeading(CompanionStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Semantics(
          header: true,

          child: Text(
            strings.connectionAccepted,

            style: const TextStyle(
              color: _darkTeal,

              fontSize: 31,

              fontWeight: FontWeight.w900,

              height: 1.08,

              letterSpacing: -0.6,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 4,

          width: 40,

          decoration: BoxDecoration(
            color: _coral,

            borderRadius: BorderRadius.circular(8),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Text(
                strings.youAndCompanionConnected(profile.firstName),

                style: const TextStyle(
                  color: _muted,

                  fontSize: 14,

                  height: 1.5,

                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(width: 9),

            Transform.rotate(
              angle: -0.10,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,

                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F4).withValues(alpha: 0.95),

                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(color: _coral, width: 1.1),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      strings.greatConnection,

                      style: const TextStyle(
                        color: _coral,

                        fontSize: 10,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Icon(
                      Icons.auto_awesome_rounded,

                      color: _coral,

                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================

  // COMPANION DETAILS CARD

  // ============================================

  Widget _buildCompanionCard(CompanionStrings strings) {
    final interests =
        controller?.sharedInterests ?? profile.interests.take(2).toList();

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),

        borderRadius: BorderRadius.circular(23),

        border: Border.all(color: _border),

        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.08),

            blurRadius: 22,

            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            const SizedBox(height: 3, child: ColoredBox(color: _teal)),

            Padding(
              padding: const EdgeInsets.all(17),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,

                        children: [
                          CompanionAvatar(
                            name: profile.name,

                            size: 61,

                            imagePath: profile.imagePath,

                            imageUrl: profile.profileImageUrl,
                          ),

                          const Positioned(
                            bottom: 0,

                            right: 0,

                            child: CircleAvatar(
                              radius: 8,

                              backgroundColor: Colors.white,

                              child: CircleAvatar(
                                radius: 5.5,

                                backgroundColor: Color(0xFF31A572),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              profile.name,

                              maxLines: 2,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: _darkTeal,

                                fontSize: 16,

                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            if (profile.verified) ...[
                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,

                                  vertical: 6,
                                ),

                                decoration: BoxDecoration(
                                  color: _mint,

                                  borderRadius: BorderRadius.circular(18),
                                ),

                                child: Row(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    const Icon(
                                      Icons.check_rounded,

                                      size: 14,

                                      color: _teal,
                                    ),

                                    const SizedBox(width: 5),

                                    Flexible(
                                      child: Text(
                                        strings.verifiedCompanion,

                                        style: const TextStyle(
                                          color: _teal,

                                          fontSize: 10.5,

                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,

                        color: _teal,

                        size: 19,
                      ),

                      const SizedBox(width: 9),

                      Text(
                        strings.sharedInterests,

                        style: const TextStyle(
                          color: _muted,

                          fontSize: 13,

                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  if (interests.isEmpty)
                    const Text(
                      'Your shared interests will appear here.',

                      style: TextStyle(
                        color: _muted,

                        fontSize: 12,

                        height: 1.4,
                      ),
                    )
                  else
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,

                        spacing: 10,

                        runSpacing: 10,

                        children: [
                          for (final interest in interests)
                            _interestChip(
                              label: strings.interestLabel(interest),

                              icon: companionInterestIcon(interest),
                            ),
                        ],
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

  Widget _interestChip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF8),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: _coral),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 16, color: _coral),

          const SizedBox(width: 6),

          Text(
            label,

            style: const TextStyle(
              color: _coral,

              fontSize: 12,

              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================

  // AGREEMENT CARD

  // ============================================

  Widget _buildAgreementPanel(CompanionStrings strings) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 23),

      decoration: BoxDecoration(
        color: const Color(0xFFE8FAF5).withValues(alpha: 0.95),

        borderRadius: BorderRadius.circular(23),

        border: Border.all(color: _border),

        boxShadow: [
          BoxShadow(color: _darkTeal.withValues(alpha: 0.035), blurRadius: 12),
        ],
      ),

      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,

            children: [
              const Icon(Icons.people_alt_rounded, color: _teal, size: 42),

              Positioned(
                right: -3,

                bottom: -3,

                child: Container(
                  padding: const EdgeInsets.all(3),

                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,

                    color: _coral,
                  ),

                  child: const Icon(
                    Icons.check_rounded,

                    color: Colors.white,

                    size: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  strings.bothPeopleAgreed,

                  style: const TextStyle(
                    color: Color(0xFF22805D),

                    fontSize: 14,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  strings.connectionStatusActive,

                  style: const TextStyle(
                    color: _teal,

                    fontSize: 12,

                    height: 1.4,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================

  // BOTTOM BUTTONS

  // ============================================

  Widget _buildBottomButtons(
    BuildContext context,

    CompanionStrings strings,

    bool connectionIsActive,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        SizedBox(
          height: 53,

          child: ElevatedButton(
            onPressed: !connectionIsActive
                ? null
                : () => _openConnection(context),

            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,

              foregroundColor: Colors.white,

              disabledBackgroundColor: _border,

              elevation: 4,

              shadowColor: _teal.withValues(alpha: 0.17),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),

            child: Text(
              strings.viewConnection,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 53,

          child: OutlinedButton.icon(
            onPressed: !connectionIsActive
                ? null
                : () => _openScheduling(context),

            icon: const Icon(Icons.calendar_month_rounded, size: 22),

            label: Text(
              strings.scheduleCheckIn,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,

              backgroundColor: Colors.white.withValues(alpha: 0.94),

              side: const BorderSide(color: _teal, width: 1.7),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================

  // ORIGINAL NAVIGATION

  // ============================================

  void _openConnection(BuildContext context) {
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,

        builder: (_) => CurrentConnectionScreen(
          profile: profile,

          selectedLanguage: selectedLanguage,

          controller: controller,
        ),
      ),
    );
  }

  void _openScheduling(BuildContext context) {
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,

        builder: (_) => SchedulingHandoffScreen(
          profile: profile,

          selectedLanguage: selectedLanguage,

          controller: controller,
        ),
      ),
    );
  }
}

// ============================================================

// FULL SCREEN BLURRED FIGMA BACKGROUND

// ============================================================

class _BlurredConnectionBackground extends StatelessWidget {
  const _BlurredConnectionBackground();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,

        children: [
          // Blur the BACKGROUND IMAGE ONLY.

          // Foreground cards and text remain sharp.
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 15,

              sigmaY: 15,

              tileMode: TileMode.clamp,
            ),

            child: Image.asset(
              'assets/images/connection_accepted_bg.png',

              fit: BoxFit.cover,

              alignment: Alignment.center,

              filterQuality: FilterQuality.high,

              errorBuilder: (_, _, _) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      colors: [
                        Color(0xFFD6EEE7),

                        Color(0xFFF9EEE9),

                        Color(0xFFB6DDD2),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Light overlay for readability while keeping

          // the original background colours visible.
          ColoredBox(color: const Color(0xFFF5FBF9).withValues(alpha: 0.35)),
        ],
      ),
    );
  }
}
