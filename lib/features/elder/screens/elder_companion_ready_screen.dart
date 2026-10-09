import 'package:flutter/material.dart';

import '../widgets/elder_ui.dart';

// =====================================================
// L05 - COMPANION READY / START VIDEO CALL
// CareLink Figma UI Redesign
// Existing call callbacks and navigation preserved.
// =====================================================

class NethmiReadyScreen extends StatelessWidget {
  const NethmiReadyScreen({
    super.key,
    this.companionName = 'Student Companion',
    this.companionImageUrl,
    this.scheduledAt,
    this.durationMinutes = 30,
    this.mode = 'Video',
    this.onStartCall,
    this.onVoiceCall,
    this.onConversationIdeas,
  });

  final String companionName;
  final String? companionImageUrl;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String mode;

  // Existing real check-in callbacks.
  // Supplied by MyScheduleScreen.
  final VoidCallback? onStartCall;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onConversationIdeas;

  // =====================================================
  // FIGMA COLOR SYSTEM
  // =====================================================

  static const Color _background = Color(0xFFF6FAF9);
  static const Color _darkTeal = Color(0xFF123F42);
  static const Color _primaryTeal = Color(0xFF00746F);
  static const Color _mint = Color(0xFFE6F5F1);
  static const Color _cyan = Color(0xFFBDF3F5);
  static const Color _muted = Color(0xFF718181);

  // =====================================================
  // ORIGINAL CALL FUNCTIONALITY
  // =====================================================

  void _startVideoCall(BuildContext context) {
    final start = onStartCall;

    if (start == null) {
      _showVerifiedCheckInRequired(context);
      return;
    }

    start();
  }

  void _startVoiceCall(BuildContext context) {
    final start = onVoiceCall;

    if (start == null) {
      _showVerifiedCheckInRequired(context);
      return;
    }

    start();
  }

  void _showVerifiedCheckInRequired(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Open a ready check-in from My Schedule '
            'to start a call.',
          ),
        ),
      );
  }

  void _showMessagingUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Messaging is not available in CareLink yet.'),
        ),
      );
  }

  // =====================================================
  // MAIN SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: _background,
      statusBarColor: const Color(0xFF8DA890),
      darkStatusBar: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Stack(
                children: [
                  // Background hero image.
                  _hero(context),

                  // White Figma content panel.
                  Padding(
                    padding: const EdgeInsets.only(top: 266),
                    child: _contentPanel(context, screenHeight: screenHeight),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // FIGMA HERO IMAGE
  // =====================================================

  Widget _hero(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    final dateText = scheduledAt == null
        ? '$durationMinutes min · $mode check-in'
        : '${localizations.formatMediumDate(scheduledAt!)}'
              ' · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt!))}'
              ' · $mode check-in';

    return SizedBox(
      width: double.infinity,
      height: 310,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic companion image.
          _heroImage(),

          // Figma dark gradient overlay.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.42, 1.0],
                colors: [
                  Color(0x28000000),
                  Color(0x08000000),
                  Color(0xB8000000),
                ],
              ),
            ),
          ),

          // Back button.
          Positioned(top: 15, left: 17, child: _backButton(context)),

          // Hero title and schedule.
          Positioned(
            left: 20,
            right: 20,
            bottom: 47,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$companionName is ready',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    shadows: [Shadow(color: Color(0x55000000), blurRadius: 7)],
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  dateText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEAEFEF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DYNAMIC HERO IMAGE
  // =====================================================

  Widget _heroImage() {
    final image = companionImageUrl?.trim();

    if (image == null || image.isEmpty) {
      return _heroPlaceholder();
    }

    return Image.network(
      image,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return _heroPlaceholder();
      },
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB5D8CB), Color(0xFF558A80), Color(0xFF123F42)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              _initials(companionName),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.video_call_rounded, color: Colors.white70, size: 27),
        ],
      ),
    );
  }

  // =====================================================
  // FIGMA BACK BUTTON
  // =====================================================

  Widget _backButton(BuildContext context) {
    return Material(
      color: const Color(0xFFBDF2EF),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _darkTeal,
            size: 18,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // WHITE ROUNDED CONTENT PANEL
  // =====================================================

  Widget _contentPanel(BuildContext context, {required double screenHeight}) {
    final panelHeight = screenHeight - 266;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: panelHeight > 0 ? panelHeight : 0),
      padding: const EdgeInsets.fromLTRB(18, 19, 18, 20),
      decoration: const BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Companion profile.
          _companionProfile(),

          const SizedBox(height: 25),

          // Duration / Call type / Safety.
          _informationCard(),

          const SizedBox(height: 19),

          // Primary action.
          _startVideoButton(context),

          const SizedBox(height: 11),

          // Voice and messaging.
          _secondaryActions(context),

          if (onConversationIdeas != null) ...[
            const SizedBox(height: 18),
            _conversationIdeas(),
          ],

          const SizedBox(height: 19),

          // Safety reminder.
          _safetyCard(),
        ],
      ),
    );
  }

  // =====================================================
  // COMPANION PROFILE SECTION
  // =====================================================

  Widget _companionProfile() {
    return Row(
      children: [
        _profileAvatar(),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companionName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkTeal,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Verified student companion',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileAvatar() {
    final image = companionImageUrl?.trim();

    if (image == null || image.isEmpty) {
      return _avatarFallback();
    }

    return CircleAvatar(
      radius: 27,
      backgroundColor: _mint,
      child: ClipOval(
        child: Image.network(
          image,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _avatarFallback();
          },
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return CircleAvatar(
      radius: 27,
      backgroundColor: _mint,
      child: Text(
        _initials(companionName),
        style: const TextStyle(
          color: _darkTeal,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _initials(String name) {
    final result = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return result.isEmpty ? '?' : result;
  }

  // =====================================================
  // FIGMA 30 MIN / VIDEO / SAFE CARD
  // =====================================================

  Widget _informationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryTeal, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.055),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _metric('$durationMinutes min', 'planned duration')),

          Expanded(child: _metric(mode, 'private call')),

          Expanded(child: _metric('Safe', 'controls on')),
        ],
      ),
    );
  }

  Widget _metric(String value, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _darkTeal,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 9, height: 1.25),
        ),
      ],
    );
  }

  // =====================================================
  // START VIDEO CALL PRIMARY BUTTON
  // =====================================================

  Widget _startVideoButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => _startVideoCall(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryTeal,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryTeal.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: const Text(
          'Start video call',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // VOICE ONLY / MESSAGE INSTEAD
  // =====================================================

  Widget _secondaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _outlineButton(
            label: 'Voice only',
            onPressed: () => _startVoiceCall(context),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _outlineButton(
            label: 'Message instead',
            onPressed: () => _showMessagingUnavailable(context),
          ),
        ),
      ],
    );
  }

  Widget _outlineButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primaryTeal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          side: const BorderSide(color: _primaryTeal, width: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA CONVERSATION IDEAS BUTTON
  // =====================================================

  Widget _conversationIdeas() {
    return SizedBox(
      width: double.infinity,
      height: 47,
      child: OutlinedButton(
        onPressed: onConversationIdeas,
        style: OutlinedButton.styleFrom(
          backgroundColor: _cyan,
          foregroundColor: _darkTeal,
          side: const BorderSide(color: Color(0xFF53777A), width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Conversation Ideas',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA SAFETY / CONTROL CARD
  // =====================================================

  Widget _safetyCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _darkTeal, width: 0.85),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _primaryTeal, width: 1),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: _primaryTeal,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You stay in control',
                  style: TextStyle(
                    color: _primaryTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'End, retry or ask for help at any time.',
                  maxLines: 2,
                  style: TextStyle(color: _muted, fontSize: 10.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
