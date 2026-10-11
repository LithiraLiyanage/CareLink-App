import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../companion/screens/student_companion_home_screen.dart';
import '../models/memory_item.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';

// Firebase Storage is unavailable on the CareLink Spark project.
// Set true only after Storage is configured and its rules are deployed.
const bool kMemoryPhotoUploadsEnabled = false;

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key, this.existingMemory});

  // Opening a photo card from Memory Lane passes its real Firestore document.
  // The + Add a memory button opens this screen without an existing document.
  final MemoryItem? existingMemory;

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;
  late final TextEditingController titleController;
  late final TextEditingController captionController;

  int visibility = 0;
  bool _saving = false;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  late DateTime _memoryDate;

  static const visibilityLabels = <String>[
    'Only me',
    'Family',
    'Companion',
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.existingMemory?.title ?? '',
    );
    captionController = TextEditingController(
      text: widget.existingMemory?.caption ?? '',
    );
    _memoryDate = widget.existingMemory?.memoryDate ?? DateTime.now();
    final previous = widget.existingMemory?.visibility;
    final index = visibilityLabels.indexOf(previous ?? 'Only me');
    visibility = index == -1 ? 0 : index;
  }

  @override
  void dispose() {
    titleController.dispose();
    captionController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _choosePhoto() async {
    if (_saving) return;
    if (!kMemoryPhotoUploadsEnabled) {
      _message('Photo uploads need Firebase Storage. Save a story instead.');
      return;
    }

    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;

      final fileSize = file.lengthSync() ?? await file.length();
      if (fileSize != null && fileSize > 8 * 1024 * 1024) {
        _message('Please select a photo smaller than 8 MB.');
        return;
      }

      final Uint8List imageBytes = await file.readAsBytes();
      if (imageBytes.isEmpty) {
        _message('Could not read the photo. Please select it again.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedPhotoBytes = imageBytes;
        _selectedPhotoName = file.name;
      });
    } catch (error) {
      _message('Could not select a photo: $error');
    }
  }

  Future<void> _selectDate() async {
    if (_saving) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _memoryDate.isAfter(DateTime.now())
          ? DateTime.now()
          : _memoryDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'When did this memory happen?',
    );
    if (date != null && mounted) {
      setState(() => _memoryDate = date);
    }
  }

  String get _formattedDate {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${_memoryDate.day.toString().padLeft(2, '0')} '
        '${months[_memoryDate.month - 1]} ${_memoryDate.year}';
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<String> _uploadPhoto(String uid) async {
    final bytes = _selectedPhotoBytes;
    final name = _selectedPhotoName;
    if (bytes == null || name == null) {
      throw StateError('Select a photo first.');
    }

    // Only keep safe extension characters in the Storage object path.
    final lower = name.toLowerCase();
    final extension = lower.endsWith('.png')
        ? 'png'
        : lower.endsWith('.webp')
            ? 'webp'
            : lower.endsWith('.gif')
                ? 'gif'
                : 'jpg';
    final objectName =
        '${DateTime.now().microsecondsSinceEpoch}.$extension';
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('memories')
        .child(uid)
        .child(objectName);
    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: _contentType(name)),
    );
    return storageRef.getDownloadURL();
  }

  Future<void> _saveMemory() async {
    if (_saving) return;
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _message('Please enter a memory title.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _message('Please sign in before saving a memory.');
      return;
    }

    final existing = widget.existingMemory;
    if (existing != null && existing.ownerId != uid) {
      _message('Only the memory creator can edit it.');
      return;
    }
    if (visibilityLabels[visibility] == 'Family') {
      _message('Family sharing is not connected yet. Choose Only me or Companion.');
      return;
    }
    // Photos are optional: Spark projects can save memory stories to Firestore.

    setState(() => _saving = true);
    try {
      // Firebase Storage rules must separately authorize memories/<uid>/...
      final String? mediaUrl = !kMemoryPhotoUploadsEnabled
          ? existing?.mediaPath
          : (_selectedPhotoBytes == null
              ? existing?.mediaPath
              : await _uploadPhoto(uid));

      await _service.addMemory(
        MemoryItem(
          id: existing?.id ?? '',
          ownerId: uid,
          type: MemoryType.photo,
          title: title,
          caption: captionController.text.trim(),
          mediaPath: mediaUrl,
          memoryDate: _memoryDate,
          createdAt: existing?.createdAt ?? DateTime.now(),
          visibility: visibilityLabels[visibility],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const StudentCompanionHomeScreen(),
        ),
        (_) => false,
      );
    } catch (error) {
      _message('Could not save memory: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteMemory() async {
    if (_saving) return;
    final existing = widget.existingMemory;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (existing != null && existing.ownerId != uid) {
      _message('Only the memory creator can delete it.');
      return;
    }

    final ok = await elderConfirm(
      context,
      title: existing == null ? 'Discard this memory?' : 'Delete this memory?',
      message: existing == null
          ? 'The unsaved memory will be discarded.'
          : 'This memory will be permanently deleted.',
      confirmLabel: existing == null ? 'Discard' : 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;

    if (existing == null) {
      Navigator.of(context).pop(); // Return to Memory Lane; no DB ID to delete.
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.deleteMemory(existing.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // Return to Memory Lane and refresh.
    } catch (error) {
      _message('Could not delete memory: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _photoPreview() {
    if (_selectedPhotoBytes != null) {
      return Image.memory(
        _selectedPhotoBytes!,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    final path = widget.existingMemory?.mediaPath;
    if (path != null && path.startsWith('http')) {
      return Image.network(
        path,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          ElderAssets.addMemoryPhoto,
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      (path != null && path.startsWith('assets/'))
          ? path
          : ElderAssets.addMemoryPhoto,
      height: 170,
      width: double.infinity,
      fit: BoxFit.cover,
    );
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
          children: [
            _header(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _mediaSection(),
                    const SizedBox(height: 16),
                    _titleField(),
                    const SizedBox(height: 12),
                    _captionField(),
                    const SizedBox(height: 12),
                    _dateField(),
                    const SizedBox(height: 12),
                    _visibilitySection(),
                    const SizedBox(height: 12),
                    const _PrivacyCard(),
                    const SizedBox(height: 12),
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

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElderBackButton(onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(height: 10),
        Text(
          widget.existingMemory == null ? 'Add a memory' : 'Edit memory',
          style: const TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          kMemoryPhotoUploadsEnabled
              ? 'Save a photo or a story'
              : 'Save a story; photos are unavailable on the free plan',
          style: TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _mediaSection() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _photoPreview(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _saving ? null : _choosePhoto,
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: ElderColors.mintSoft,
                border: Border.all(color: ElderColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.add_a_photo_outlined,
                        color: ElderColors.deepTeal, size: 23),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    !kMemoryPhotoUploadsEnabled
                        ? 'Photo unavailable'
                        : (_selectedPhotoBytes == null ? 'Add photo' : 'Photo selected'),
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    kMemoryPhotoUploadsEnabled
                        ? 'Tap to replace'
                        : 'Save a story instead',
                    style: TextStyle(color: ElderColors.textMuted, fontSize: 8.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Memory title'),
        const SizedBox(height: 7),
        SizedBox(
          height: 56,
          child: TextField(
            controller: titleController,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Family New Year',
              prefixIcon: const Icon(Icons.title_rounded,
                  color: ElderColors.deepTeal, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 11),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: ElderColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: ElderColors.deepTeal),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Story text is stored in Firestore without needing a Storage bucket.
  Widget _captionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Memory story (optional)'),
        const SizedBox(height: 7),
        TextField(
          controller: captionController,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          style: const TextStyle(
            color: ElderColors.textDark,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Write something about this memory...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: ElderColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: ElderColors.deepTeal),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date'),
        const SizedBox(height: 7),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ElderColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: ElderColors.mintSoft,
                  child: Icon(Icons.calendar_month_outlined,
                      color: ElderColors.deepTeal, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formattedDate,
                    style: const TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: ElderColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _visibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Visibility'),
        const SizedBox(height: 7),
        Row(
          children: List.generate(visibilityLabels.length, (index) {
            final selected = visibility == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == visibilityLabels.length - 1 ? 0 : 7,
                ),
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            if (index == 1) {
                              _message('Family sharing is not configured yet.');
                              return;
                            }
                            setState(() => visibility = index);
                          },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: selected
                          ? ElderColors.darkTeal
                          : Colors.white,
                      foregroundColor: selected
                          ? Colors.white
                          : ElderColors.deepTeal,
                      side: BorderSide(
                        color: selected
                            ? ElderColors.darkTeal
                            : ElderColors.border,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                    ),
                    child: Text(
                          index == 1 ? 'Family*' : visibilityLabels[index],
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        const Text(
          '* Family sharing needs a separate consent-based feature.',
          style: TextStyle(color: ElderColors.textMuted, fontSize: 9),
        ),
      ],
    );
  }

  Widget _actions() {
    return Column(
      children: [
        ElderPrimaryButton(
          label: _saving ? 'Saving...' : 'Save memory',
          height: 54,
          onPressed: _saving ? () {} : _saveMemory,
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _saving ? null : _deleteMemory,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC94354),
              side: const BorderSide(color: ElderColors.coral),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Delete memory',
              style: const TextStyle(fontSize: 10.5,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: ElderColors.textMuted,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.lock_outline_rounded,
                color: ElderColors.deepTeal, size: 19),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by default.',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'You choose who can see it.',
                  style: TextStyle(color: ElderColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
