import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'my_schedule_screen.dart';

class RescheduleCheckInScreen extends StatefulWidget {
  const RescheduleCheckInScreen({super.key});

  @override
  State<RescheduleCheckInScreen> createState() =>
      _RescheduleCheckInScreenState();
}

class _RescheduleCheckInScreenState extends State<RescheduleCheckInScreen> {
  int selectedDate = 1;
  int selectedTime = 2;

  @override
  Widget build(BuildContext context) {
    const dates = [
      ('Wed', '16'),
      ('Thu', '17'),
      ('Fri', '18'),
      ('Sat', '19'),
      ('Sun', '20'),
    ];
    const times = ['5:30 PM', '6:30 PM', '7:00 PM', '7:30 PM'];

    return ElderPhoneScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElderBackButton(onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 10),
            const Text(
              'Reschedule check-in',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Choose a new day and time',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 13),
            Container(
              height: 94,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ElderColors.deepTeal),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  ElderAvatar(
                    asset: ElderAssets.nethmiAvatar,
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
                          'Nethmi',
                          style: TextStyle(
                            color: ElderColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Wednesday • 6:30 PM',
                          style: TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElderStatusPill('VIDEO'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Choose a new date',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: List.generate(dates.length, (i) {
                final selected = i == selectedDate;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == dates.length - 1 ? 0 : 6,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => selectedDate = i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: selected
                              ? ElderColors.darkTeal
                              : Colors.white,
                          border: Border.all(color: ElderColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dates[i].$1,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white70
                                    : ElderColors.textMuted,
                                fontSize: 8.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dates[i].$2,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : ElderColors.textDark,
                                fontSize: 15,
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
            const SizedBox(height: 14),
            const Text(
              'Available times',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            GridView.builder(
              itemCount: times.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
                childAspectRatio: 4.0,
              ),
              itemBuilder: (context, i) {
                final selected = i == selectedTime;
                return OutlinedButton(
                  onPressed: () => setState(() => selectedTime = i),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? ElderColors.darkTeal
                        : Colors.white,
                    foregroundColor:
                        selected ? Colors.white : ElderColors.deepTeal,
                    side: const BorderSide(color: ElderColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(
                    times[i],
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const ElderInfoCard(
              icon: Icons.notifications_active_outlined,
              title: 'Nethmi will be notified of your new',
              subtitle: 'time.',
            ),
            const Spacer(),
            ElderPrimaryButton(
              label: 'Save new time',
              height: 52,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MyScheduleScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () async {
                  final ok = await elderConfirm(
                    context,
                    title: 'Cancel this check-in?',
                    message:
                        'Nethmi will be notified if you cancel this check-in.',
                    confirmLabel: 'Cancel check-in',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC94354),
                  backgroundColor: ElderColors.dangerSoft,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel this check-in',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
