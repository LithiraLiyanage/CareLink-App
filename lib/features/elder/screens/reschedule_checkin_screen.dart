import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'my_schedule_screen.dart';
import 'kamala_ready_screen.dart';

class RescheduleCheckInScreen extends StatefulWidget {
  final String checkInId;

  // Optional for independent design previews; real flow must pass the Firestore ID.
  const RescheduleCheckInScreen({super.key, this.checkInId = ''});

  @override
  State<RescheduleCheckInScreen> createState() =>
      _RescheduleCheckInScreenState();
}

class _RescheduleCheckInScreenState extends State<RescheduleCheckInScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  int selectedDate = 0;
  int selectedTime = 1;
  bool _saving = false;
  bool _loading = true;
  String? _errorMessage;
  CheckIn? _checkIn;

  static const times = ['5:30 PM', '6:30 PM', '7:00 PM', '7:30 PM'];
  static const _hours = [17, 18, 19, 19];
  static const _minutes = [30, 30, 0, 30];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Next five calendar days; no hardcoded year/month/day.
  List<DateTime> get _dates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(5, (index) => today.add(Duration(days: index + 1)));
  }

  String _dateLabel(DateTime date) =>
      '${_weekdays[date.weekday - 1]} ${date.day}/${date.month}';

  String _timeLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  void initState() {
    super.initState();
    _loadCheckIn();
  }

  Future<void> _loadCheckIn() async {
    if (widget.checkInId.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Select a check-in from My Schedule first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final item = await _service.getCheckInById(widget.checkInId);
      if (item == null) {
        throw StateError('This check-in no longer exists.');
      }
      if (item.status == CheckInStatus.cancelled ||
          item.status == CheckInStatus.completed) {
        throw StateError('This check-in can no longer be rescheduled.');
      }
      if (!mounted) return;

      final matchingDay = _dates.indexWhere(
        (day) =>
            day.year == item.scheduledAt.year &&
            day.month == item.scheduledAt.month &&
            day.day == item.scheduledAt.day,
      );
      final matchingTime = List.generate(times.length, (index) => index)
          .indexWhere(
            (index) =>
                _hours[index] == item.scheduledAt.hour &&
                _minutes[index] == item.scheduledAt.minute,
          );

      setState(() {
        _checkIn = item;
        selectedDate = matchingDay < 0 ? 0 : matchingDay;
        selectedTime = matchingTime < 0 ? 1 : matchingTime;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load check-in: $error';
        _loading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveNewTime() async {
    if (_saving || _checkIn == null) return;

    final day = _dates[selectedDate];
    final selectedDateTime = DateTime(
      day.year,
      day.month,
      day.day,
      _hours[selectedTime],
      _minutes[selectedTime],
    );
    if (!selectedDateTime.isAfter(DateTime.now())) {
      _showError('Please choose a future date and time.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.rescheduleCheckIn(widget.checkInId, selectedDateTime);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: RouteSettings(arguments: widget.checkInId),
          builder: (_) => const KamalaReadyScreen(),
        ),
      );
    } catch (error) {
      _showError('Could not save new time: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelCheckIn() async {
    if (_saving || _checkIn == null) return;
    final ok = await elderConfirm(
      context,
      title: 'Cancel this check-in?',
      message: 'This session will be cancelled in My Schedule.',
      confirmLabel: 'Cancel check-in',
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    try {
      await _service.cancelCheckIn(widget.checkInId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyScheduleScreen()),
      );
    } catch (error) {
      _showError('Could not cancel check-in: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ElderColors.darkTeal,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 34,
                            color: ElderColors.darkTeal,
                          ),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: _loadCheckIn,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _currentCheckInCard(),
                        _dateSection(),
                        _timeSection(),
                        _notificationCard(),
                        _actions(),
                      ],
                    ),
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

  Widget _currentCheckInCard() {
    final checkIn = _checkIn!;
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
          const ElderAvatar(
            asset: ElderAssets.kamalaAvatar,
            size: 54,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_dateLabel(checkIn.scheduledAt)} • '
                  '${_timeLabel(checkIn.scheduledAt)}',
                  style: const TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const ElderStatusPill('VIDEO'),
        ],
      ),
    );
  }

  Widget _dateSection() {
    final dates = _dates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a new date',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(dates.length, (index) {
            final selected = index == selectedDate;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == dates.length - 1 ? 0 : 7,
                ),
                child: InkWell(
                  onTap: () => setState(() => selectedDate = index),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 72,
                    decoration: BoxDecoration(
                      color: selected ? ElderColors.darkTeal : Colors.white,
                      border: Border.all(
                        color: selected
                            ? ElderColors.darkTeal
                            : ElderColors.border,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdays[dates[index].weekday - 1],
                          style: TextStyle(
                            color: selected
                                ? Colors.white70
                                : ElderColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dates[index].day.toString(),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : ElderColors.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _timeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available times',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _timeButton(0)),
            const SizedBox(width: 9),
            Expanded(child: _timeButton(1)),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(child: _timeButton(2)),
            const SizedBox(width: 9),
            Expanded(child: _timeButton(3)),
          ],
        ),
      ],
    );
  }

  Widget _timeButton(int index) {
    final selected = index == selectedTime;

    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: () => setState(() => selectedTime = index),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? ElderColors.darkTeal : Colors.white,
          foregroundColor: selected ? Colors.white : ElderColors.deepTeal,
          side: BorderSide(
            color: selected ? ElderColors.darkTeal : ElderColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          times[index],
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _notificationCard() {
    return Container(
      width: double.infinity,
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
              Icons.event_available_outlined,
              color: ElderColors.deepTeal,
              size: 19,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your selected time will be saved to the check-in schedule.',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 10,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Column(
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
    );
  }
}
