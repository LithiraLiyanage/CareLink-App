import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../companion/screens/student_companion_home_screen.dart';
import '../models/memory_item.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';
import 'add_memory_screen.dart';
import 'my_schedule_screen.dart';

class MemoryLaneScreen extends StatefulWidget {
  const MemoryLaneScreen({super.key});

  @override
  State<MemoryLaneScreen> createState() => _MemoryLaneScreenState();
}

class _MemoryLaneScreenState extends State<MemoryLaneScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  int filter = 0;
  bool _loading = true;
  String? _error;
  String _elderName = 'Older Adult';
  String? _elderPhotoUrl;
  List<MemoryItem> _memories = <MemoryItem>[];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final contextData = await _service.getCurrentFlowContext();
      final items = await _service.getMemories();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // Client-side privacy display check. Security rules must also enforce it.
      final visible = items.where((memory) {
        return memory.ownerId == uid || memory.visibility == 'Companion';
      }).toList();

      String? photo;
      try {
        final elderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(contextData.elderId)
            .get();
        final data = elderDoc.data();
        photo =
            (data?['profileImageUrl'] as String?) ??
            (data?['photoUrl'] as String?);
      } catch (_) {
        // The connected elder's basic request name is already available.
        // A separate user-photo read may not be permitted by team rules.
      }

      if (!mounted) return;
      setState(() {
        _memories = visible;
        _elderName = contextData.elderName;
        _elderPhotoUrl = photo;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<MemoryItem> get _filtered {
    switch (filter) {
      case 1:
        return _memories.where((e) => e.type == MemoryType.photo).toList();
      case 2:
        return _memories.where((e) => e.type == MemoryType.voice).toList();
      case 3:
        return _memories.where((e) => e.type == MemoryType.song).toList();
      default:
        return _memories;
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const StudentCompanionHomeScreen(),
      ),
      (_) => false,
    );
  }

  void _openSchedule() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MyScheduleScreen()));
  }

  Future<void> _openAddMemory({MemoryItem? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddMemoryScreen(existingMemory: existing),
      ),
    );
    if (mounted) await _loadMemories();
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.cream,
      statusBarColor: ElderColors.darkTeal,
      darkStatusBar: false,
      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 2,
        onHome: _goHome,
        onSchedule: _openSchedule,
        onMemory: () {},
      ),
      child: Column(
        children: [
          _header(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                children: [
                  Expanded(child: _content()),
                  const SizedBox(height: 9),
                  ElderPrimaryButton(
                    label: '+  Add a memory',
                    color: ElderColors.coral,
                    height: 54,
                    onPressed: _loading ? () {} : () => _openAddMemory(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    const filters = <String>['All', 'Photos', 'Voice', 'Songs'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: ElderColors.darkTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElderBackButton(
                filled: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 9),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(
                  'C',
                  style: TextStyle(
                    color: ElderColors.darkTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'CareLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 21,
                backgroundColor: ElderColors.mintSoft,
                backgroundImage:
                    _elderPhotoUrl != null && _elderPhotoUrl!.startsWith('http')
                    ? NetworkImage(_elderPhotoUrl!)
                    : null,
                child: _elderPhotoUrl == null
                    ? Text(
                        _elderName.isNotEmpty
                            ? _elderName.trim()[0].toUpperCase()
                            : 'E',
                        style: const TextStyle(
                          color: ElderColors.darkTeal,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Memory Lane',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Stories, photos and moments you love',
            style: TextStyle(color: Colors.white70, fontSize: 9.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(filters.length, (index) {
              final selected = filter == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == filters.length - 1 ? 0 : 6,
                  ),
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => setState(() => filter = index),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? Colors.white
                            : Colors.transparent,
                        foregroundColor: selected
                            ? ElderColors.darkTeal
                            : Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        filters[index],
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
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ElderColors.darkTeal),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: ElderColors.darkTeal,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _loadMemories, child: const Text('Retry')),
          ],
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              color: ElderColors.deepTeal,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'No memories here yet',
              style: TextStyle(
                color: ElderColors.textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              filter == 0
                  ? 'Add your first memory to get started.'
                  : 'Try another memory category.',
              style: const TextStyle(color: ElderColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: ElderColors.darkTeal,
      onRefresh: _loadMemories,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          switch (item.type) {
            case MemoryType.photo:
              return _photoCard(item);
            case MemoryType.voice:
              return _voiceCard(item);
            case MemoryType.song:
              return _songCard(item);
          }
        },
      ),
    );
  }

  bool _canEdit(MemoryItem memory) =>
      memory.ownerId == FirebaseAuth.instance.currentUser?.uid;

  Widget _mediaImage(String? path) {
    if (path != null &&
        (path.startsWith('https://') || path.startsWith('http://'))) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 174,
        errorBuilder: (_, _, _) => _imageFallback(),
      );
    }
    if (path != null && path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: double.infinity,
        height: 174,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(),
      );
    }
    return _imageFallback();
  }

  Widget _imageFallback() => Container(
    width: double.infinity,
    height: 174,
    color: ElderColors.mintSoft,
    child: const Icon(
      Icons.photo_outlined,
      size: 44,
      color: ElderColors.deepTeal,
    ),
  );

  Widget _photoCard(MemoryItem memory) {
    return InkWell(
      onTap: _canEdit(memory) ? () => _openAddMemory(existing: memory) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 238,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ElderColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: _mediaImage(memory.mediaPath),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: ElderColors.mintSoft,
                      child: Icon(
                        Icons.photo_outlined,
                        color: ElderColors.deepTeal,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memory.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ElderColors.textDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            memory.caption ??
                                '${memory.memoryDate.day}/${memory.memoryDate.month}/${memory.memoryDate.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ElderColors.textMuted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_canEdit(memory))
                      const Icon(
                        Icons.edit_outlined,
                        color: ElderColors.deepTeal,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceCard(MemoryItem memory) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: ElderColors.darkTeal,
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: 0,
                  minHeight: 4,
                  color: ElderColors.deepTeal,
                  backgroundColor: ElderColors.mintSoft,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            memory.caption ?? 'Voice note',
            style: const TextStyle(color: ElderColors.textMuted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _songCard(MemoryItem memory) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: ElderColors.deepTeal,
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: 0,
                  minHeight: 4,
                  color: Color(0xFFD6A64B),
                  backgroundColor: Color(0xFFD3E5E2),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_circle_outline_rounded,
            color: ElderColors.deepTeal,
            size: 25,
          ),
        ],
      ),
    );
  }
}
