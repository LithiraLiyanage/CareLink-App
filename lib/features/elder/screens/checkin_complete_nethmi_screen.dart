
import 'package:flutter/material.dart';

import '../widgets/elder_ui.dart';

import 'checkin_reflection_screen.dart';
import 'elder_home_screen.dart';
import 'memory_lane_screen.dart';
import 'my_schedule_screen.dart';

// =====================================================
// L08 - CHECK-IN COMPLETE
// CareLink Figma UI Redesign
// Existing functionality preserved.
// =====================================================

class CheckInCompleteNethmiScreen extends StatefulWidget {
  const CheckInCompleteNethmiScreen({
    super.key,
    this.companionName = 'Student Companion',
    this.companionImageUrl,
    this.scheduledAt,
    this.durationMinutes = 28,
    this.mode = 'Video',
    this.previewOnly = false,
  });

  final String companionName;
  final String? companionImageUrl;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String mode;
  final bool previewOnly;

  @override
  State<CheckInCompleteNethmiScreen> createState() =>
      _CheckInCompleteNethmiScreenState();
}

class _CheckInCompleteNethmiScreenState
    extends State<CheckInCompleteNethmiScreen> {
  String? _feeling;
  String _note = '';

  // =====================================================
  // FIGMA COLOR SYSTEM
  // =====================================================

  static const Color _background = Color(0xFFF6FAF9);
  static const Color _darkTeal = Color(0xFF123F42);
  static const Color _primaryTeal = Color(0xFF086C66);
  static const Color _mint = Color(0xFFE6F6F1);
  static const Color _mintStrong = Color(0xFFBEECE2);
  static const Color _muted = Color(0xFF718383);
  static const Color _border = Color(0xFFB5DDD1);
  static const Color _white = Colors.white;

  // =====================================================
  // ORIGINAL NAVIGATION FUNCTIONALITY
  // =====================================================

  void _replaceWith(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
      (_) => false,
    );
  }

  void _goHome() {
    if (widget.previewOnly) {
      _showPreviewNotice();
      return;
    }

    _replaceWith(const ElderHomeScreen());
  }

  void _goSchedule() {
    if (widget.previewOnly) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const MyScheduleScreen(
            navigationOnly: true,
          ),
        ),
      );
      return;
    }

    _replaceWith(const MyScheduleScreen());
  }

  void _openMemoryLane() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryLaneScreen(
          navigationOnly: widget.previewOnly,
        ),
      ),
    );
  }

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Home navigation is available in the '
          'signed-in CareLink application.',
        ),
      ),
    );
  }

  // =====================================================
  // ORIGINAL REFLECTION FUNCTIONALITY
  // =====================================================

  Future<void> _openReflection() async {
    final result =
        await Navigator.of(context).push<CheckInReflectionResult>(
      MaterialPageRoute<CheckInReflectionResult>(
        builder: (_) => CheckInReflectionScreen(
          companionName: widget.companionName,
          initialFeeling: _feeling,
          initialNote: _note,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _feeling = result.feeling;
      _note = result.note;
    });
  }

  // =====================================================
  // MAIN SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: _background,
      statusBarColor: _background,
      darkStatusBar: true,

      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onHome: _goHome,
        onSchedule: _goSchedule,
        onMemory: _openMemoryLane,
      ),

      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back button.
            _topBar(),

            // Scrollable content.
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  19,
                  13,
                  19,
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _completeHeader(),

                    const SizedBox(height: 27),

                    _summaryRow(),

                    const SizedBox(height: 20),

                    _personCard(),

                    if (_note.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _reflectionNote(),
                    ],

                    const SizedBox(height: 20),

                    _privacyCard(),

                    const SizedBox(height: 23),

                    _actions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA TOP BAR
  // =====================================================

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        0,
      ),
      child: Row(
        children: [
          Material(
            color: _white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _goHome,
              customBorder: const CircleBorder(),
              child: Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryTeal,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _primaryTeal,
                  size: 17,
                ),
              ),
            ),
          ),

          const Spacer(),

          if (widget.previewOnly)
            const ElderStatusPill('UI PREVIEW'),
        ],
      ),
    );
  }

  // =====================================================
  // FIGMA SUCCESS HEADER
  // =====================================================

  Widget _completeHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: _mint,
            shape: BoxShape.circle,
            border: Border.all(
              color: _primaryTeal,
              width: 1.1,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF4D5554),
            size: 52,
          ),
        ),

        const SizedBox(height: 17),

        const Text(
          'Check-in complete',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkTeal,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'Your ${widget.mode.toLowerCase()} check-in '
          'with ${widget.companionName} is complete.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 11.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // FIGMA SUMMARY CARDS
  // =====================================================

  Widget _summaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summaryBox(
            label: 'Planned',
            value: '${widget.durationMinutes} min',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _summaryBox(
            label: 'Reflection',
            value: _feeling ?? 'Add',
            onTap: _openReflection,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _summaryBox(
            label: 'Next',
            value: 'Schedule',
            onTap: _goSchedule,
          ),
        ),
      ],
    );
  }

  Widget _summaryBox({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final card = Container(
      constraints: const BoxConstraints(
        minHeight: 69,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _primaryTeal,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.035),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _darkTeal,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Semantics(
      button: true,
      label: '$label: $value. Tap to open.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: card,
      ),
    );
  }

  // =====================================================
  // FIGMA COMPANION CARD
  // =====================================================

  Widget _personCard() {
    final localizations =
        MaterialLocalizations.of(context);

    final dateText = widget.scheduledAt == null
        ? ''
        : ' · ${localizations.formatMediumDate(
            widget.scheduledAt!,
          )}';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 100,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _primaryTeal,
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.075),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _companionAvatar(),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.companionName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${widget.mode} check-in$dateText',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _primaryTeal,
                width: 0.9,
              ),
            ),
            child: const Text(
              'COMPLETED',
              style: TextStyle(
                color: _primaryTeal,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DYNAMIC COMPANION AVATAR
  // =====================================================

  Widget _companionAvatar() {
    final name = widget.companionName.trim();

    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final imageUrl = widget.companionImageUrl?.trim();

    Widget fallback() {
      return CircleAvatar(
        radius: 26,
        backgroundColor: _mintStrong,
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: const TextStyle(
            color: _darkTeal,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return fallback();
    }

    return CircleAvatar(
      radius: 27,
      backgroundColor: _mintStrong,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return fallback();
          },
        ),
      ),
    );
  }

  // =====================================================
  // REFLECTION NOTE - EXISTING FEATURE
  // =====================================================

  Widget _reflectionNote() {
    return InkWell(
      onTap: _openReflection,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.favorite_outline_rounded,
                  color: _primaryTeal,
                  size: 18,
                ),

                SizedBox(width: 8),

                Text(
                  'Your reflection note',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                Spacer(),

                Icon(
                  Icons.edit_outlined,
                  color: _primaryTeal,
                  size: 17,
                ),
              ],
            ),

            const SizedBox(height: 9),

            Text(
              _note,
              style: const TextStyle(
                color: _darkTeal,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA PRIVACY CARD
  // =====================================================

  Widget _privacyCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 83,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _primaryTeal,
          width: 0.85,
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _white,
            child: Icon(
              Icons.shield_outlined,
              color: _primaryTeal,
              size: 23,
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your reflection stays private',
                  style: TextStyle(
                    color: _primaryTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Your reflection is held on this screen '
                  'until secure saving is enabled.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.5,
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
  // FIGMA BOTTOM ACTIONS
  // =====================================================

  Widget _actions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dark teal primary button.
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _goHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryTeal,
              foregroundColor: _white,
              elevation: 3,
              shadowColor:
                  _primaryTeal.withValues(alpha: 0.20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Back to home',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(height: 11),

        // White outlined secondary button.
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: _openMemoryLane,
            style: OutlinedButton.styleFrom(
              backgroundColor: _white,
              foregroundColor: _primaryTeal,
              side: const BorderSide(
                color: _primaryTeal,
                width: 0.9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'View Memory Lane',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
