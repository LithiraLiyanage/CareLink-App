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
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 0,
        onHome: () => _replace(context, const ElderHomeScreen()),
        onMemory: () => _replace(context, const MemoryLaneScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElderBackButton(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _completeHeader(),
                  const _SummaryRow(),
                  _personCard(),
                  const _ConsentCard(),
                  _actions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completeHeader() {
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
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'A lovely 28-minute conversation with Nethmi',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _personCard() {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.deepTeal),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          ElderAvatar(asset: ElderAssets.kamalaAvatar, size: 52, border: false),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamala Perera',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Video check-in • Today',
                  style: TextStyle(color: ElderColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
          ElderStatusPill('COMPLETED'),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        ElderPrimaryButton(
          label: 'Back to home',
          height: 54,
          onPressed: () => _replace(context, const ElderHomeScreen()),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElderOutlineButton(
            label: 'View Memory Lane',
            height: 48,
            onPressed: () => _replace(context, const MemoryLaneScreen()),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _SummaryBox(
            icon: Icons.schedule_rounded,
            label: 'Duration',
            value: '28 min',
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _SummaryBox(
            icon: Icons.favorite_outline_rounded,
            label: 'Reflection',
            value: 'Good',
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _SummaryBox(
            icon: Icons.event_available_outlined,
            label: 'Next',
            value: 'Wed 6:30',
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.value,
  });

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
                  'Family visibility is off',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Nothing is shared without your consent.',
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
