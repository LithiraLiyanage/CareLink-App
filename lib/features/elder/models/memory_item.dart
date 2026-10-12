enum MemoryType {
  photo,
  voice,
  song,
}

class MemoryItem {
  final String id;
  final String ownerId;
  final MemoryType type;
  final String title;
  final String? caption;
  final String? mediaPath;
  final DateTime memoryDate;
  final DateTime createdAt;
  final String visibility;

  const MemoryItem({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.title,
    this.caption,
    this.mediaPath,
    required this.memoryDate,
    required this.createdAt,
    this.visibility = 'Only me',
  });

  MemoryItem copyWith({
    String? id,
    String? ownerId,
    MemoryType? type,
    String? title,
    String? caption,
    String? mediaPath,
    DateTime? memoryDate,
    DateTime? createdAt,
    String? visibility,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      mediaPath: mediaPath ?? this.mediaPath,
      memoryDate: memoryDate ?? this.memoryDate,
      createdAt: createdAt ?? this.createdAt,
      visibility: visibility ?? this.visibility,
    );
  }
}
