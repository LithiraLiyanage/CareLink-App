import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'active_video_call_screen.dart';
import 'kamala_ready_screen.dart';
import 'student_checkin_complete_screen.dart';

class RescheduleCheckInScreen extends StatefulWidget {
  const RescheduleCheckInScreen({
    super.key,
    this.checkInId,
    this.initialCheckIn,
    this.navigationOnly = false,
  });

  final String? checkInId;
  final CheckIn? initialCheckIn;
  final bool navigationOnly;

  @override
  State<RescheduleCheckInScreen> createState() =>
      _RescheduleCheckInScreenState();
}

class _RescheduleCheckInScreenState extends State<RescheduleCheckInScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  CheckIn? _checkIn;
  DateTime? _selectedAt;
  Object? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final preview = widget.initialCheckIn;
    if (widget.navigationOnly && preview != null) {
      _checkIn = preview;
      _selectedAt = preview.scheduledAt;
      _loading = false;
    } else {
      _loadCheckIn();
    }
  }

  Future<void> _loadCheckIn() async {
    try {
      final id = widget.checkInId;
      if (id == null || id.isEmpty) {
        throw StateError('Select a scheduled check-in before rescheduling.');
      }
      final checkIn = await _service.getCheckInById(id);
      if (checkIn == null) {
        throw StateError('The selected check-in could not be found.');
      }
      if (!mounted) return;
      setState(() {
        _checkIn = checkIn;
        _selectedAt = checkIn.scheduledAt;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _chooseDate() async {
    final current = _selectedAt;
    if (current == null) return;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        current.hour,
        current.minute,
      );
    });
  }

  Future<void> _chooseTime() async {
    final current = _selectedAt;
    if (current == null) return;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedAt = DateTime(
        current.year,
        current.month,
        current.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _saveNewTime() async {
    final checkIn = _checkIn;
    final selectedAt = _selectedAt;
    if (_saving || checkIn == null || selectedAt == null) return;
    if (widget.navigationOnly) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => KamalaReadyScreen(
            elderName: checkIn.elderName,
            elderImageUrl: checkIn.elderImageUrl,
            companionId: checkIn.companionId,
            connectionId: '',
            checkInId: checkIn.id,
            scheduledAt: selectedAt,
            durationMinutes: checkIn.durationMinutes,
            mode: checkIn.mode,
            onStartCall: () => _openNavigationOnlyCall(checkIn, selectedAt),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.rescheduleCheckIn(checkIn.id, selectedAt);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelCheckIn() async {
    final checkIn = _checkIn;
    if (checkIn == null) return;
    if (widget.navigationOnly) {
      Navigator.of(context).popUntil(
        (route) =>
            route.settings.name == '/student-my-schedule' || route.isFirst,
      );
      return;
    }
    final ok = await elderConfirm(
      context,
      title: 'Cancel this check-in?',
      message: '${checkIn.companionName} will be notified.',
      confirmLabel: 'Cancel check-in',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _service.cancelCheckIn(checkIn.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openNavigationOnlyCall(
    CheckIn checkIn,
    DateTime scheduledAt,
  ) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ActiveVideoCallScreen(
          elderId: checkIn.elderId,
          elderName: checkIn.elderName,
          elderImageUrl: checkIn.elderImageUrl,
          companionId: checkIn.companionId,
          connectionId: '',
          checkInId: checkIn.id,
          scheduledAt: scheduledAt,
          durationMinutes: checkIn.durationMinutes,
          callType: checkIn.mode,
          onEndCall: () async {
            if (!mounted) return;
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => StudentCheckInCompleteScreen(
                  elderName: checkIn.elderName,
                  elderId: checkIn.elderId,
                  elderImageUrl: checkIn.elderImageUrl,
                  companionId: checkIn.companionId,
                  connectionId: '',
                  checkInId: checkIn.id,
                  scheduledAt: scheduledAt,
                  durationMinutes: checkIn.durationMinutes,
                  callType: checkIn.mode,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 18),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ElderColors.darkTeal,
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        'Could not load this check-in: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ElderColors.textDark),
                      ),
                    )
                  : _checkIn == null || _selectedAt == null
                  ? const Center(child: Text('No check-in is selected.'))
                  : _content(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElderBackButton(onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 10),
        const Text(
          'Reschedule check-in',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose a new day and time',
          style: TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final checkIn = _checkIn!;
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(_selectedAt!);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(_selectedAt!));
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _companionCard(checkIn, context),
        _selectionCard(
          label: 'Date',
          value: date,
          icon: Icons.calendar_month_outlined,
          onTap: _chooseDate,
        ),
        _selectionCard(
          label: 'Time',
          value: time,
          icon: Icons.schedule_rounded,
          onTap: _chooseTime,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ElderColors.mintSoft,
            border: Border.all(color: ElderColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${checkIn.durationMinutes} min · ${checkIn.mode} check-in',
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Column(
          children: [
            ElderPrimaryButton(
              label: _saving ? 'Saving...' : 'Save new time',
              height: 54,
              onPressed: _saveNewTime,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _saving ? null : _cancelCheckIn,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC94354),
                  backgroundColor: ElderColors.dangerSoft,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel this check-in',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _companionCard(CheckIn checkIn, BuildContext context) {
    final initials = checkIn.companionName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    return Container(
      height: 102,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal, width: 1.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: ElderColors.mintSoft,
            child: Text(
              initials,
              style: const TextStyle(
                color: ElderColors.darkTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.companionName,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(checkIn.scheduledAt)} · '
                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(checkIn.scheduledAt))}',
                  style: const TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          ElderStatusPill(checkIn.mode.toUpperCase()),
        ],
      ),
    );
  }

  Widget _selectionCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE9E7)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: ElderColors.deepTeal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ElderColors.textMuted,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}
