import 'package:flutter/material.dart';

import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'my_schedule_screen.dart';
import 'nethmi_ready_screen.dart';

class RescheduleCheckInScreen extends StatefulWidget {
  final String checkInId;

  const RescheduleCheckInScreen({super.key, this.checkInId = 'checkin-001'});

  @override
  State<RescheduleCheckInScreen> createState() =>
      _RescheduleCheckInScreenState();
}

class _RescheduleCheckInScreenState extends State<RescheduleCheckInScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  int selectedDate = 1;
  int selectedTime = 2;
  bool _saving = false;

  static const dates = [
    ('Wed', '16'),
    ('Thu', '17'),
    ('Fri', '18'),
    ('Sat', '19'),
    ('Sun', '20'),
  ];

  static const times = ['5:30 PM', '6:30 PM', '7:00 PM', '7:30 PM'];

  Future<void> _saveNewTime() async {
    if (_saving) return;

    setState(() => _saving = true);

    final day = 16 + selectedDate;
    final selectedHours = [17, 18, 19, 19];
    final selectedMinutes = [30, 30, 0, 30];

    await _service.rescheduleCheckIn(
      widget.checkInId,
      DateTime(
        2026,
        10,
        day,
        selectedHours[selectedTime],
        selectedMinutes[selectedTime],
      ),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NethmiReadyScreen()),
    );
  }

  Future<void> _cancelCheckIn() async {
    final ok = await elderConfirm(
      context,
      title: 'Cancel this check-in?',
      message: 'Nethmi will be notified if you cancel this check-in.',
      confirmLabel: 'Cancel check-in',
      destructive: true,
    );

    if (!ok || !mounted) return;

    await _service.cancelCheckIn(widget.checkInId);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MyScheduleScreen()),
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
            const SizedBox(height: 14),
            Expanded(
              child: Column(
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
    return Container(
      height: 102,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal, width: 1.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ElderAvatar(asset: ElderAssets.nethmiAvatar, size: 54, border: false),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nethmi',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Wednesday • 6:30 PM',
                  style: TextStyle(color: ElderColors.textMuted, fontSize: 9.5),
                ),
              ],
            ),
          ),
          ElderStatusPill('VIDEO'),
        ],
      ),
    );
  }

  Widget _dateSection() {
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
                          dates[index].$1,
                          style: TextStyle(
                            color: selected
                                ? Colors.white70
                                : ElderColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dates[index].$2,
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
              Icons.notifications_active_outlined,
              color: ElderColors.deepTeal,
              size: 19,
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Nethmi will be notified of your new time.',
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
            onPressed: _cancelCheckIn,
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
