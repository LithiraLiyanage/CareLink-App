import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'elder_home_screen.dart';
import 'memory_lane_screen.dart';

class CheckInCompleteKamalaScreen extends StatelessWidget {
  const CheckInCompleteKamalaScreen({super.key});

  void _replace(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onHome: () => _replace(context, const ElderHomeScreen()),
        onMemory: () => _replace(context, const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElderBackButton(onPressed: () => Navigator.pop(context)),
            ),
            const SizedBox(height: 8),
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: ElderColors.mintSoft,
                shape: BoxShape.circle,
                border: Border.all(color: ElderColors.deepTeal),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: ElderColors.textDark,
                size: 38,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Check-in complete',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'A lovely 28-minute conversation with Nethmi',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(child: _SummaryBox('Duration', '28 min')),
                SizedBox(width: 8),
                Expanded(child: _SummaryBox('Reflection', 'Good')),
                SizedBox(width: 8),
                Expanded(child: _SummaryBox('Next', 'Wed 6:30')),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ElderColors.deepTeal),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  ElderAvatar(
                    asset: ElderAssets.kamalaAvatar,
                    size: 44,
                    border: false,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kamala Perera',
                          style: TextStyle(
                            color: ElderColors.textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Video check-in • Today',
                          style: TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElderStatusPill('COMPLETED'),
                ],
              ),
            ),
            const SizedBox(height: 13),
            const ElderInfoCard(
              icon: Icons.check_rounded,
              title: 'Family visibility is off',
              subtitle: 'Nothing is shared without your consent.',
            ),
            const Spacer(),
            ElderPrimaryButton(
              label: 'Back to home',
              height: 52,
              onPressed: () => _replace(context, const ElderHomeScreen()),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: ElderOutlineButton(
                label: 'View Memory Lane',
                onPressed: () => _replace(context, const MemoryLaneScreen()),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ElderColors.textMuted,
              fontSize: 8,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
