import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'my_schedule_screen.dart';

class NewRecurringCheckInScreen extends StatefulWidget {
  const NewRecurringCheckInScreen({super.key});

  @override
  State<NewRecurringCheckInScreen> createState() =>
      _NewRecurringCheckInScreenState();
}

class _NewRecurringCheckInScreenState
    extends State<NewRecurringCheckInScreen> {
  final Set<int> selectedDays = {0, 2, 4};

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return ElderPhoneScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElderBackButton(onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 10),
            const Text(
              'New recurring check-in',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Create a routine that feels comfortable',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            _stepIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Repeat on',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(days.length, (i) {
                final selected = selectedDays.contains(i);
                return InkWell(
                  onTap: () {
                    setState(() {
                      selected ? selectedDays.remove(i) : selectedDays.add(i);
                    });
                  },
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor:
                        selected ? ElderColors.darkTeal : Colors.white,
                    child: Text(
                      days[i],
                      style: TextStyle(
                        color:
                            selected ? Colors.white : ElderColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            _fieldLabel('Time'),
            const SizedBox(height: 5),
            _field(Icons.schedule_rounded, '6:30 PM'),
            const SizedBox(height: 11),
            _fieldLabel('Duration'),
            const SizedBox(height: 5),
            _field(Icons.remove_rounded, '30 minutes'),
            const SizedBox(height: 11),
            _fieldLabel('Elder'),
            const SizedBox(height: 5),
            Container(
              height: 92,
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
                    size: 46,
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
                          'Verified student companion',
                          style: TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElderStatusPill('SELECTED', filled: true),
                ],
              ),
            ),
            const Spacer(),
            ElderPrimaryButton(
              label: 'Create schedule',
              color: ElderColors.coral,
              height: 54,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MyScheduleScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'You can edit this anytime from My Schedule.',
                style: TextStyle(
                  color: ElderColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Row(
      children: const [
        Expanded(child: _Step('1', 'Schedule', true)),
        Expanded(child: _Step('2', 'Companion', false)),
        Expanded(child: _Step('3', 'Confirm', false)),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: ElderColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _field(IconData icon, String text) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE9E7)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: ElderColors.mintSoft,
            child: Icon(icon, size: 16, color: ElderColors.deepTeal),
          ),
          const SizedBox(width: 9),
          Text(
            text,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String label;
  final bool active;

  const _Step(this.number, this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          thickness: 2,
          color: active ? ElderColors.deepTeal : ElderColors.border,
        ),
        const SizedBox(height: 3),
        Text(
          '$number  $label',
          style: TextStyle(
            color: active ? ElderColors.deepTeal : ElderColors.textMuted,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
