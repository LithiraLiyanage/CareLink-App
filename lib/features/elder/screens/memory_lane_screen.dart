import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'add_memory_screen.dart';
import 'elder_home_screen.dart';
import 'my_schedule_screen.dart';

class MemoryLaneScreen extends StatefulWidget {
  const MemoryLaneScreen({super.key});

  @override
  State<MemoryLaneScreen> createState() => _MemoryLaneScreenState();
}

class _MemoryLaneScreenState extends State<MemoryLaneScreen> {
  int filter = 0;

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.cream,
      statusBarColor: ElderColors.darkTeal,
      darkStatusBar: false,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 2,
        onHome: () => _open(const ElderHomeScreen()),
        onSchedule: () => _open(const MyScheduleScreen()),
      ),
      child: Column(
        children: [
          _header(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _photoCard(),
                  _voiceCard(),
                  _songCard(),
                  ElderPrimaryButton(
                    label: '+  Add a memory',
                    color: ElderColors.coral,
                    height: 54,
                    onPressed: () => _open(
                      const AddMemoryScreen(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    const filters = ['All', 'Photos', 'Voice', 'Songs'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: const BoxDecoration(
        color: ElderColors.darkTeal,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ElderBackButton(
                filled: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 9),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const ElderAvatar(
                asset: ElderAssets.kamalaAvatar,
                size: 44,
                border: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Memory Lane',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Stories, photos and moments you love',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(filters.length, (index) {
              final selected = filter == index;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == filters.length - 1 ? 0 : 6,
                  ),
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          filter = index;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            selected ? Colors.white : Colors.transparent,
                        foregroundColor:
                            selected ? ElderColors.darkTeal : Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        filters[index],
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _photoCard() {
    return Container(
      height: 238,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15),
            ),
            child: Image.asset(
              ElderAssets.familyMemory,
              height: 174,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ElderColors.mintSoft,
                    child: Icon(
                      Icons.photo_outlined,
                      color: ElderColors.deepTeal,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A favourite family moment',
                          style: TextStyle(
                            color: ElderColors.textDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Colombo • Jan 1998',
                          style: TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voiceCard() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          ElderAvatar(
            asset: ElderAssets.kamalaAvatar,
            size: 42,
            border: false,
          ),
          SizedBox(width: 9),
          CircleAvatar(
            radius: 19,
            backgroundColor: ElderColors.darkTeal,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Listen to Amma's Story",
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: .58,
                  minHeight: 4,
                  color: ElderColors.deepTeal,
                  backgroundColor: ElderColors.mintSoft,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            '02:45',
            style: TextStyle(
              color: ElderColors.textMuted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _songCard() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ElderColors.deepTeal,
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favourite Song',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: .52,
                  minHeight: 4,
                  color: Color(0xFFD6A64B),
                  backgroundColor: Color(0xFFD3E5E2),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Icon(
            Icons.play_circle_outline_rounded,
            color: ElderColors.deepTeal,
            size: 25,
          ),
        ],
      ),
    );
  }
}
