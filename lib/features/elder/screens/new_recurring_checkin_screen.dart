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
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _header(context),
            _stepIndicator(),
            _repeatSection(),
            _fieldSection(
              label: 'Time',
              icon: Icons.schedule_rounded,
              value: '6:30 PM',
            ),
            _fieldSection(
              label: 'Duration',
              icon: Icons.timelapse_rounded,
              value: '30 minutes',
            ),
            _elderSection(),
            _actions(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElderBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 10),
        const Text(
          'New recurring check-in',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create a routine that feels comfortable',
          style: TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _stepIndicator() {
    return Row(
      children: const [
        Expanded(
          child: _Step(
            number: '1',
            label: 'Schedule',
            active: true,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _Step(
            number: '2',
            label: 'Companion',
            active: false,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _Step(
            number: '3',
            label: 'Confirm',
            active: false,
          ),
        ),
      ],
    );
  }

  Widget _repeatSection() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat on',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(days.length, (index) {
            final selected = selectedDays.contains(index);

            return InkWell(
              onTap: () {
                setState(() {
                  if (selected) {
                    selectedDays.remove(index);
                  } else {
                    selectedDays.add(index);
                  }
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? ElderColors.darkTeal : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? ElderColors.darkTeal
                        : const Color(0xFFDCE9E7),
                  ),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x14005B59),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  days[index],
                  style: TextStyle(
                    color: selected ? Colors.white : ElderColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _fieldSection({
    required String label,
    required IconData icon,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFDCE9E7),
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ElderColors.mintSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: ElderColors.deepTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ElderColors.textMuted,
                size: 21,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _elderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elder',
          style: TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: ElderColors.deepTeal,
              width: 1.1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              ElderAvatar(
                asset: ElderAssets.kamalaAvatar,
                size: 54,
                border: false,
              ),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Selected elder',
                      style: TextStyle(
                        color: ElderColors.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElderStatusPill(
                'SELECTED',
                filled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
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
        const SizedBox(height: 9),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_calendar_outlined,
              size: 13,
              color: ElderColors.textMuted,
            ),
            SizedBox(width: 5),
            Text(
              'You can edit this anytime from My Schedule.',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String label;
  final bool active;

  const _Step({
    required this.number,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: active ? ElderColors.deepTeal : const Color(0xFFD7E6E3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 21,
              height: 21,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? ElderColors.darkTeal : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? ElderColors.darkTeal : ElderColors.border,
                ),
              ),
              child: Text(
                number,
                style: TextStyle(
                  color: active ? Colors.white : ElderColors.textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? ElderColors.deepTeal : ElderColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
