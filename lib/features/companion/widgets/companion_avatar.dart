import 'package:flutter/material.dart';

import 'companion_scaffold.dart';

/// Approved profile images can be shown here; initials remain the fallback.
class CompanionAvatar extends StatelessWidget {
  const CompanionAvatar({
    super.key,
    required this.name,
    required this.size,
    this.imagePath = '',
    this.imageUrl,
    this.heroTag,
  });

  final String name;
  final double size;
  final String imagePath;
  final String? imageUrl;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: CompanionPalette.coral.withValues(alpha: 0.14),
      child: Text(
        initials,
        style: TextStyle(
          color: CompanionPalette.ink,
          fontSize: size * 0.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final image = imageUrl != null && imageUrl!.isNotEmpty
        ? ClipOval(
            child: Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          )
        : imagePath.isEmpty
        ? fallback
        : ClipOval(
            child: Image.asset(
              imagePath,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          );
    final avatar = Semantics(
      label: '$name profile',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size + 8,
          height: size + 8,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CompanionPalette.coral, width: 2),
          ),
          child: image,
        ),
      ),
    );
    return heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar);
  }
}
