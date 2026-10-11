import 'package:flutter/material.dart';

import '../models/check_in.dart';
import '../models/check_in_scheduling.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'my_schedule_screen.dart';

class RescheduleCheckInScreen extends StatefulWidget {
  const RescheduleCheckInScreen({
    super.key,
    this.checkInId,
    this.initialCheckIn,
    this.navigationOnly = false,
    this.isInitialScheduling = false,
    this.connectionId,
    this.elderId,
    this.elderName,
    this.companionId,
    this.companionName,
    this.companionImageUrl,
    this.preferredCheckInType,
  });

  final String? checkInId;
  final CheckIn? initialCheckIn;
  final bool navigationOnly;
  final bool isInitialScheduling;

  final String? connectionId;
  final String? elderId;
  final String? elderName;
  final String? companionId;
  final String? companionName;
  final String? companionImageUrl;
  final String? preferredCheckInType;

  @override
  State<RescheduleCheckInScreen> createState() =>
      _RescheduleCheckInScreenState();
}

class _RescheduleCheckInScreenState extends State<RescheduleCheckInScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  ElderConnectionDetails? _connection;
  CheckIn? _checkIn;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _durationMinutes;
  String? _mode;

  bool _loading = true;
  bool _saving = false;
  bool _confirming = false;
  Object? _error;

  bool get _busy => _saving || _confirming;

  DateTime? get _selectedAt {
    if (_selectedDate == null || _selectedTime == null) {
      return null;
    }

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  @override
  void initState() {
    super.initState();

    if (widget.isInitialScheduling) {
      _loadActiveConnection();
    } else {
      _loadExistingCheckIn();
    }
  }

  // --------------------------------------------------
  // LOAD ACTIVE ELDER CONNECTION
  // --------------------------------------------------

  Future<void> _loadActiveConnection() async {
    try {
      final connection = await _service.getActiveConnectionForCurrentElder();

      if (connection == null) {
        throw StateError(
          'You need an active companion connection '
          'before scheduling a check-in.',
        );
      }

      if (widget.connectionId != null && widget.connectionId != connection.id) {
        throw StateError(
          'The selected companion connection is no longer active.',
        );
      }

      if (widget.elderId != null && widget.elderId != connection.elderId) {
        throw StateError('The Elder account does not match.');
      }

      if (widget.companionId != null &&
          widget.companionId != connection.companionId) {
        throw StateError('The Student Companion does not match.');
      }

      final preferredType = widget.preferredCheckInType?.trim();

      if (!mounted) return;

      setState(() {
        _connection = connection;
        _durationMinutes = null;
        _mode = preferredType == 'Video' || preferredType == 'Voice'
            ? preferredType
            : null;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  // --------------------------------------------------
  // LOAD EXISTING CHECK-IN FOR RESCHEDULING
  // --------------------------------------------------

  Future<void> _loadExistingCheckIn() async {
    try {
      CheckIn? checkIn;

      if (widget.navigationOnly && widget.initialCheckIn != null) {
        checkIn = widget.initialCheckIn;
      } else {
        final id = widget.checkInId;

        if (id == null || id.isEmpty) {
          throw StateError('Select an existing check-in first.');
        }

        checkIn = await _service.getCheckInById(id);
      }

      if (checkIn == null) {
        throw StateError('Check-in not found.');
      }

      if (!mounted) return;

      setState(() {
        _checkIn = checkIn;

        _selectedDate = DateTime(
          checkIn!.scheduledAt.year,
          checkIn.scheduledAt.month,
          checkIn.scheduledAt.day,
        );

        _selectedTime = TimeOfDay.fromDateTime(checkIn.scheduledAt);

        _durationMinutes = checkIn.durationMinutes;
        _mode = checkIn.mode;

        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  // --------------------------------------------------
  // DATE AND TIME PICKERS
  // --------------------------------------------------

  Future<void> _chooseDate() async {
    if (_busy) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = _selectedDate;

    final initialDate = selected != null && !selected.isBefore(today)
        ? selected
        : today;

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(result.year, result.month, result.day);
    });
  }

  Future<void> _chooseTime() async {
    if (_busy) return;

    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (result == null || !mounted) return;

    setState(() => _selectedTime = result);
  }

  Future<void> _chooseDuration() async {
    if (_busy) return;

    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Choose check-in duration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final duration in CheckInScheduling.durationOptions)
                ListTile(
                  title: Text('$duration minutes'),
                  trailing: _durationMinutes == duration
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext, duration);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _durationMinutes = result);
    }
  }

  Future<void> _chooseMode() async {
    if (_busy) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Choose check-in type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final mode in CheckInScheduling.modes)
                ListTile(
                  leading: Icon(
                    mode == 'Video'
                        ? Icons.videocam_outlined
                        : Icons.call_outlined,
                  ),
                  title: Text(mode),
                  trailing: _mode == mode ? const Icon(Icons.check) : null,
                  onTap: () {
                    Navigator.pop(sheetContext, mode);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _mode = result);
    }
  }

  // --------------------------------------------------
  // CONFIRM SCHEDULE
  // --------------------------------------------------

  Future<bool> _confirmSchedule(DateTime scheduledAt) async {
    final localizations = MaterialLocalizations.of(context);

    final companion =
        _connection?.companionName ??
        _checkIn?.companionName ??
        'Student Companion';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            widget.isInitialScheduling
                ? 'Confirm Check-in'
                : 'Confirm New Time',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Companion: $companion'),
              const SizedBox(height: 10),
              Text('Date: ${localizations.formatMediumDate(scheduledAt)}'),
              const SizedBox(height: 10),
              Text(
                'Time: ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt))}',
              ),
              const SizedBox(height: 10),
              Text('Duration: $_durationMinutes minutes'),
              const SizedBox(height: 10),
              Text('Type: $_mode'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  // --------------------------------------------------
  // VALIDATE AND SAVE
  // --------------------------------------------------

  Future<void> _saveSchedule() async {
    if (_busy) return;

    final scheduledAt = _selectedAt;
    final duration = _durationMinutes;
    final mode = _mode;

    final validationError = CheckInScheduling.validateSelection(
      scheduledAt: scheduledAt,
      durationMinutes: duration,
      mode: mode,
    );

    if (validationError != null) {
      _showMessage(validationError);
      return;
    }

    if (widget.navigationOnly) {
      _showMessage('Preview mode cannot save a check-in.');
      return;
    }

    setState(() => _confirming = true);

    try {
      final confirmed = await _confirmSchedule(scheduledAt!);

      if (!confirmed || !mounted) return;

      // Revalidate: time might pass while confirmation is open.
      final freshError = CheckInScheduling.validateSelection(
        scheduledAt: scheduledAt,
        durationMinutes: duration,
        mode: mode,
      );

      if (freshError != null) {
        _showMessage(freshError);
        return;
      }

      setState(() => _saving = true);

      if (widget.isInitialScheduling) {
        await _createCheckIn(
          scheduledAt: scheduledAt,
          durationMinutes: duration!,
          mode: mode!,
        );
      } else {
        await _rescheduleExisting(scheduledAt);
      }
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _confirming = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // CREATE FIRESTORE CHECK-IN
  // --------------------------------------------------

  Future<void> _createCheckIn({
    required DateTime scheduledAt,
    required int durationMinutes,
    required String mode,
  }) async {
    // Always fetch the live connection again before saving.
    final connection = await _service.getActiveConnectionForCurrentElder();

    if (connection == null) {
      throw StateError('Your companion connection is no longer active.');
    }

    if (_connection == null || connection.id != _connection!.id) {
      throw StateError('The active connection has changed. Please try again.');
    }

    var elderName = connection.elderName.trim();

    if (elderName.isEmpty) {
      elderName = (await _service.getCurrentElderName()).trim();
    }

    final checkIn = CheckIn(
      id: '',
      elderId: connection.elderId,
      elderName: elderName,
      elderImageUrl: null,
      companionId: connection.companionId,
      companionName: connection.companionName,
      companionImageUrl: connection.companionImageUrl,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      mode: mode,
      status: CheckInStatus.scheduled,
    );

    // Use the existing Firebase service.
    // It validates the active Elder–Student connection.
    await _service.createCheckIn(checkIn);

    if (!mounted) return;

    // IMPORTANT: Do not open the Ready/Call screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MyScheduleScreen(
          connectionId: connection.id,
          elderId: connection.elderId,
          elderName: elderName,
          companionId: connection.companionId,
          companionName: connection.companionName,
          companionImageUrl: connection.companionImageUrl,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // RESCHEDULE EXISTING CHECK-IN
  // --------------------------------------------------

  Future<void> _rescheduleExisting(DateTime scheduledAt) async {
    final checkIn = _checkIn;

    if (checkIn == null) {
      throw StateError('No check-in selected.');
    }

    if (checkIn.status == CheckInStatus.completed ||
        checkIn.status == CheckInStatus.cancelled) {
      throw StateError(
        'Completed or cancelled check-ins cannot be rescheduled.',
      );
    }

    await _service.rescheduleCheckIn(checkIn.id, scheduledAt);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // --------------------------------------------------
  // CANCEL EXISTING CHECK-IN
  // --------------------------------------------------

  Future<void> _cancelCheckIn() async {
    if (_busy || widget.isInitialScheduling) return;

    final checkIn = _checkIn;
    if (checkIn == null) return;

    if (widget.navigationOnly) {
      _showMessage('Preview mode cannot cancel a check-in.');
      return;
    }

    final confirmed = await elderConfirm(
      context,
      title: 'Cancel this check-in?',
      message: '${checkIn.companionName} will see the cancelled status.',
      confirmLabel: 'Cancel check-in',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _saving = true);

    try {
      await _service.cancelCheckIn(checkIn.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --------------------------------------------------
  // BUILD UI
  // --------------------------------------------------

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
          children: [
            _header(),
            const SizedBox(height: 18),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ElderColors.darkTeal,
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        'Could not load check-in:\n$_error',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : widget.isInitialScheduling
                  ? _connection == null
                        ? const Center(
                            child: Text('No active connection found.'),
                          )
                        : _content()
                  : _checkIn == null
                  ? const Center(child: Text('No check-in selected.'))
                  : _content(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElderBackButton(onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 10),
        Text(
          widget.isInitialScheduling
              ? 'Schedule check-in'
              : 'Reschedule check-in',
          style: const TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isInitialScheduling
              ? 'Choose a day and time'
              : 'Choose a new day and time',
          style: const TextStyle(color: ElderColors.textMuted, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _content() {
    final localizations = MaterialLocalizations.of(context);

    final date = _selectedDate == null
        ? 'Choose a date'
        : localizations.formatMediumDate(_selectedDate!);

    final time = _selectedTime == null
        ? 'Choose a time'
        : localizations.formatTimeOfDay(_selectedTime!);

    final companionName =
        _connection?.companionName ?? _checkIn?.companionName ?? '';

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _companionCard(companionName),
              const SizedBox(height: 13),
              _selectionCard(
                label: 'Date',
                value: date,
                icon: Icons.calendar_month_outlined,
                onTap: _chooseDate,
              ),
              const SizedBox(height: 13),
              _selectionCard(
                label: 'Time',
                value: time,
                icon: Icons.schedule_rounded,
                onTap: _chooseTime,
              ),
              if (widget.isInitialScheduling) ...[
                const SizedBox(height: 13),
                _selectionCard(
                  label: 'Duration',
                  value: _durationMinutes == null
                      ? 'Choose a duration'
                      : '$_durationMinutes min',
                  icon: Icons.timelapse_rounded,
                  onTap: _chooseDuration,
                ),
                const SizedBox(height: 13),
                _selectionCard(
                  label: 'Check-in type',
                  value: _mode ?? 'Choose Video or Voice',
                  icon: Icons.video_call_outlined,
                  onTap: _chooseMode,
                ),
              ] else ...[
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ElderColors.mintSoft,
                    border: Border.all(color: ElderColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${_durationMinutes ?? 0} min · ${_mode ?? ''} check-in',
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ElderPrimaryButton(
          label: _saving
              ? 'Saving...'
              : widget.isInitialScheduling
              ? 'Schedule check-in'
              : 'Save new time',
          height: 54,
          onPressed: _busy ? () {} : _saveSchedule,
        ),
        if (!widget.isInitialScheduling) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _busy ? null : _cancelCheckIn,
              child: const Text('Cancel this check-in'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _companionCard(String companionName) {
    final initials = companionName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Container(
      height: 102,
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
                const SizedBox(height: 5),
                Text(
                  widget.isInitialScheduling
                      ? 'Connected Student Companion'
                      : 'Scheduled check-in',
                  style: const TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          ElderStatusPill((_mode ?? 'CHECK-IN').toUpperCase()),
        ],
      ),
    );
  }

  Widget _selectionCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE9E7)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: ElderColors.deepTeal, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ElderColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
    );
  }
}
