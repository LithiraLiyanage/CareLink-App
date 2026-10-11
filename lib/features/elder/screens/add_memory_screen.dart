import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/memory_item.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_ui.dart';

// Enable only after Firebase Storage and its security rules are configured.
const bool kMemoryPhotoUploadsEnabled = false;

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({
    super.key,
    this.navigationOnly = false,
    this.isEditing = false,
    this.memoryId,
    this.existingMemory,
  });

  // Keep both branches' constructor arguments compatible with existing callers.
  final bool navigationOnly;
  final bool isEditing;
  final String? memoryId;
  final MemoryItem? existingMemory;

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;
  late final TextEditingController titleController;
  late final TextEditingController captionController;

  static const Color _background = Color(0xFFF6FAF9);
  static const Color _darkTeal = Color(0xFF123F42);
  static const Color _primaryTeal = Color(0xFF086C66);
  static const Color _mint = Color(0xFFE6F7F3);
  static const Color _mintStrong = Color(0xFFB5F2E4);
  static const Color _muted = Color(0xFF718383);
  static const Color _coral = Color(0xFFF34E65);
  static const List<String> visibilityLabels = [
    'Only me',
    'Family',
    'Companion',
  ];

  bool _saving = false;
  bool _deleting = false;
  int visibility = 0;
  late DateTime _selectedDate;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;

  bool get _editing => widget.isEditing || widget.existingMemory != null;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existingMemory?.title ?? '');
    captionController = TextEditingController(text: widget.existingMemory?.caption ?? '');
    _selectedDate = widget.existingMemory?.memoryDate ?? DateTime.now();
    final index = visibilityLabels.indexOf(widget.existingMemory?.visibility ?? 'Only me');
    visibility = index < 0 ? 0 : index;
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
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _choosePhoto() async {
    if (_saving || _deleting) return;
    if (!kMemoryPhotoUploadsEnabled) {
      _message('Photo uploads are not configured. You can save a story instead.');
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.size > 8 * 1024 * 1024) {
        _message('Please select a photo smaller than 8 MB.');
        return;
      }
      if (file.bytes == null || file.bytes!.isEmpty) {
        _message('Could not read the selected photo.');
        return;
      }
      if (mounted) {
        setState(() {
          _selectedPhotoBytes = file.bytes;
          _selectedPhotoName = file.name;
        });
      }
    } catch (error) {
      _message('Could not select a photo: $error');
    }
  }

  String _contentType(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<String> _uploadPhoto(String uid) async {
    final bytes = _selectedPhotoBytes;
    final filename = _selectedPhotoName;
    if (bytes == null || filename == null) {
      throw StateError('Select a photo before uploading.');
    }
    final name = filename.toLowerCase();
    final extension = name.endsWith('.png') ? 'png' :
        name.endsWith('.webp') ? 'webp' : name.endsWith('.gif') ? 'gif' : 'jpg';
    final ref = FirebaseStorage.instance.ref()
        .child('memories').child(uid)
        .child('${DateTime.now().microsecondsSinceEpoch}.$extension');
    await ref.putData(bytes, SettableMetadata(contentType: _contentType(filename)));
    return ref.getDownloadURL();
  }

  Future<void> _saveMemory() async {
    if (_saving || _deleting) return;
    if (widget.navigationOnly) {
      Navigator.of(context).maybePop();
      return;
    }
    // addMemory() is not confirmed to provide update semantics. Do not create
    // duplicate memory documents when a user opens an existing record.
    if (_editing) {
      _message('Editing an existing memory is not available yet.');
      return;
    }
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _message('Please enter a memory title.');
      return;
    }
    if (visibilityLabels[visibility] == 'Family') {
      _message('Family sharing is not configured yet.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _message('Please sign in before saving a memory.');
      return;
    }
    setState(() => _saving = true);
    try {
      final String? mediaUrl = kMemoryPhotoUploadsEnabled && _selectedPhotoBytes != null
          ? await _uploadPhoto(uid) : null;
      await _service.addMemory(MemoryItem(
        id: '',
        ownerId: uid,
        type: MemoryType.photo,
        title: title,
        caption: captionController.text.trim(),
        mediaPath: mediaUrl,
        memoryDate: _selectedDate,
        createdAt: DateTime.now(),
        visibility: visibilityLabels[visibility],
      ));
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      _message('Could not save memory: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteMemory() async {
    if (_saving || _deleting) return;
    if (widget.navigationOnly) {
      Navigator.of(context).maybePop();
      return;
    }
    final existing = widget.existingMemory;
    final id = existing?.id.isNotEmpty == true ? existing!.id : widget.memoryId?.trim();
    if (!_editing || id == null || id.isEmpty) {
      _message('An existing memory ID is required to delete.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _message('Please sign in to delete this memory.');
      return;
    }
    if (existing != null && existing.ownerId != uid) {
      _message('Only the memory creator can delete it.');
      return;
    }
    final confirmed = await elderConfirm(
      context,
      title: 'Delete this memory?',
      message: 'This memory will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteMemory(id);
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      _message('Could not delete memory: $error');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _chooseDate() async {
    if (_saving || _deleting) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'When did this memory happen?',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryTeal),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

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
                    _header(),
                    const SizedBox(height: 21),
                    _mediaSection(),
                    const SizedBox(height: 24),
                    _titleField(),
                    const SizedBox(height: 13),
                    _captionField(),
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

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryTeal),
        ),
      ),
      const SizedBox(height: 22),
      Text(_editing ? 'Edit memory' : 'Add a memory',
        style: const TextStyle(color: _darkTeal, fontSize: 25,
          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text(kMemoryPhotoUploadsEnabled ? 'Save a photo or story'
          : 'Save a story; photo uploads are not configured',
        style: const TextStyle(color: _muted, fontSize: 11)),
    ],
  );

  Widget _photoPreview() {
    if (_selectedPhotoBytes != null) {
      return Image.memory(_selectedPhotoBytes!, height: 153, width: double.infinity,
        fit: BoxFit.cover);
    }
    final path = widget.existingMemory?.mediaPath;
    if (path != null && path.startsWith('http')) {
      return Image.network(path, height: 153, width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(ElderAssets.addMemoryPhoto,
          height: 153, fit: BoxFit.cover));
    }
    return Image.asset(path != null && path.startsWith('assets/')
        ? path : ElderAssets.addMemoryPhoto, height: 153, fit: BoxFit.cover);
  }

  Widget _mediaSection() => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      boxShadow: [BoxShadow(color: _darkTeal.withValues(alpha: 0.065),
        blurRadius: 15, offset: const Offset(0, 6))]),
    child: Row(children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16),
        child: _photoPreview())),
      const SizedBox(width: 11),
      Expanded(child: Material(
        color: _mint,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: _choosePhoto,
          child: Container(
            height: 153,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _mintStrong)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircleAvatar(radius: 23, backgroundColor: Colors.white,
                child: Icon(Icons.add_a_photo_outlined, color: _primaryTeal, size: 25)),
              const SizedBox(height: 12),
              Text(kMemoryPhotoUploadsEnabled ? 'Add photo' : 'Photo unavailable',
                style: const TextStyle(color: _darkTeal, fontSize: 12,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text(kMemoryPhotoUploadsEnabled ? 'Tap to replace' : 'Save a story instead',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 10)),
            ]),
          ),
        ),
      )),
    ]),
  );

  Widget _titleField() => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Memory title'),
      const SizedBox(height: 7),
      TextField(
        controller: titleController,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: _darkTeal, fontWeight: FontWeight.w700),
        decoration: _inputDecoration('Enter memory title', Icons.title_rounded),
      ),
    ]);

  Widget _captionField() => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Memory story (optional)'),
      const SizedBox(height: 7),
      TextField(
        controller: captionController,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        decoration: _inputDecoration('Write something about this memory...',
          Icons.edit_note_rounded),
      ),
    ]);

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: _primaryTeal),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _primaryTeal, width: 0.9),
      borderRadius: BorderRadius.circular(14)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: _primaryTeal, width: 1.7),
      borderRadius: BorderRadius.circular(14)),
  );

  Widget _dateField() => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Date'),
      const SizedBox(height: 7),
      Material(color: Colors.white, borderRadius: BorderRadius.circular(14),
        child: InkWell(onTap: _chooseDate, borderRadius: BorderRadius.circular(14),
          child: Container(height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(border: Border.all(color: _primaryTeal),
              borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const CircleAvatar(radius: 17, backgroundColor: _mint,
                child: Icon(Icons.access_time_rounded, color: _primaryTeal)),
              const SizedBox(width: 12),
              Expanded(child: Text(_formatDate(_selectedDate),
                style: const TextStyle(color: _darkTeal,
                  fontSize: 12, fontWeight: FontWeight.w700))),
              const Icon(Icons.calendar_month_outlined, color: _muted),
            ]),
          ),
        ),
      ),
    ]);

  Widget _visibilitySection() => Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Visibility'),
      const SizedBox(height: 9),
      Row(children: List.generate(visibilityLabels.length, (index) {
        final selected = visibility == index;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: index == visibilityLabels.length - 1 ? 0 : 7),
          child: SizedBox(height: 39, child: OutlinedButton(
            onPressed: _saving || _deleting ? null : () {
              if (index == 1) {
                _message('Family sharing is not configured yet.');
                return;
              }
              setState(() => visibility = index);
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: selected ? _primaryTeal : Colors.white,
              foregroundColor: selected ? Colors.white : _primaryTeal,
              padding: EdgeInsets.zero,
              side: const BorderSide(color: _primaryTeal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23))),
            child: Text(index == 1 ? 'Family*' : visibilityLabels[index],
              maxLines: 1, style: const TextStyle(fontSize: 10,
                fontWeight: FontWeight.w800)),
          )),
        ));
      })),
      const SizedBox(height: 5),
      const Text('* Family sharing needs a separate consent-based feature.',
        style: TextStyle(color: _muted, fontSize: 9)),
    ]);

  Widget _privacyCard() {
    final descriptions = [
      'Only you can see this memory.',
      'Family sharing is not configured.',
      'Shared with your companion, subject to permissions.',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: const Color(0xFFDCEBE7),
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const CircleAvatar(radius: 18, backgroundColor: Colors.white,
          child: Icon(Icons.lock_outline_rounded, color: _primaryTeal)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Private by default', style: TextStyle(color: _darkTeal,
              fontWeight: FontWeight.w900, fontSize: 11)),
            const SizedBox(height: 4),
            Text(descriptions[visibility],
              style: const TextStyle(color: _muted, fontSize: 10)),
          ])),
      ]),
    );
  }

  Widget _actions() => Container(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
    color: _background,
    child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 53, child: ElevatedButton(
          onPressed: _saving || _deleting ? null : _saveMemory,
          style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          child: _saving ? const SizedBox(width: 21, height: 21,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text('Save memory', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w900)),
        )),
        if (_editing) ...[
          const SizedBox(height: 10),
          SizedBox(height: 46, child: OutlinedButton(
            onPressed: _saving || _deleting ? null : _deleteMemory,
            style: OutlinedButton.styleFrom(foregroundColor: _coral,
              side: const BorderSide(color: _coral),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
            child: Text(_deleting ? 'Deleting...' : 'Delete memory',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          )),
        ],
      ],
    ),
  );

  Widget _label(String value) => Text(value,
    style: const TextStyle(color: _muted, fontSize: 11,
      fontWeight: FontWeight.w700));
}
