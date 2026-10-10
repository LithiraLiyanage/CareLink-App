import 'package:flutter/material.dart';

import '../controllers/companion_controller.dart';
import '../controllers/companion_controller_factory.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../models/match_preferences.dart';
import '../models/match_recommendation.dart';
import '../widgets/companion_avatar.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_interest_icon.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'companion_profile_screen.dart';
import 'matching_preferences_screen.dart';
import 'send_match_request_screen.dart';

class RecommendedCompanionsScreen extends StatefulWidget {
  const RecommendedCompanionsScreen({
    super.key,
    required this.selectedLanguage,
    this.preferences,
    this.controller,
    this.fromPreferences = false,
  });
  final CompanionLanguage selectedLanguage;
  final MatchPreferences? preferences;
  final CompanionController? controller;
  final bool fromPreferences;
  @override
  State<RecommendedCompanionsScreen> createState() =>
      _RecommendedCompanionsScreenState();
}

class _RecommendedCompanionsScreenState
    extends State<RecommendedCompanionsScreen> {
  late final CompanionController _controller;
  late final bool _ownsController;
  static const Color _teal = Color(0xFF087F83);
  static const Color _darkTeal = Color(0xFF173F42);
  static const Color _coral = Color(0xFFFF625F);
  static const Color _mint = Color(0xFFEAF6F2);
  static const Color _border = Color(0xFFDCE9E5);
  static const Color _muted = Color(0xFF5B7272);
  CompanionLanguage get selectedLanguage => widget.selectedLanguage;
  MatchPreferences get _effectivePreferences =>
      widget.preferences ??
      _controller.currentPreferences ??
      MatchPreferences(
        preferredLanguage: '',
        interests: const [],
        availability: '',
        preferredTime: '',
      );
  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? createCompanionController();
    _controller.addListener(_onControllerChanged);
    if (_ownsController ||
        _controller.currentPreferences == null ||
        (widget.preferences != null &&
            !identical(_controller.currentPreferences, widget.preferences))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadRecommendations(_effectivePreferences);
        }
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  // ===================================================
  // Existing navigation and matching logic
  // ===================================================
  void _adjustPreferences(BuildContext context) {
    if (widget.fromPreferences && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      CompanionRoute<void>(
        context: context,
        builder: (_) => MatchingPreferencesScreen(
          initialPreferences: _effectivePreferences,
          uiLanguage: selectedLanguage,
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, MatchRecommendation recommendation) {
    final profile = recommendation.companion;
    _controller.selectRecommendation(recommendation);
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        builder: (_) => CompanionProfileScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          preferences: _effectivePreferences,
          controller: _controller,
        ),
      ),
    );
  }

  void _openRequest(BuildContext context, MatchRecommendation recommendation) {
    final profile = recommendation.companion;
    _controller.selectRecommendation(recommendation);
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        builder: (_) => SendMatchRequestScreen(
          profile: profile,
          selectedLanguage: selectedLanguage,
          controller: _controller,
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ===================================================
  // Profile image presentation
  // ===================================================
  // Demo portraits are visual fallbacks for the sample
  // profiles. The Firebase image URL always takes priority.
  // Replace these previews with genuine profile photos
  // before production use.
  String _imagePathFor(CompanionProfile profile) {
    if (profile.imagePath.isNotEmpty) {
      return profile.imagePath;
    }
    if ((profile.profileImageUrl ?? '').isNotEmpty) {
      return '';
    }
    final name = profile.name.trim().toLowerCase();
    if (name.startsWith('nethmi ')) {
      return 'assets/images/companion_nethmi.png';
    }
    if (name.startsWith('amaya ')) {
      return 'assets/images/companion_amaya.png';
    }
    if (name.startsWith('kavindu ')) {
      return 'assets/images/companion_kavindu.png';
    }
    return '';
  }

  Widget _avatar(CompanionProfile profile, {required double size}) {
    return CompanionAvatar(
      name: profile.name,
      size: size,
      imagePath: _imagePathFor(profile),
      imageUrl: profile.profileImageUrl,
      heroTag: 'companion-avatar-${profile.id}',
    );
  }

  // ===================================================
  // Main UI
  // ===================================================
  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    final recommendations = _controller.recommendations;
    return CompanionScaffold(
      body: CompanionEntrance(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, strings),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        strings.recommendedCompanions,
                        style: const TextStyle(
                          color: _darkTeal,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.recommendationSubtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _preferencesRow(context, strings),
                    const SizedBox(height: 15),
                    if (_controller.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(color: _teal),
                        ),
                      )
                    else if (_controller.errorMessage != null)
                      _buildMessageCard(
                        context,
                        title: strings.recommendationsLoadError,
                        detail: strings.recommendationsRetryHelper,
                        action: strings.retry,
                        onPressed: () => _controller.loadRecommendations(
                          _effectivePreferences,
                        ),
                      )
                    else if (recommendations.isEmpty)
                      _buildMessageCard(
                        context,
                        title: strings.noSuitableCompanions,
                        detail: strings.adjustPreferencesHelper,
                        action: strings.adjustPreferences,
                        onPressed: () => _adjustPreferences(context),
                      )
                    else ...[
                      CompanionEntrance(
                        child: _buildFeaturedCard(
                          context,
                          strings,
                          recommendations.first,
                        ),
                      ),
                      for (
                        var index = 1;
                        index < recommendations.length;
                        index++
                      ) ...[
                        const SizedBox(height: 12),
                        CompanionEntrance(
                          delay: Duration(milliseconds: 55 * index),
                          child: _buildSmallCard(
                            context,
                            strings,
                            recommendation: recommendations[index],
                          ),
                        ),
                      ],
                    ],
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
          matchesIcon: Icons.favorite_border,
          selectedMatchesIcon: Icons.favorite_border,
          onDestinationSelected: (index) {
            if (index != 1) {
              _showPlaceholder(context, strings.navigationComingSoon);
            }
          },
        ),
      ),
    );
  }

  // ===================================================
  // Header
  // ===================================================
  Widget _buildHeader(BuildContext context, CompanionStrings strings) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: _border)),
          child: IconButton(
            onPressed: () => _adjustPreferences(context),
            tooltip: strings.adjustPreferences,
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 24,
              color: _teal,
            ),
          ),
        ),
        // A bounded, flexible label avoids an overflowing Row with 2x text.
        Expanded(
          child: Semantics(
            label: 'CareLink',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'C',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Flexible(
                      child: Text(
                        'CareLink',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: _teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      '•',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: _coral,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Keep the existing decorative notification icon.
        ExcludeSemantics(
          child: Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _darkTeal.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _teal,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ===================================================
  // Adjust preferences row
  // ===================================================
  Widget _preferencesRow(BuildContext context, CompanionStrings strings) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 3,
          decoration: BoxDecoration(
            color: _coral,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        // Expanded gives localized text a finite width. The label can wrap
        // instead of pushing the trailing edge outside a narrow screen.
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _adjustPreferences(context),
              style: TextButton.styleFrom(
                foregroundColor: _teal,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                '${strings.adjustPreferences} →',
                softWrap: true,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================================================
  // Featured companion card
  // ===================================================
  Widget _buildFeaturedCard(
    BuildContext context,
    CompanionStrings strings,
    MatchRecommendation recommendation,
  ) {
    final profile = recommendation.companion;
    final reasons = recommendation.reasons;
    final availability = strings.profileAvailability(profile, short: true);
    final metadata = [
      if (profile.languages.isNotEmpty) profile.languages.join(', '),
      if (availability.trim().isNotEmpty) availability,
    ].join(' • ');
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 3,
      shadowColor: _darkTeal.withValues(alpha: 0.10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: const BorderSide(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 3, child: ColoredBox(color: _teal)),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _avatar(profile, size: 55),
                    const SizedBox(width: 11),
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
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          if (profile.verified) ...[
                            const SizedBox(height: 6),
                            _buildVerifiedBadge(strings.verifiedStudent),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    metadata,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
                if (profile.interests.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: profile.interests
                        .map(
                          (interest) => _buildInterestChip(
                            strings.interestLabel(interest),
                            companionInterestIcon(interest),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          strings.whyThisMatch,
                          style: const TextStyle(
                            color: _darkTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (reasons.isEmpty)
                        Text(
                          strings.noPreferenceOverlap,
                          style: const TextStyle(color: _muted, fontSize: 11.5),
                        )
                      else
                        for (final reason in reasons)
                          _buildReason(strings.matchReasonText(reason)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionButtons(context, strings, recommendation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // Profile and Request buttons
  // ===================================================
  Widget _buildActionButtons(
    BuildContext context,
    CompanionStrings strings,
    MatchRecommendation recommendation,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final profileButton = OutlinedButton(
          onPressed: () => _openProfile(context, recommendation),
          style: OutlinedButton.styleFrom(
            foregroundColor: _teal,
            backgroundColor: Colors.white,
            side: const BorderSide(color: _teal, width: 1.4),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            strings.viewProfile,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        );
        final requestButton = ElevatedButton(
          onPressed: () => _openRequest(context, recommendation),
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: _teal.withValues(alpha: 0.18),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            strings.sendRequest,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        );
        final compactEnglish =
            selectedLanguage == CompanionLanguage.english &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.2;
        if (!compactEnglish || constraints.maxWidth < 290) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [profileButton, const SizedBox(height: 8), requestButton],
          );
        }
        return Row(
          children: [
            Expanded(child: profileButton),
            const SizedBox(width: 9),
            Expanded(child: requestButton),
          ],
        );
      },
    );
  }

  // ===================================================
  // Small companion cards
  // ===================================================
  Widget _buildSmallCard(
    BuildContext context,
    CompanionStrings strings, {
    required MatchRecommendation recommendation,
  }) {
    final profile = recommendation.companion;
    final availability = strings.profileAvailability(profile, short: true);
    final metadata = [
      if (profile.languages.isNotEmpty) profile.languages.join(', '),
      if (profile.interests.isNotEmpty)
        profile.interests.map(strings.interestLabel).join(', '),
      if (availability.trim().isNotEmpty) availability,
    ].join(' • ');
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 2,
      shadowColor: _darkTeal.withValues(alpha: 0.09),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border),
      ),
      child: Semantics(
        button: true,
        label: '${strings.viewProfile}: ${profile.name}',
        child: InkWell(
          onTap: () => _openProfile(context, recommendation),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _avatar(profile, size: 47),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _darkTeal,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (profile.verified) ...[
                        const SizedBox(height: 5),
                        _buildVerifiedBadge(strings.verified),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 19, color: _teal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================
  // Verified badge
  // ===================================================
  Widget _buildVerifiedBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: _teal, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _teal,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // Interest chips
  // ===================================================
  Widget _buildInterestChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _coral, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _coral, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: _coral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // Matching reasons
  // ===================================================
  Widget _buildReason(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 15, color: _teal),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(color: _teal, fontSize: 11.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // Loading/error/empty state message
  // ===================================================
  Widget _buildMessageCard(
    BuildContext context, {
    required String title,
    required String detail,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.people_outline_rounded, color: _teal, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _darkTeal,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
