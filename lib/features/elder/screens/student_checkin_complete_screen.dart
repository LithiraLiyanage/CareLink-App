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
    this.callCompleted = true,
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
  final bool callCompleted;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    final initials = elderName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final title = callCompleted ? 'Check-in complete' : 'Call ended';
    final subtitle = callCompleted
        ? 'Your check-in with $elderName was completed successfully.'
        : 'Your call with $elderName has ended safely.';
    final status = callCompleted ? 'COMPLETED' : 'ENDED';

    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ElderColors.mintSoft.withValues(
                                alpha: .48,
                              ),
                            ),
                          ),
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: ElderColors.deepTeal.withValues(
                                  alpha: .14,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .07),
                                  blurRadius: 20,
                                  offset: const Offset(0, 9),
                                ),
                              ],
                            ),
                            child: Icon(
                              callCompleted
                                  ? Icons.check_rounded
                                  : Icons.call_end_rounded,
                              size: 38,
                              color: ElderColors.deepTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ElderColors.mintSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          callCompleted ? 'CHECK-IN FINISHED' : 'CALL FINISHED',
                          style: const TextStyle(
                            color: ElderColors.darkTeal,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ElderColors.textDark,
                          fontSize: 25,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.45,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 10.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ElderColors.deepTeal.withValues(alpha: .28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .045),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ElderColors.mintSoft,
                                border: Border.all(
                                  color: ElderColors.deepTeal.withValues(
                                    alpha: .12,
                                  ),
                                ),
                              ),
                              child:
                                  elderImageUrl == null ||
                                      elderImageUrl!.trim().isEmpty
                                  ? Center(
                                      child: Text(
                                        initials.isEmpty ? '?' : initials,
                                        style: const TextStyle(
                                          color: ElderColors.darkTeal,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    )
                                  : ClipOval(
                                      child: Image.network(
                                        elderImageUrl!,
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Center(
                                          child: Text(
                                            initials.isEmpty ? '?' : initials,
                                            style: const TextStyle(
                                              color: ElderColors.darkTeal,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    elderName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: ElderColors.textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$callType check-in  •  '
                                    '${localizations.formatMediumDate(scheduledAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ElderColors.mintSoft,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: ElderColors.deepTeal.withValues(
                                    alpha: .20,
                                  ),
                                ),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: ElderColors.darkTeal,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryBox(
                              icon: Icons.schedule_rounded,
                              label: 'Planned duration',
                              value: '$durationMinutes min',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryBox(
                              icon: callType.toLowerCase() == 'voice'
                                  ? Icons.call_rounded
                                  : Icons.videocam_rounded,
                              label: 'Check-in type',
                              value: callType,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ElderColors.mintSoft.withValues(alpha: .68),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: ElderColors.deepTeal.withValues(alpha: .11),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                color: ElderColors.deepTeal,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keep the connection going',
                                    style: TextStyle(
                                      color: ElderColors.textDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Save a photo or a small moment from today in Memory Lane.',
                                    style: TextStyle(
                                      color: ElderColors.textMuted,
                                      fontSize: 9.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
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
                height: 49,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.home_outlined, size: 17),
                  label: const Text(
                    'Back to home',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ElderColors.deepTeal,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: ElderColors.deepTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ElderColors.mintSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ElderColors.deepTeal, size: 16),
          ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
