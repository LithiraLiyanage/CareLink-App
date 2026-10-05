import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'memory_lane_screen.dart';
import 'new_recurring_checkin_screen.dart';
import 'nethmi_ready_screen.dart';
import 'reschedule_checkin_screen.dart';

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 1,
        onSchedule: () {},
        onMemory: () => _open(context, const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(context),
            const SizedBox(height: 10),
            const Text(
              'My Schedule',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your upcoming companion check-ins',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  _scheduleCard(
                    context,
                    time: 'Today • 6:30 PM',
                    subtitle: 'Nethmi • Video',
                    badge: 'NEXT',
                    filledBadge: true,
                    onTap: () => _open(
                      context,
                      const NethmiReadyScreen(),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _scheduleCard(
                    context,
                    time: 'Wed • 6:30 PM',
                    subtitle: 'Nethmi • Video',
                    badge: 'RECURRING',
                    onTap: () => _open(
                      context,
                      const RescheduleCheckInScreen(),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _scheduleCard(
                    context,
                    time: 'Fri • 6:30 PM',
                    subtitle: 'Nethmi • Video',
                    badge: 'RECURRING',
                    onTap: () => _open(
                      context,
                      const RescheduleCheckInScreen(),
                    ),
                  ),
                  const Spacer(),
                  ElderPrimaryButton(
                    label: '+  Create recurring check-in',
                    color: ElderColors.darkTeal,
                    height: 54,
                    onPressed: () => _open(
                      context,
                      const NewRecurringCheckInScreen(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x66005B59),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: ElderColors.darkTeal,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: ElderColors.darkTeal,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'CareLink',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    Widget tab(String label, {bool selected = false}) {
      return Expanded(
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ElderColors.textDark,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ElderColors.mint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          tab('Today'),
          tab('Upcoming', selected: true),
          tab('Past'),
        ],
      ),
    );
  }

  Widget _scheduleCard(
    BuildContext context, {
    required String time,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
    bool filledBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0x6693CFC4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x09000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const ElderAvatar(
              asset: ElderAssets.nethmiAvatar,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElderStatusPill(
              badge,
              filled: filledBadge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0x66A7EEE0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x6693CFC4),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.info_outline_rounded,
              color: ElderColors.darkTeal,
              size: 19,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can reschedule or cancel any session.',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 9.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
