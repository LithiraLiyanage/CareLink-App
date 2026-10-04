import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'elder_home_screen.dart';
import 'memory_lane_screen.dart';
import 'new_recurring_checkin_screen.dart';
import 'nethmi_ready_screen.dart';
import 'reschedule_checkin_screen.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  int tab = 1;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 1,
        onHome: () => _open(const ElderHomeScreen()),
        onMemory: () => _open(const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElderBackButton(onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 7),
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: ElderColors.darkTeal,
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'CareLink',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'My Schedule',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Your upcoming companion check-ins',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 14),
            _tabs(),
            const SizedBox(height: 12),
            _session(
              title: 'Today • 6:30 PM',
              subtitle: 'Nethmi • Video',
              status: 'NEXT',
              onTap: () => _open(const NethmiReadyScreen()),
            ),
            const SizedBox(height: 13),
            _session(
              title: 'Wed • 6:30 PM',
              subtitle: 'Nethmi • Video',
              status: 'RECURRING',
              onTap: () => _open(const RescheduleCheckInScreen()),
            ),
            const SizedBox(height: 13),
            _session(
              title: 'Fri • 6:30 PM',
              subtitle: 'Nethmi • Voice',
              status: 'RECURRING',
              onTap: () => _open(const RescheduleCheckInScreen()),
            ),
            const Spacer(),
            ElderPrimaryButton(
              label: '+  Create recurring check-in',
              height: 54,
              onPressed: () => _open(const NewRecurringCheckInScreen()),
            ),
            const SizedBox(height: 10),
            const ElderInfoCard(
              icon: Icons.info_outline_rounded,
              title: 'You can reschedule or cancel any',
              subtitle: 'session.',
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Today', 'Upcoming', 'Past'];

    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF82E8D8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = tab == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => tab = i),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  labels[i],
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _session({
    required String title,
    required String subtitle,
    required String status,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 98,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ElderColors.border),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const ElderAvatar(
              asset: ElderAssets.nethmiAvatar,
              size: 42,
              border: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            ElderStatusPill(status, filled: status == 'NEXT'),
          ],
        ),
      ),
    );
  }
}
