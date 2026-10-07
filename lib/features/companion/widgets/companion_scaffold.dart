import 'package:flutter/material.dart';

/// Visual tokens used only by the companion flow. The app-wide theme is untouched.
abstract final class CompanionPalette {
  static const teal = Color(0xFF087F83);
  static const coral = Color(0xFFFF625F);
  static const ink = Color(0xFF173F42);
  static const muted = Color(0xFF5B7272);
  static const background = Color(0xFFF7FBF9);
  static const mint = Color(0xFFEAF6F2);
  static const border = Color(0xFFDCE9E5);
  static const amber = Color(0xFFFFF4DE);
}

class CompanionScaffold extends StatelessWidget {
  const CompanionScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  static TextTheme textTheme(BuildContext context) {
    final base = Theme.of(context).textTheme;
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        color: CompanionPalette.ink,
        fontWeight: FontWeight.w800,
        height: 1.16,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: CompanionPalette.ink,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(color: CompanionPalette.ink),
      titleMedium: base.titleMedium?.copyWith(color: CompanionPalette.ink),
      bodyMedium: base.bodyMedium?.copyWith(
        color: CompanionPalette.muted,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: CompanionPalette.muted,
        height: 1.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: CompanionPalette.teal,
      secondary: CompanionPalette.coral,
      surface: Colors.white,
      onSurface: CompanionPalette.ink,
    );
    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    final theme = base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: CompanionPalette.background,
      textTheme: textTheme(context),
      appBarTheme: const AppBarTheme(
        backgroundColor: CompanionPalette.background,
        foregroundColor: CompanionPalette.ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: CompanionPalette.ink.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CompanionPalette.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: CompanionPalette.teal,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: CompanionPalette.teal.withValues(alpha: 0.18),
          shape: pill,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          foregroundColor: CompanionPalette.teal,
          side: const BorderSide(color: CompanionPalette.teal),
          shape: pill,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: CompanionPalette.mint,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? CompanionPalette.teal
                : CompanionPalette.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? CompanionPalette.teal
                : CompanionPalette.muted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: CompanionPalette.background,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
