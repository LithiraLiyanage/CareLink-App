import 'package:flutter/material.dart';

import '../../elder/widgets/elder_assets.dart';
import '../../elder/widgets/elder_colors.dart';

/// Circular, edge-to-edge photo used on Home, My Connection, and My Schedule.
/// Keeps Firestore profileImageUrl as the first choice and a local fallback.
class CompanionProfileAvatar extends StatelessWidget {
  const CompanionProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final remote = imageUrl?.trim() ?? '';

    Widget fallback() {
      if (trimmed.toLowerCase().startsWith('nethmi')) {
        return Image.asset(
          ElderAssets.nethmiAvatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, error, stack) => _initial(initial),
        );
      }
      return _initial(initial);
    }

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: ElderColors.mintSoft,
          child: remote.isEmpty
              ? fallback()
              : Image.network(
                  remote,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, error, stack) => fallback(),
                ),
        ),
      ),
    );
  }

  Widget _initial(String initial) => Center(
    child: Text(
      initial,
      style: TextStyle(
        color: ElderColors.darkTeal,
        fontWeight: FontWeight.w900,
        fontSize: size * .36,
      ),
    ),
  );
}
