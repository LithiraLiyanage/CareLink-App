import 'package:flutter/material.dart';

import '../models/memory_item.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_ui.dart';

// =====================================================
// L10 - ADD / DELETE MEMORY
// CareLink Figma UI Redesign
// Existing Firebase methods preserved.
// =====================================================

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({
    super.key,
    this.navigationOnly = false,
    this.isEditing = false,
    this.memoryId,
  });

  final bool navigationOnly;
  final bool isEditing;

  // Required for safe deletion of an existing memory.
  final String? memoryId;

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  final TextEditingController titleController = TextEditingController(
    text: 'Family New Year',
  );

  int visibility = 0;
  bool _saving = false;
  bool _deleting = false;

  DateTime _selectedDate = DateTime(1998, 1, 1);

  static const Color _background = Color(0xFFF6FAF9);
  static const Color _darkTeal = Color(0xFF123F42);
  static const Color _primaryTeal = Color(0xFF086C66);
  static const Color _mint = Color(0xFFE6F7F3);
  static const Color _mintStrong = Color(0xFFB5F2E4);
  static const Color _muted = Color(0xFF718383);
  
  static const Color _coral = Color(0xFFF34E65);

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // =====================================================
  // EXISTING FIREBASE SAVE FLOW
  // =====================================================

  Future<void> _saveMemory() async {
    if (_saving || _deleting) return;

    if (widget.navigationOnly) {
      Navigator.of(context).maybePop();
      return;
    }

    // The existing service call only adds memories.
    // Do not accidentally create a duplicate while editing.
    if (widget.isEditing) {
      _message('Editing existing memories is not available yet.');
      return;
    }

    final title = titleController.text.trim();

    if (title.isEmpty) {
      _message('Please enter a memory title.');
      return;
    }

    setState(() => _saving = true);

    const visibilityLabels = ['Only me', 'Family', 'Companion'];

    try {
      await _service.addMemory(
        MemoryItem(
          id: '',
          // Preserved from the existing implementation.
          // Replace with authenticated owner ID
          // when the service integration is updated.
          ownerId: 'elder-kamala',
          type: MemoryType.photo,
          title: title,
          caption: 'Saved from Add a memory',
          mediaPath: ElderAssets.addMemoryPhoto,
          memoryDate: _selectedDate,
          createdAt: DateTime.now(),
          visibility: visibilityLabels[visibility],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (error) {
      _message('Could not save memory: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // =====================================================
  // SAFE DELETE FLOW
  // =====================================================

  Future<void> _deleteMemory() async {
    if (_deleting || _saving) return;

    if (widget.navigationOnly) {
      Navigator.of(context).maybePop();
      return;
    }

    final id = widget.memoryId?.trim();

    if (id == null || id.isEmpty) {
      _message('Cannot delete: an existing memory ID is required.');
      return;
    }

    final confirmed = await elderConfirm(
      context,
      title: 'Delete this memory?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);

    try {
      await _service.deleteMemory(id);

      if (!mounted) return;
      Navigator.of(context).maybePop();
    } catch (error) {
      _message('Could not delete memory: $error');
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  // =====================================================
  // DATE PICKER
  // =====================================================

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: 'Select memory date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _darkTeal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  // =====================================================
  // MAIN SCREEN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: _background,
      statusBarColor: _background,
      darkStatusBar: true,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 9, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 21),
                    _mediaSection(),
                    const SizedBox(height: 24),
                    _titleField(),
                    const SizedBox(height: 13),
                    _dateField(),
                    const SizedBox(height: 16),
                    _visibilitySection(),
                    const SizedBox(height: 16),
                    _privacyCard(),
                  ],
                ),
              ),
            ),
            _actions(),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FIGMA HEADER
  // =====================================================

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primaryTeal),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _primaryTeal,
                size: 17,
              ),
            ),
          ),
        ),
        const SizedBox(height: 29),
        Text(
          widget.isEditing ? 'Edit memory' : 'Add a memory',
          style: const TextStyle(
            color: _darkTeal,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Save a photo, story or voice note',
          style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  // =====================================================
  // PHOTO PREVIEW + ADD PHOTO
  // =====================================================

  Widget _mediaSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: _darkTeal.withValues(alpha: 0.065),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                ElderAssets.addMemoryPhoto,
                height: 153,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 153,
                  color: _mint,
                  child: const Icon(
                    Icons.photo_outlined,
                    color: _primaryTeal,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Material(
              color: _mint,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () {
                  _message('Photo selection is not connected yet.');
                },
                child: Container(
                  height: 153,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: _mintStrong, width: 1.1),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 23,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.add_rounded,
                          color: _primaryTeal,
                          size: 26,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Add photo',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tap to replace',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // MEMORY TITLE FIELD
  // =====================================================

  Widget _titleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Memory title'),
        const SizedBox(height: 7),
        TextField(
          controller: titleController,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            color: _darkTeal,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(9),
              child: Container(
                decoration: BoxDecoration(
                  color: _mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryTeal),
                ),
                child: const Icon(
                  Icons.title_rounded,
                  color: _primaryTeal,
                  size: 21,
                ),
              ),
            ),
            hintText: 'Enter memory title',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _primaryTeal, width: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _primaryTeal, width: 1.7),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // DATE FIELD
  // =====================================================

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date'),
        const SizedBox(height: 7),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _chooseDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                border: Border.all(color: _primaryTeal, width: 0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 17,
                    backgroundColor: _mint,
                    child: Icon(
                      Icons.access_time_rounded,
                      color: _primaryTeal,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        color: _darkTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: _muted,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // VISIBILITY SELECTION
  // =====================================================

  Widget _visibilitySection() {
    const labels = ['Only me', 'Family', 'Companion'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Visibility'),
        const SizedBox(height: 9),
        Row(
          children: List.generate(labels.length, (index) {
            final selected = visibility == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 8,
                ),
                child: SizedBox(
                  height: 39,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => visibility = index);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected ? _primaryTeal : Colors.white,
                      foregroundColor: selected ? Colors.white : _primaryTeal,
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: _primaryTeal, width: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(23),
                      ),
                    ),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // =====================================================
  // FIGMA PRIVACY CARD
  // =====================================================

  Widget _privacyCard() {
    const descriptions = [
      'Only you can see this memory.',
      'Visible to family, subject to app permissions.',
      'Visible to your companion, subject to permissions.',
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 59),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.check_rounded, color: _primaryTeal, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Private by default',
                  style: TextStyle(
                    color: _darkTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descriptions[visibility],
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // FIXED BOTTOM ACTIONS
  // =====================================================

  Widget _actions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      decoration: const BoxDecoration(color: _background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 53,
            child: ElevatedButton(
              onPressed: _saving || _deleting ? null : _saveMemory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryTeal,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: _darkTeal.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save memory',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),

          if (widget.isEditing) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _saving || _deleting ? null : _deleteMemory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _coral,
                  backgroundColor: const Color(0xFFFFF6F7),
                  side: const BorderSide(color: _coral, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  _deleting ? 'Deleting...' : 'Delete memory',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
