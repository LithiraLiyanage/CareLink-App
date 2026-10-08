
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'elder_colors.dart';

/// Responsive scaffold without a simulated phone frame.
/// Uses the device's actual status bar and safe areas.
class ElderPhoneScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final Color backgroundColor;
  final bool darkStatusBar;
  final Color? statusBarColor;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const ElderPhoneScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.backgroundColor = ElderColors.background,
    this.darkStatusBar = true,
    this.statusBarColor,
    this.scrollable = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(
            padding: padding,
            child: child,
          )
        : Padding(
            padding: padding,
            child: child,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? backgroundColor,
        statusBarIconBrightness:
            darkStatusBar ? Brightness.dark : Brightness.light,
        statusBarBrightness:
            darkStatusBar ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        body: ColoredBox(
          color: statusBarColor ?? backgroundColor,
          child: SafeArea(
            top: true,
            bottom: bottomNavigationBar == null,
            child: ColoredBox(
              color: backgroundColor,
              child: SizedBox.expand(
                child: content,
              ),
            ),
          ),
        ),
        bottomNavigationBar: bottomNavigationBar == null
            ? null
            : ColoredBox(
                color: backgroundColor,
                child: SafeArea(
                  top: false,
                  child: bottomNavigationBar!,
                ),
              ),
      ),
    );
  }
}

/// Retained for compatibility with any other preview screens.
/// ElderPhoneScaffold no longer displays a fake status bar.
class ElderIosStatusBar extends StatelessWidget {
  final Color backgroundColor;
  final bool darkIcons;

  const ElderIosStatusBar({
    super.key,
    required this.backgroundColor,
    this.darkIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        darkIcons ? const Color(0xFF111719) : Colors.white;

    return Container(
      height: 26,
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(17, 5, 15, 2),
      child: Row(
        children: [
          Text(
            '9:41',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(Icons.signal_cellular_alt_rounded,
              color: color, size: 14),
          const SizedBox(width: 4),
          Icon(Icons.wifi_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Icon(Icons.battery_full_rounded,
              color: color, size: 17),
        ],
      ),
    );
  }
}

/// Available for existing preview code, but not automatically
/// inserted into the real app scaffold.
class ElderHomeIndicator extends StatelessWidget {
  const ElderHomeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Center(
        child: Container(
          width: 128,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF0E2426),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class ElderBottomNav extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onHome;
  final VoidCallback? onSchedule;
  final VoidCallback? onMemory;
  final VoidCallback? onProfile;

  const ElderBottomNav({
    super.key,
    required this.selectedIndex,
    this.onHome,
    this.onSchedule,
    this.onMemory,
    this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home', onHome),
      (Icons.schedule_rounded, 'Schedule', onSchedule),
      (Icons.photo_library_outlined, 'Memory', onMemory),
      (Icons.person_outline_rounded, 'Profile', onProfile),
    ];

    return Container(
      height: 68,
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF073F42).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          final item = items[index];

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: item.$3,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? ElderColors.mint
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        item.$1,
                        size: 20,
                        color: ElderColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$2,
                      maxLines: 1,
                      style: TextStyle(
                        color: ElderColors.textDark,
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ElderAvatar extends StatelessWidget {
  final String asset;
  final double size;
  final bool border;

  const ElderAvatar({
    super.key,
    required this.asset,
    this.size = 46,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(
            color: ElderColors.mint,
            child: Icon(
              Icons.person_rounded,
              color: ElderColors.darkTeal,
            ),
          );
        },
      ),
    );
  }
}

class ElderPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double height;

  const ElderPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = ElderColors.darkTeal,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class ElderOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color foregroundColor;
  final Color? backgroundColor;
  final double height;

  const ElderOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.foregroundColor = ElderColors.darkTeal,
    this.backgroundColor,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor ?? Colors.white,
          side: BorderSide(
            color: foregroundColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class ElderBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool filled;

  const ElderBackButton({
    super.key,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFFCAF1EC)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: filled
              ? null
              : Border.all(color: ElderColors.deepTeal),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
          color: ElderColors.deepTeal,
        ),
      ),
    );
  }
}

class ElderInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ElderInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ElderColors.border),
            ),
            child: Icon(
              icon,
              color: ElderColors.deepTeal,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ElderStatusPill extends StatelessWidget {
  final String label;
  final bool filled;

  const ElderStatusPill(
    this.label, {
    super.key,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: filled ? ElderColors.darkTeal : Colors.white,
        border: Border.all(color: ElderColors.deepTeal),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : ElderColors.deepTeal,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Future<bool> elderConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: destructive
                    ? ElderColors.coral
                    : ElderColors.darkTeal,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
