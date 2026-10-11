import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../companion/screens/student_companion_home_screen.dart';
import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'memory_lane_screen.dart';
import 'my_schedule_screen.dart';

/// Completion screen for the authenticated Student Companion flow.
/// The active call passes the saved check-in document ID via route arguments.
class CheckInCompleteKamalaScreen extends StatefulWidget {
  const CheckInCompleteKamalaScreen({super.key, this.checkInId = ''});

  final String checkInId;

  @override
  State<CheckInCompleteKamalaScreen> createState() =>
      _CheckInCompleteKamalaScreenState();
}

class _CheckInCompleteKamalaScreenState
    extends State<CheckInCompleteKamalaScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  bool _resolvedRoute = false;
  bool _loading = true;
  String _checkInId = '';
  String? _error;
  CheckIn? _completedCheckIn;
  int? _actualDurationMinutes;
  String? _nextCheckInText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedRoute) return;
    _resolvedRoute = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    _checkInId = widget.checkInId.isNotEmpty
        ? widget.checkInId
        : (args is String ? args : '');

    if (_checkInId.isEmpty) {
      _loading = false;
      _error = 'Open this screen after completing a check-in.';
      return;
    }

    _loadCompletion();
  }

  Future<void> _loadCompletion() async {
    if (_checkInId.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final completed = await _service.getCheckInById(_checkInId);
      if (completed == null) {
        throw StateError('The completed check-in could not be found.');
      }
      if (completed.status != CheckInStatus.completed) {
        throw StateError('This check-in has not been completed yet.');
      }

      // Use the actual timestamps written on Start / End, rather than
      // displaying a fabricated duration from the design screenshot.
      final doc = await FirebaseFirestore.instance
          .collection('check_ins')
          .doc(_checkInId)
          .get();
      final data = doc.data() ?? const <String, dynamic>{};
      final started = data['startedAt'];
      final ended = data['completedAt'];
      int? duration;
      if (started is Timestamp && ended is Timestamp) {
        final seconds = ended.toDate().difference(started.toDate()).inSeconds;
        if (seconds >= 0) {
          duration = seconds ~/ 60;
        }
      }

      // An unavailable next-session query should not hide an already
      // completed check-in. It only affects the optional Next field.
      String? next;
      try {
        final all = await _service.getCheckIns();
        final now = DateTime.now();
        final upcoming = all.where((item) {
          return item.id != completed.id &&
              item.scheduledAt.isAfter(now) &&
              (item.status == CheckInStatus.scheduled ||
                  item.status == CheckInStatus.ready);
        }).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        if (upcoming.isNotEmpty) {
          next = _nextTime(upcoming.first.scheduledAt);
        }
      } catch (_) {
        next = null;
      }

      if (!mounted) return;
      setState(() {
        _completedCheckIn = completed;
        _actualDurationMinutes = duration;
        _nextCheckInText = next;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load completed check-in: $error';
      });
    }
  }

  static String _nextTime(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '${weekdays[value.weekday - 1]} $hour:$minute';
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const StudentCompanionHomeScreen(),
      ),
      (_) => false,
    );
  }

  void _openFromHome(Widget destination) {
    final navigator = Navigator.of(context);
    // Retain Student Companion Home underneath the requested screen so
    // its back arrow leads home rather than reopening the finished call.
    navigator.pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => const StudentCompanionHomeScreen(),
      ),
      (_) => false,
    );
    navigator.push<void>(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onHome: _goHome,
        onSchedule: () => _openFromHome(const MyScheduleScreen()),
        onMemory: () => _openFromHome(const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElderBackButton(onPressed: _goHome),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ElderColors.darkTeal,
                      ),
                    )
                  : _error != null
                  ? _errorView()
                  : _completionContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: ElderColors.deepTeal,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ElderColors.textDark, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (_checkInId.isNotEmpty)
              TextButton.icon(
                onPressed: _loadCompletion,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            const SizedBox(height: 10),
            ElderPrimaryButton(
              label: 'Back to home',
              height: 52,
              onPressed: _goHome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _completionContent() {
    // Scroll when system text scale or display height is smaller, while
    // preserving the screenshot's spacing at 393 x 852 logical pixels.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _completeHeader(),
                const SizedBox(height: 15),
                _summaryRow(),
                const SizedBox(height: 15),
                _personCard(),
                const SizedBox(height: 15),
                const _ConsentCard(),
                const SizedBox(height: 15),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _completeHeader() {
    final name = _completedCheckIn!.elderName.trim().isEmpty
        ? 'your elder companion'
        : _completedCheckIn!.elderName;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: ElderColors.mintSoft,
            shape: BoxShape.circle,
            border: Border.all(color: ElderColors.deepTeal, width: 1.3),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: ElderColors.deepTeal,
            size: 44,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Check-in complete',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Video check-in completed with $name',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow() {
    final reflection = _completedCheckIn!.reflection?.trim();
    final duration = _actualDurationMinutes == null
        ? '—'
        : _actualDurationMinutes == 0
        ? '<1 min'
        : '$_actualDurationMinutes min';
    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            icon: Icons.schedule_rounded,
            label: 'Duration',
            value: duration,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _SummaryBox(
            icon: Icons.favorite_outline_rounded,
            label: 'Reflection',
            value: reflection == null || reflection.isEmpty ? '—' : reflection,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _SummaryBox(
            icon: Icons.event_available_outlined,
            label: 'Next',
            value: _nextCheckInText ?? 'None',
          ),
        ),
      ],
    );
  }

  Widget _personCard() {
    final checkIn = _completedCheckIn!;
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const ElderAvatar(
            asset: ElderAssets.kamalaAvatar,
            size: 52,
            border: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.elderName.isEmpty ? 'Older Adult' : checkIn.elderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${checkIn.mode} check-in • Completed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const ElderStatusPill('COMPLETED'),
        ],
      ),
    );
  }

  Widget _actions() {
    return Column(
      children: [
        ElderPrimaryButton(
          label: 'Back to home',
          height: 54,
          onPressed: _goHome,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElderOutlineButton(
            label: 'View Memory Lane',
            height: 48,
            onPressed: () => _openFromHome(const MemoryLaneScreen()),
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ElderColors.deepTeal, size: 17),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: ElderColors.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.privacy_tip_outlined,
              color: ElderColors.deepTeal,
              size: 19,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what to share',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Set the visibility of each memory before saving.',
                  maxLines: 2,
                  style: TextStyle(color: ElderColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
