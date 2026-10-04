import 'package:flutter/material.dart';

import 'companion_scaffold.dart';

/// Compact CareLink header used by the request review and pending screens.
class CompanionFlowHeader extends StatelessWidget {
  const CompanionFlowHeader({
    super.key,
    required this.onBack,
    required this.backTooltip,
    this.trailingIcon = Icons.more_horiz,
    this.trailingColor = CompanionPalette.teal,
    this.showCoralDot = false,
  });

  final VoidCallback onBack;
  final String backTooltip;
  final IconData? trailingIcon;
  final Color trailingColor;
  final bool showCoralDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: backTooltip,
          icon: const Icon(Icons.chevron_left),
          color: CompanionPalette.teal,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: CompanionPalette.border),
          ),
        ),
        Expanded(
          child: Center(
            child: Semantics(
              label: 'CareLink',
              child: ExcludeSemantics(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 3,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CompanionPalette.teal,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Text(
                      'CareLink',
                      style: TextStyle(
                        color: CompanionPalette.teal,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showCoralDot)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: CompanionPalette.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Decorative until a companion-specific menu is approved.
        ExcludeSemantics(
          child: trailingIcon == null
              ? const SizedBox(width: 44, height: 44)
              : Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: CompanionPalette.border),
                  ),
                  child: Icon(trailingIcon, color: trailingColor, size: 20),
                ),
        ),
      ],
    );
  }
}
