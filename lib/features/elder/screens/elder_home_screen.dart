import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'memory_lane_screen.dart';
import 'my_schedule_screen.dart';

class ElderHomeScreen extends StatelessWidget {
  const ElderHomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.darkTeal,
      darkStatusBar: false,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onSchedule: () => _open(context, const MyScheduleScreen()),
        onMemory: () => _open(context, const MemoryLaneScreen()),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            _checkInCard(context),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 9),
              child: Text(
                'Quick actions',
                style: TextStyle(
                  color: ElderColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _quickActions(context),
            const SizedBox(height: 14),
            _reminder(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 165,
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 14),
      decoration: const BoxDecoration(
        color: ElderColors.darkTeal,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  'C',
                  style: TextStyle(
                    color: ElderColors.darkTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'CareLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  Positioned(
                    right: 1,
                    top: 0,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ElderColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, Kamala',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your next check-in is ready',
                      style: TextStyle(
                        color: Color(0xFFD7EBE8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              ElderAvatar(
                asset: ElderAssets.kamalaAvatar,
                size: 66,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkInCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              child: Stack(
                children: [
                  Image.asset(
                    ElderAssets.homeCheckin,
                    width: double.infinity,
                    height: 170,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      color: const Color(0xB9144A47),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nethmi • verified companion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ElderStatusPill('TODAY', filled: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: ElderColors.darkTeal,
                        size: 23,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '6:30 PM',
                              style: TextStyle(
                                color: ElderColors.textDark,
                                fontSize: 22,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '30 min • Video check-in',
                              style: TextStyle(
                                color: ElderColors.textMuted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  ElderPrimaryButton(
                    label: 'Find a Companion',
                    color: ElderColors.coral,
                    height: 52,
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.companionMatching),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    Widget item(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: ElderColors.mint,
              border: Border.all(color: ElderColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: ElderColors.textDark,
                  size: 27,
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          item(
            Icons.schedule_rounded,
            'Schedule',
            () => _open(context, const MyScheduleScreen()),
          ),
          const SizedBox(width: 8),
          item(
            Icons.menu_book_rounded,
            'Memory Lane',
            () => _open(context, const MemoryLaneScreen()),
          ),
          const SizedBox(width: 8),
          item(
            Icons.help_outline_rounded,
            'Need Help',
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Help options will open here.'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: ElderColors.success,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ElderColors.coral,
            child: Icon(
              Icons.favorite_border_rounded,
              color: ElderColors.textDark,
              size: 21,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A gentle reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Take your time. You can end or\nreschedule anytime.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
