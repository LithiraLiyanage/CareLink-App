import 'package:flutter/material.dart';

/// Shared companion header; the name wraps instead of overflowing at large text sizes.
class CareLinkBrandHeader extends StatelessWidget {
  const CareLinkBrandHeader({super.key, this.large = false});

  final bool large;

  static const Color _teal = Color(0xFF087F83);
  static const Color _coral = Color(0xFFFF625F);

  @override
  Widget build(BuildContext context) {
    final logoSize = large ? 44.0 : 38.0;

    return Semantics(
      container: true,
      label: 'CareLink',
      child: ExcludeSemantics(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(large ? 10 : 9),
              child: Image.asset(
                'assets/images/carelink_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            SizedBox(width: large ? 10 : 9),
            Flexible(
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Care',
                      style: TextStyle(color: _teal),
                    ),
                    TextSpan(
                      text: 'Link',
                      style: TextStyle(color: _coral),
                    ),
                  ],
                ),
                softWrap: true,
                style: TextStyle(
                  fontSize: large ? 25 : 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: large ? -0.5 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
