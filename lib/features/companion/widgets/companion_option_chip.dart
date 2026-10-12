import 'package:flutter/material.dart';

import 'companion_scaffold.dart';

class CompanionOptionChip extends StatelessWidget {
  const CompanionOptionChip({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final radius = BorderRadius.circular(24);

    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      child: AnimatedScale(
        scale: selected ? 1.01 : 1,
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF7F4)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? CompanionPalette.coral
                  : CompanionPalette.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => onSelected(!selected),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 76, minHeight: 40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    widthFactor: 1,
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: CompanionPalette.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
