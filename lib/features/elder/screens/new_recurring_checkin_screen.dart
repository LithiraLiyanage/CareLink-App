import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../models/recurring_schedule.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'reschedule_checkin_screen.dart';

class NewRecurringCheckInScreen extends StatefulWidget {
  const NewRecurringCheckInScreen({super.key});

  @override
  State<NewRecurringCheckInScreen> createState() =>
      _NewRecurringCheckInScreenState();
}

class _NewRecurringCheckInScreenState extends State<NewRecurringCheckInScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  final Set<int> selectedDays = {0, 2, 4};
  late Future<ElderFlowContext> _connectionFuture;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 30);
  int _durationMinutes = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _connectionFuture = _service.getCurrentFlowContext();
  }

  void _retryConnection() {
    setState(() {
      _connectionFuture = _service.getCurrentFlowContext();
    });
  }

  String _timeLabel() {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Choose check-in time',
    );
    if (selected != null && mounted) {
      setState(() => _selectedTime = selected);
    }
  }

  Future<void> _chooseDuration() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Check-in duration')),
            for (final minutes in [15, 30, 45, 60])
              ListTile(
                title: Text('$minutes minutes'),
                trailing: _durationMinutes == minutes
                    ? const Icon(Icons.check, color: ElderColors.deepTeal)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(minutes),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _durationMinutes = selected);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createSchedule() async {
    if (_saving) return;
    if (selectedDays.isEmpty) {
      _showError('Select at least one repeat day.');
      return;
    }

    setState(() => _saving = true);

    String writeStage = 'loading active connection';
    try {
      final connection = await _connectionFuture;
      writeStage = 'creating recurring_schedules document';
      final schedule = await _service.createRecurringSchedule(
        RecurringSchedule(
          id: '',
          elderId: connection.elderId,
          elderName: connection.elderName,
          companionId: connection.companionId,
          companionName: connection.companionName,
          weekdays: selectedDays.map((index) => index + 1).toList()..sort(),
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          durationMinutes: _durationMinutes,
          isActive: true,
        ),
      );

      // Use an actual Firestore ID, not a demo ID like 'checkin-001'.
      // If the second write fails, undo the newly created routine where possible.
      late final CheckIn checkIn;
      try {
        writeStage = 'creating check_ins document';
        checkIn = await _service.createInitialCheckInForSchedule(schedule);
      } catch (_) {
        try {
          await _service.deleteRecurringSchedule(schedule.id);
        } catch (_) {
          // A cleanup failure should not hide the original write failure.
        }
        rethrow;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RescheduleCheckInScreen(checkInId: checkIn.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      debugPrint('CareLink write stage: $writeStage | $error');
      _showError('Failed at $writeStage: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
              value: _timeLabel(),
              onTap: _chooseTime,
            ),
            _fieldSection(
              label: 'Duration',
              icon: Icons.timelapse_rounded,
              value: '$_durationMinutes minutes',
              onTap: _chooseDuration,
            ),
            _elderSection(),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElderBackButton(onPressed: () => Navigator.of(context).maybePop()),
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
          child: _Step(number: '1', label: 'Schedule', active: true),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _Step(number: '2', label: 'Companion', active: false),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _Step(number: '3', label: 'Confirm', active: false),
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
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDCE9E7)),
              borderRadius: BorderRadius.circular(15),
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
                  child: Icon(icon, color: ElderColors.deepTeal, size: 18),
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
            border: Border.all(color: ElderColors.deepTeal, width: 1.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: FutureBuilder<ElderFlowContext>(
            future: _connectionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: ElderColors.darkTeal),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: ElderColors.darkTeal,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Cannot load your Elder connection.',
                        maxLines: 2,
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    TextButton(
                      onPressed: _retryConnection,
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }

              final elderName = snapshot.data!.elderName;
              final isExampleKamala = elderName.toLowerCase().contains(
                'kamala',
              );

              return Row(
                children: [
                  if (isExampleKamala)
                    const ElderAvatar(
                      asset: ElderAssets.kamalaAvatar,
                      size: 54,
                      border: false,
                    )
                  else
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: ElderColors.mintSoft,
                      child: Text(
                        elderName.isEmpty ? '?' : elderName[0].toUpperCase(),
                        style: const TextStyle(
                          color: ElderColors.darkTeal,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ElderColors.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Connected elder',
                          style: TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ElderStatusPill('SELECTED', filled: true),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Column(
      children: [
        ElderPrimaryButton(
          label: _saving ? 'Creating...' : 'Create schedule',
          color: ElderColors.coral,
          height: 54,
          onPressed: _createSchedule,
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
              style: TextStyle(color: ElderColors.textMuted, fontSize: 9),
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
