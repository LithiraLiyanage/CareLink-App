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
        : const Duration(milliseconds: 180);
    final radius = BorderRadius.circular(24);

    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      child: AnimatedScale(
        scale: selected ? 1.02 : 1,
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? CompanionPalette.coral.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? CompanionPalette.coral
                  : CompanionPalette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => onSelected(!selected),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    widthFactor: 1,
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: CompanionPalette.ink,
                          fontSize: 15,
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
