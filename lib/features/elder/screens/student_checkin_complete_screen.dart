import 'package:flutter/material.dart';

import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'memory_lane_screen.dart';

class StudentCheckInCompleteScreen extends StatelessWidget {
  const StudentCheckInCompleteScreen({
    super.key,
    required this.elderName,
    required this.elderId,
    required this.elderImageUrl,
    required this.companionId,
    required this.connectionId,
    required this.checkInId,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.callType,
  });

  final String elderName;
  final String elderId;
  final String? elderImageUrl;
  final String companionId;
  final String connectionId;
  final String checkInId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String callType;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final initials = elderName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: ElderColors.mintSoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ElderColors.deepTeal,
                            width: 1.3,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: ElderColors.deepTeal,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Check-in complete',
                        style: TextStyle(
                          color: ElderColors.textDark,
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Your check-in with $elderName is complete.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ElderColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 94,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ElderColors.deepTeal),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: ElderColors.mintSoft,
                          child: elderImageUrl == null || elderImageUrl!.isEmpty
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: ElderColors.darkTeal,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : ClipOval(
                                  child: Image.network(
                                    elderImageUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Text(
                                      initials,
                                      style: const TextStyle(
                                        color: ElderColors.darkTeal,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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
                                elderName,
                                style: const TextStyle(
                                  color: ElderColors.textDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$callType check-in · '
                                '${localizations.formatMediumDate(scheduledAt)}',
                                style: const TextStyle(
                                  color: ElderColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const ElderStatusPill('COMPLETED'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(
                          icon: Icons.schedule_rounded,
                          label: 'Duration',
                          value: '$durationMinutes min',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _SummaryBox(
                          icon: Icons.video_call_outlined,
                          label: 'Check-in type',
                          value: callType,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElderPrimaryButton(
                  label: 'View Memory Lane',
                  height: 54,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MemoryLaneScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ElderColors.deepTeal,
                      side: const BorderSide(color: ElderColors.deepTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to home',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
