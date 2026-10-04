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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Photos', 'Voice', 'Songs'];

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
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: ElderColors.darkTeal,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ElderBackButton(
                      filled: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 7),
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: ElderColors.darkTeal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'CareLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const ElderAvatar(
                      asset: ElderAssets.kamalaAvatar,
                      size: 40,
                      border: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Memory Lane',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Stories, photos and moments you love',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: List.generate(filters.length, (i) {
                    final selected = filter == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 3 ? 0 : 5),
                        child: SizedBox(
                          height: 34,
                          child: OutlinedButton(
                            onPressed: () => setState(() => filter = i),
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  selected ? Colors.white : Colors.transparent,
                              foregroundColor:
                                  selected ? ElderColors.darkTeal : Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              filters[i],
                              style: const TextStyle(fontSize: 8.5),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Column(
                children: [
                  _photoCard(),
                  const SizedBox(height: 8),
                  _voiceCard(),
                  const SizedBox(height: 8),
                  _songCard(),
                  const SizedBox(height: 9),
                  ElderPrimaryButton(
                    label: '+  Add a memory',
                    color: ElderColors.coral,
                    height: 50,
                    onPressed: () => _open(const AddMemoryScreen()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(13),
            ),
            child: Image.asset(
              ElderAssets.familyMemory,
              height: 205,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(9),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A favourite family moment',
                    style: TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }

  Widget _voiceCard() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          ElderAvatar(
            asset: ElderAssets.kamalaAvatar,
            size: 36,
            border: false,
          ),
          SizedBox(width: 7),
          CircleAvatar(
            radius: 17,
            backgroundColor: ElderColors.darkTeal,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Listen to Amma's Story",
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                LinearProgressIndicator(
                  value: .58,
                  minHeight: 3,
                  color: ElderColors.deepTeal,
                  backgroundColor: ElderColors.mintSoft,
                ),
              ],
            ),
          ),
          SizedBox(width: 6),
          Text(
            '02:45',
            style: TextStyle(
              color: ElderColors.textMuted,
              fontSize: 7.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _songCard() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ElderColors.deepTeal,
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favourite Song',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                LinearProgressIndicator(
                  value: .52,
                  minHeight: 3,
                  color: Color(0xFFD6A64B),
                  backgroundColor: Color(0xFFD3E5E2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
