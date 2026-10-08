
import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../models/recurring_schedule.dart';
import '../services/firebase_elder_service.dart';
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

class _NewRecurringCheckInScreenState
    extends State<NewRecurringCheckInScreen> {
  final FirebaseElderService _service =
      FirebaseElderService.instance;

  // Original form state.
  final Set<int> selectedDays = {};

  TimeOfDay? _selectedTime;
  int? _durationMinutes;
  String? _mode;
  bool _saving = false;

  // ==============================================
  // FIGMA COLORS
  // ==============================================

  static const Color _background = Color(0xFFF6FAF9);
  static const Color _darkTeal = Color(0xFF123E42);
  static const Color _primaryTeal = Color(0xFF08635F);
  static const Color _coral = Color(0xFFF25266);
  static const Color _mint = Color(0xFFE7F7F3);
  static const Color _muted = Color(0xFF617879);
  static const Color _border = Color(0xFFD9E9E5);

  @override
  void initState() {
    super.initState();

    final requestedType =
        widget.preferredCheckInType?.trim();

    if (requestedType == 'Video' ||
        requestedType == 'Voice') {
      _mode = requestedType;
    }
  }

  // ==============================================
  // ORIGINAL FIREBASE SCHEDULING LOGIC
  // ==============================================

  Future<void> _createSchedule() async {
    if (_saving) return;

    // Preserve the existing UI-only preview mode.
    if (widget.navigationOnly) {
      final now = DateTime.now();
      final time = _selectedTime ??
          const TimeOfDay(hour: 10, minute: 0);

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
        mode: _mode ??
            widget.preferredCheckInType ??
            'Video',
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
                  widget.companionName
                          ?.trim()
                          .isEmpty !=
                      false
              ? await _service
                  .getActiveConnectionForCurrentElder()
              : null;

      final connectionId =
          widget.connectionId ?? connection?.id;

      final elderId =
          widget.elderId ?? connection?.elderId;

      var elderName =
          widget.elderName?.trim() ?? '';

      final companionId =
          widget.companionId ??
          connection?.companionId;

      var companionName =
          widget.companionName?.trim() ?? '';

      if (elderName.isEmpty) {
        elderName =
            connection?.elderName.trim() ?? '';
      }

      if (elderName.isEmpty) {
        elderName =
            (await _service.getCurrentElderName())
                .trim();
      }

      if (companionName.isEmpty) {
        companionName =
            connection?.companionName.trim() ?? '';
      }

      if (connectionId == null ||
          connectionId.isEmpty) {
        throw StateError(
          'An active companion connection is '
          'required to schedule.',
        );
      }

      if (elderId == null || elderId.isEmpty) {
        throw StateError(
          'Could not identify the Older Adult account.',
        );
      }

      if (companionId == null ||
          companionId.isEmpty ||
          companionName.isEmpty) {
        throw StateError(
          'Could not identify the connected companion.',
        );
      }

      // Keep existing validation.
      if (selectedDays.isEmpty) {
        throw StateError(
          'Choose at least one day.',
        );
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
        weekdays: selectedDays
            .map((index) => index + 1)
            .toList()
          ..sort(),
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        durationMinutes: _durationMinutes!,
        isActive: true,
      );

      final nextOccurrence =
          schedule.nextOccurrence(DateTime.now());

      if (nextOccurrence == null) {
        throw StateError(
          'Could not calculate the next check-in.',
        );
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

      // Original confirmation step.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),
            title: const Text(
              'Confirm check-in',
              style: TextStyle(
                color: _darkTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text('Companion: $companionName'),
                const SizedBox(height: 10),
                Text('Repeat: $selectedDayNames'),
                const SizedBox(height: 10),
                Text(
                  'Time: ${_selectedTime!.format(context)}',
                ),
                const SizedBox(height: 10),
                Text(
                  'Duration: $_durationMinutes minutes',
                ),
                const SizedBox(height: 10),
                Text('Type: $_mode'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext)
                        .pop(false),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: _primaryTeal,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryTeal,
                ),
                onPressed: () =>
                    Navigator.of(dialogContext)
                        .pop(true),
                child: const Text(
                  'Confirm Schedule',
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }

      setState(() {
        _saving = true;
      });

      // Original Firebase write.
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
        const SnackBar(
          content: Text(
            'Check-in scheduled successfully.',
          ),
        ),
      );

      // Return true to the Scheduling Hand-off screen.
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst(
                'Bad state: ',
                '',
              ),
            ),
          ),
        );
    } finally {
      if (mounted && _saving) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ==============================================
  // TIME PICKER — ORIGINAL FUNCTIONALITY
  // ==============================================

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime:
          _selectedTime ?? TimeOfDay.now(),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedTime = selected;
      });
    }
  }

  // ==============================================
  // DURATION — ORIGINAL OPTIONS
  // ==============================================

  Future<void> _chooseDuration() async {
    final selected =
        await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 17),
              const Text(
                'Choose duration',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              for (final duration
                  in [15, 30, 45, 60])
                ListTile(
                  leading: const Icon(
                    Icons.timer_outlined,
                    color: _primaryTeal,
                  ),
                  title: Text(
                    '$duration minutes',
                  ),
                  trailing: _durationMinutes ==
                          duration
                      ? const Icon(
                          Icons.check_circle,
                          color: _primaryTeal,
                        )
                      : null,
                  onTap: () =>
                      Navigator.of(sheetContext)
                          .pop(duration),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _durationMinutes = selected;
      });
    }
  }

  // ==============================================
  // VIDEO / VOICE — ORIGINAL OPTIONS
  // ==============================================

  Future<void> _chooseMode() async {
    final selected =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 17),
              const Text(
                'Check-in type',
                style: TextStyle(
                  color: _darkTeal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (final mode
                  in ['Video', 'Voice'])
                ListTile(
                  leading: Icon(
                    mode == 'Video'
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,
                    color: _primaryTeal,
                  ),
                  title: Text(
                    '$mode call',
                  ),
                  trailing: _mode == mode
                      ? const Icon(
                          Icons.check_circle,
                          color: _primaryTeal,
                        )
                      : null,
                  onTap: () =>
                      Navigator.of(sheetContext)
                          .pop(mode),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _mode = selected;
      });
    }
  }

  // ==============================================
  // MAIN SCREEN
  // ==============================================

  @override
  Widget build(BuildContext context) {
    final companionName =
        widget.companionName?.trim().isNotEmpty ==
                true
            ? widget.companionName!.trim()
            : 'Connected companion';

    return ElderPhoneScaffold(
      backgroundColor: _background,
      statusBarColor: _background,
      darkStatusBar: true,
      child: Column(
        children: [
          // Scrollable form.
          Expanded(
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                21,
                12,
                21,
                16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _header(context),

                  const SizedBox(height: 25),

                  _stepIndicator(),

                  const SizedBox(height: 30),

                  _repeatSection(),

                  const SizedBox(height: 24),

                  _fieldSection(
                    label: 'Time',
                    icon:
                        Icons.access_time_rounded,
                    value: _selectedTime == null
                        ? 'Choose a time'
                        : _selectedTime!
                            .format(context),
                    onTap: _chooseTime,
                  ),

                  const SizedBox(height: 15),

                  _fieldSection(
                    label: 'Duration',
                    icon:
                        Icons.timelapse_rounded,
                    value: _durationMinutes == null
                        ? 'Choose a duration'
                        : '$_durationMinutes minutes',
                    onTap: _chooseDuration,
                  ),

                  const SizedBox(height: 15),

                  // This field is required by the
                  // current Firebase scheduling model.
                  _fieldSection(
                    label: 'Check-in type',
                    icon:
                        Icons.video_call_rounded,
                    value: _mode ??
                        'Choose Video or Voice',
                    onTap: _chooseMode,
                  ),

                  const SizedBox(height: 20),

                  _companionSection(
                    companionName,
                  ),
                ],
              ),
            ),
          ),

          // Bottom action stays visible while
          // scrolling the form.
          _actions(),
        ],
      ),
    );
  }

  // ==============================================
  // FIGMA HEADER
  // ==============================================

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        ElderBackButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),

        const SizedBox(height: 22),

        const Text(
          'New recurring check-in',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.65,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Create a routine that feels comfortable',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ==============================================
  // FIGMA 3-STEP PROGRESS
  // ==============================================

  Widget _stepIndicator() {
    return const Row(
      children: [
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

  // ==============================================
  // REPEAT DAYS
  // ==============================================

  Widget _repeatSection() {
    const days = [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];

    const fullDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat on',
          style: TextStyle(
            color: _darkTeal,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 13),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: List.generate(
            days.length,
            (index) {
              final selected =
                  selectedDays.contains(index);

              return Semantics(
                label: fullDays[index],
                selected: selected,
                button: true,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        selectedDays.remove(index);
                      } else {
                        selectedDays.add(index);
                      }
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 160,
                    ),
                    width: 41,
                    height: 41,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? _primaryTeal
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? _primaryTeal
                            : _border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      days[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : _darkTeal,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==============================================
  // TIME / DURATION / CALL TYPE
  // ==============================================

  Widget _fieldSection({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 7),

        Material(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius:
                BorderRadius.circular(15),
            child: Container(
              height: 57,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _border,
                ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: _mint,
                    child: Icon(
                      icon,
                      color: _primaryTeal,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: _darkTeal,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==============================================
  // SELECTED COMPANION — AMAYA
  // ==============================================

  Widget _companionSection(
    String companionName,
  ) {
    final initials = companionName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Companion',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: _primaryTeal,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _darkTeal.withValues(
                  alpha: 0.045,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _mint,
                child: Text(
                  initials.isEmpty
                      ? '?'
                      : initials,
                  style: const TextStyle(
                    color: _darkTeal,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      companionName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkTeal,
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Connected Student Companion',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _primaryTeal,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Text(
                  'SELECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==============================================
  // FIGMA CORAL BUTTON
  // ==============================================

  Widget _actions() {
    return Container(
      color: _background,
      padding: const EdgeInsets.fromLTRB(
        21,
        10,
        21,
        13,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 53,
            child: ElevatedButton(
              onPressed:
                  _saving ? null : _createSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: _coral,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _coral.withValues(alpha: 0.55),
                elevation: 3,
                shadowColor:
                    _darkTeal.withValues(
                  alpha: 0.13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Review & create schedule',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 11),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_calendar_outlined,
                size: 14,
                color: _muted,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'You can edit this anytime from My Schedule.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================
// STEP INDICATOR WIDGET
// ==============================================

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.active,
  });

  final String number;
  final String label;
  final bool active;

  static const Color _teal = Color(0xFF08635F);
  static const Color _muted = Color(0xFF617879);
  static const Color _border = Color(0xFFD9E9E5);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: active ? _teal : _border,
            borderRadius:
                BorderRadius.circular(5),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 22,
              width: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    active ? _teal : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      active ? _teal : _border,
                ),
              ),
              child: Text(
                number,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : _muted,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(width: 5),

            Flexible(
              child: Text(
                label,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? _teal : _muted,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
