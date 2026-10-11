import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/memory_item.dart';
import '../services/firebase_elder_service.dart';
import '../widgets/elder_assets.dart';
import '../widgets/elder_ui.dart';

import 'add_memory_screen.dart';
import 'elder_home_screen.dart';
import 'my_schedule_screen.dart';

class MemoryLaneScreen extends StatefulWidget {
  const MemoryLaneScreen({super.key, this.navigationOnly = false});

  final bool navigationOnly;

  @override
  State<MemoryLaneScreen> createState() => _MemoryLaneScreenState();
}

class _MemoryLaneScreenState extends State<MemoryLaneScreen> {
  final FirebaseElderService _service = FirebaseElderService.instance;

  int filter = 0;

  bool _loading = true;
  String? _error;

  List<MemoryItem> _memories = [];

  // ==========================================
  // CARELINK FIGMA COLOR SYSTEM
  // ==========================================

  static const Color _darkTeal = Color(0xFF075B57);
  static const Color _deepTeal = Color(0xFF063F42);
  static const Color _primaryTeal = Color(0xFF087C77);
  static const Color _cream = Color(0xFFFFFBF4);
  static const Color _mintSoft = Color(0xFFE6F7F2);
  static const Color _coral = Color(0xFFF64E66);
  static const Color _ink = Color(0xFF153F42);
  static const Color _muted = Color(0xFF657E7D);
  static const Color _border = Color(0xFFC6E6DF);
  static const Color _gold = Color(0xFFD5A64C);

  @override
  void initState() {
    super.initState();

    if (widget.navigationOnly) {
      _loading = false;
    } else {
      _loadMemories();
    }
  }

  // ==========================================
  // FIREBASE — EXISTING LOGIC
  // ==========================================

  Future<void> _loadMemories() async {
    try {
      final items = await _service.getMemories();

      if (!mounted) return;

      setState(() {
        _memories = items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshMemories() async {
    if (widget.navigationOnly) return;
    await _loadMemories();
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    if (!mounted) return;

    if (!widget.navigationOnly) {
      await _loadMemories();
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _openAddMemory({MemoryItem? existing}) {
    _openAndRefresh(AddMemoryScreen(
      navigationOnly: widget.navigationOnly,
      existingMemory: existing,
      isEditing: existing != null,
      memoryId: existing?.id,
    ));
  }

  bool _canEditMemory(MemoryItem memory) =>
      !_usingSamples && memory.ownerId == FirebaseAuth.instance.currentUser?.uid;

  // ==========================================
  // SAMPLE DATA — FOR EMPTY MEMORY LANE ONLY
  // ==========================================

  bool get _usingSamples => _memories.isEmpty;

  List<MemoryItem> _sampleMemories() {
    final now = DateTime.now();

    return [
      MemoryItem(
        id: 'sample-photo',
        ownerId: 'sample',
        type: MemoryType.photo,
        title: 'Family New Year',
        caption: 'A cherished family celebration',
        mediaPath: ElderAssets.familyMemory,
        memoryDate: DateTime(1998, 4, 14),
        createdAt: now,
      ),
      MemoryItem(
        id: 'sample-voice',
        ownerId: 'sample',
        type: MemoryType.voice,
        title: "Listen to Amma's Story",
        caption: 'A special story to remember',
        memoryDate: DateTime(1998, 4, 14),
        createdAt: now,
      ),
      MemoryItem(
        id: 'sample-song',
        ownerId: 'sample',
        type: MemoryType.song,
        title: 'Favourite Song',
        caption: 'A melody close to your heart',
        memoryDate: DateTime(1998, 4, 14),
        createdAt: now,
      ),
    ];
  }

  List<MemoryItem> get _visibleMemories {
    final source = _usingSamples ? _sampleMemories() : _memories;

    if (filter == 0) return source;

    final type = switch (filter) {
      1 => MemoryType.photo,
      2 => MemoryType.voice,
      3 => MemoryType.song,
      _ => MemoryType.photo,
    };

    return source.where((memory) => memory.type == type).toList();
  }

  // ==========================================
  // MAIN SCREEN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: _cream,
      statusBarColor: _darkTeal,
      darkStatusBar: false,

      bottomNavigationBar: ElderBottomNav(
        selectedIndex: 2,
        onHome: () => _open(const ElderHomeScreen()),
        onSchedule: () => _open(const MyScheduleScreen()),
        onMemory: () {},
      ),

      child: Column(
        children: [
          _header(),

          Expanded(child: _buildBody()),

          _bottomAction(),
        ],
      ),
    );
  }

  // ==========================================
  // DARK TEAL HEADER
  // ==========================================

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _darkTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // Decorative soft circles.
            const Positioned(
              top: -60,
              right: -50,
              child: CircleAvatar(
                radius: 90,
                backgroundColor: Color(0x1800D9B2),
              ),
            ),

            const Positioned(
              bottom: -48,
              left: -35,
              child: CircleAvatar(
                radius: 77,
                backgroundColor: Color(0x1600CEBA),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerTopRow(),

                  const SizedBox(height: 16),

                  const Text(
                    'Memory Lane',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Stories, photos and moments you love',
                    style: TextStyle(
                      color: Color(0xFFD9F3EE),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 19),

                  _filterTabs(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerTopRow() {
    return Row(
      children: [
        SizedBox(
          width: 43,
          height: 43,
          child: Material(
            color: const Color(0xFFB8F8E8),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                Navigator.of(context).maybePop();
              },
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _darkTeal,
                size: 18,
              ),
            ),
          ),
        ),

        const SizedBox(width: 11),

        const CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white,
          child: Text(
            'C',
            style: TextStyle(
              color: _darkTeal,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ),

        const SizedBox(width: 8),

        const Text(
          'CareLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),

        const Spacer(),

        const ElderAvatar(
          asset: ElderAssets.kamalaAvatar,
          size: 45,
          border: true,
        ),
      ],
    );
  }

  // ==========================================
  // WORKING CATEGORY FILTERS
  // ==========================================

  Widget _filterTabs() {
    const filters = ['All', 'Photos', 'Voice', 'Songs'];

    return Row(
      children: List.generate(filters.length, (index) {
        final selected = filter == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 6,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                onTap: () {
                  setState(() {
                    filter = index;
                  });
                },
                borderRadius: BorderRadius.circular(25),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: selected ? Colors.white : const Color(0xFFB4E3D9),
                    ),
                  ),
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: selected ? _darkTeal : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==========================================
  // SCROLLABLE MEMORY CARDS
  // ==========================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryTeal),
      );
    }

    if (_error != null) {
      return _errorState();
    }

    final memories = _visibleMemories;

    return RefreshIndicator(
      color: _primaryTeal,
      onRefresh: _refreshMemories,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_usingSamples) ...[_sampleNotice(), const SizedBox(height: 15)],

          if (memories.isEmpty)
            _emptyState()
          else
            for (final memory in memories) ...[
              _memoryCard(memory),
              const SizedBox(height: 18),
            ],
        ],
      ),
    );
  }

  Widget _memoryCard(MemoryItem memory) {
    switch (memory.type) {
      case MemoryType.photo:
        return _photoCard(memory);

      case MemoryType.voice:
        return _audioCard(memory, isVoice: true);

      case MemoryType.song:
        return _audioCard(memory, isVoice: false);
    }
  }

  // ==========================================
  // PHOTO MEMORY CARD
  // ==========================================

  Widget _photoCard(MemoryItem memory) {
    return InkWell(
      onTap: _canEditMemory(memory) ? () => _openAddMemory(existing: memory) : null,
      borderRadius: BorderRadius.circular(21),
      child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _deepTeal.withValues(alpha: 0.09),
            blurRadius: 19,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _memoryImage(memory),

                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x65000000),
                        Color(0x00000000),
                        Color(0x30000000),
                      ],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),

                Positioned(
                  left: 13,
                  top: 13,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _darkTeal.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 14,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          _usingSamples
                              ? 'FAMILY MEMORY · SAMPLE'
                              : 'PHOTO MEMORY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 13,
                  bottom: 13,
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: _coral,
                      size: 23,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: _mintSoft,
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: _primaryTeal,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _formatMemoryDate(memory.memoryDate),
                        style: const TextStyle(
                          color: _primaryTeal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (memory.caption != null &&
                          memory.caption!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Text(
                          memory.caption!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _memoryImage(MemoryItem memory) {
    final path = memory.mediaPath?.trim();

    if (path == null || path.isEmpty) {
      return _imageFallback();
    }

    if (path.startsWith('https://') || path.startsWith('http://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _imageFallback();
        },
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return _imageFallback();
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC5EBDE), Color(0xFFE8F8EF)],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.photo_library_outlined,
        color: _primaryTeal,
        size: 65,
      ),
    );
  }

  // ==========================================
  // VOICE / SONG MEMORY CARD
  // ==========================================

  Widget _audioCard(MemoryItem memory, {required bool isVoice}) {
    return Container(
      decoration: BoxDecoration(
        color: isVoice ? Colors.white : _mintSoft,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _deepTeal.withValues(alpha: 0.055),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        child: Row(
          children: [
            if (isVoice)
              const ElderAvatar(
                asset: ElderAssets.kamalaAvatar,
                size: 45,
                border: false,
              )
            else
              const CircleAvatar(
                radius: 23,
                backgroundColor: _darkTeal,
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    memory.caption?.trim().isNotEmpty == true
                        ? memory.caption!
                        : isVoice
                        ? 'A voice memory'
                        : 'A special song',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 10.5),
                  ),

                  const SizedBox(height: 12),

                  // Decorative waveform only.
                  // No fake playback progress.
                  _waveform(color: isVoice ? _primaryTeal : _gold),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Material(
              color: isVoice ? _darkTeal : Colors.white,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: isVoice ? 'Voice playback' : 'Song playback',
                onPressed: () {
                  _showMessage(
                    'Audio playback is not connected '
                    'yet for this memory.',
                  );
                },
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: isVoice ? Colors.white : _primaryTeal,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waveform({required Color color}) {
    const heights = <double>[
      7,
      13,
      18,
      10,
      20,
      12,
      8,
      17,
      23,
      12,
      16,
      9,
      21,
      14,
      8,
      18,
      12,
      7,
      16,
      10,
      18,
      13,
    ];

    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < heights.length; i++) ...[
            Expanded(
              child: Center(
                child: Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: i < 11 ? color : color.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),

            if (i != heights.length - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SAMPLE LABEL
  // ==========================================

  Widget _sampleNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _mintSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: _primaryTeal),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'Sample memories are shown here. '
              'Add your own memories to replace them.',
              style: TextStyle(color: _ink, fontSize: 10.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY FILTER STATE
  // ==========================================

  Widget _emptyState() {
    final label = switch (filter) {
      1 => 'No photo memories yet',
      2 => 'No voice memories yet',
      3 => 'No songs saved yet',
      _ => 'No memories yet',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: _mintSoft,
            child: Icon(
              Icons.auto_stories_outlined,
              color: _primaryTeal,
              size: 32,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Every special moment deserves a place.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ERROR / RETRY
  // ==========================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 42, color: _coral),

            const SizedBox(height: 12),

            const Text(
              'Could not load memories',
              style: TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });

                _loadMemories();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FIXED ADD MEMORY BUTTON
  // ==========================================

  Widget _bottomAction() {
    return Container(
      color: _cream,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () => _openAddMemory(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _coral,
            foregroundColor: Colors.white,
            elevation: 3,
            shadowColor: _coral.withValues(alpha: 0.20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 23),
          label: const Text(
            'Add a memory',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DATE FORMAT
  // ==========================================

  String _formatMemoryDate(DateTime date) {
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}
