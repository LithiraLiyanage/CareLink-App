import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../models/recurring_schedule.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'reschedule_checkin_screen.dart';

class NewRecurringCheckInScreen extends StatefulWidget {
  const NewRecurringCheckInScreen({
    super.key,
    this.connectionId,
    this.elderId,
    this.elderName,
    this.companionId,
    this.companionName,
    this.preferredCheckInType,
    this.navigationOnly = false,
  });

  final String? connectionId;
  final String? elderId;
  final String? elderName;
  final String? companionId;
  final String? companionName;
  final String? preferredCheckInType;
  final bool navigationOnly;

  @override
  State<NewRecurringCheckInScreen> createState() =>
      _NewRecurringCheckInScreenState();
}

class _NewRecurringCheckInScreenState extends State<NewRecurringCheckInScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  final Set<int> selectedDays = {};
  TimeOfDay? _selectedTime;
  int? _durationMinutes;
  String? _mode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final requestedType = widget.preferredCheckInType?.trim();
    if (requestedType == 'Video' || requestedType == 'Voice') {
      _mode = requestedType;
    }
  }

  Future<void> _createSchedule() async {
    if (_saving) return;

    if (widget.navigationOnly) {
      final now = DateTime.now();
      final time = _selectedTime ?? const TimeOfDay(hour: 10, minute: 0);
      final preview = CheckIn(
        id: '',
        elderId: widget.elderId ?? '',
        elderName: widget.elderName ?? '',
        elderImageUrl: null,
        companionId: widget.companionId ?? '',
        companionName: widget.companionName ?? '',
        scheduledAt: DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        ),
        durationMinutes: _durationMinutes ?? 30,
        mode: _mode ?? widget.preferredCheckInType ?? 'Video',
        status: CheckInStatus.scheduled,
      );
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RescheduleCheckInScreen(
            initialCheckIn: preview,
            navigationOnly: true,
          ),
        ),
      );
      return;
    }

    try {
      final connection =
          widget.connectionId == null ||
              widget.elderId == null ||
              widget.companionId == null ||
              widget.companionName?.trim().isEmpty != false
          ? await _service.getActiveConnectionForCurrentElder()
          : null;

      final connectionId = widget.connectionId ?? connection?.id;
      final elderId = widget.elderId ?? connection?.elderId;
      var elderName = widget.elderName?.trim() ?? '';
      final companionId = widget.companionId ?? connection?.companionId;
      var companionName = widget.companionName?.trim() ?? '';

      if (elderName.isEmpty) {
        elderName = connection?.elderName.trim() ?? '';
      }
      if (elderName.isEmpty) {
        elderName = (await _service.getCurrentElderName()).trim();
      }
      if (companionName.isEmpty) {
        companionName = connection?.companionName.trim() ?? '';
      }

      if (connectionId == null || connectionId.isEmpty) {
        throw StateError(
          'An active companion connection is required to schedule.',
        );
      }
      if (elderId == null || elderId.isEmpty) {
        throw StateError('Could not identify the Older Adult account.');
      }
      if (companionId == null || companionId.isEmpty || companionName.isEmpty) {
        throw StateError('Could not identify the connected companion.');
      }
      if (selectedDays.isEmpty) {
        throw StateError('Choose at least one day.');
      }
      if (_selectedTime == null) {
        throw StateError('Choose a time.');
      }
      if (_durationMinutes == null) {
        throw StateError('Choose a duration.');
      }
      if (_mode == null) {
        throw StateError('Choose Video or Voice.');
      }

      final schedule = RecurringSchedule(
        id: '',
        elderId: elderId,
        elderName: elderName,
        companionId: companionId,
        companionName: companionName,
        connectionId: connectionId,
        mode: _mode!,
        weekdays: selectedDays.map((index) => index + 1).toList()..sort(),
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        durationMinutes: _durationMinutes!,
        isActive: true,
      );

      final nextOccurrence = schedule.nextOccurrence(DateTime.now());
      if (nextOccurrence == null) {
        throw StateError('Could not calculate the next check-in.');
      }

      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final selectedDayNames = schedule.weekdays
          .where((day) => day >= 1 && day <= 7)
          .map((day) => dayNames[day - 1])
          .join(', ');

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm check-in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Companion: $companionName'),
              const SizedBox(height: 8),
              Text('Repeat: $selectedDayNames'),
              const SizedBox(height: 8),
              Text('Time: ${_selectedTime!.format(context)}'),
              const SizedBox(height: 8),
              Text('Duration: $_durationMinutes minutes'),
              const SizedBox(height: 8),
              Text('Type: $_mode'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm Schedule'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
      setState(() => _saving = true);

      await _service.createScheduleWithFirstCheckIn(
        schedule: schedule,
        checkIn: CheckIn(
          id: '',
          elderId: elderId,
          elderName: elderName,
          elderImageUrl: null,
          companionId: companionId,
          companionName: companionName,
          scheduledAt: nextOccurrence,
          durationMinutes: _durationMinutes!,
          mode: _mode!,
          status: CheckInStatus.scheduled,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in scheduled successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
    } finally {
      if (mounted && _saving) {
        setState(() => _saving = false);
      }
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
              value: _selectedTime == null
                  ? 'Choose a time'
                  : _selectedTime!.format(context),
              onTap: _chooseTime,
            ),
            _fieldSection(
              label: 'Duration',
              icon: Icons.timelapse_rounded,
              value: _durationMinutes == null
                  ? 'Choose a duration'
                  : '$_durationMinutes minutes',
              onTap: _chooseDuration,
            ),
            _fieldSection(
              label: 'Check-in type',
              icon: Icons.video_call_outlined,
              value: _mode ?? 'Choose Video or Voice',
              onTap: _chooseMode,
            ),
            _companionSection(
              widget.companionName?.trim().isNotEmpty == true
                  ? widget.companionName!.trim()
                  : 'Connected companion',
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (selected != null && mounted) {
      setState(() => _selectedTime = selected);
    }
  }

  Future<void> _chooseDuration() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final duration in [15, 30, 45, 60])
              ListTile(
                title: Text('$duration minutes'),
                onTap: () => Navigator.of(context).pop(duration),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _durationMinutes = selected);
    }
  }

  Future<void> _chooseMode() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ['Video', 'Voice'])
              ListTile(
                title: Text(mode),
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _mode = selected);
    }
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

  Widget _companionSection(String companionName) {
    final initials = companionName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Companion',
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: ElderColors.mintSoft,
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    color: ElderColors.darkTeal,
                    fontWeight: FontWeight.w800,
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
                      companionName,
                      style: const TextStyle(
                        color: ElderColors.textDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Connected Student Companion',
                      style: TextStyle(
                        color: ElderColors.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const ElderStatusPill('CONNECTED', filled: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Column(
      children: [
        ElderPrimaryButton(
          label: _saving ? 'Creating...' : 'Review & create schedule',
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
