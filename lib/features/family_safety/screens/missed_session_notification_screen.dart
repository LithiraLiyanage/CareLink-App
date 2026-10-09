import 'package:flutter/material.dart';

import '../../../app/routes.dart';

/// Static missed check-in notification shown to a family caregiver.
class MissedSessionNotificationScreen extends StatelessWidget {
  const MissedSessionNotificationScreen({super.key});

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _coral = Color(0xFFFF5369);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _line = Color(0xFFD1EBE7);
  static const _secondary = Color(0xFF708486);
  static const _orange = Color(0xFFF59E0B);
  static const _lightWarning = Color(0xFFFFF4DF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF073F42),
        surfaceTintColor: Colors.transparent,
        leadingWidth: 64,
        leading: IconButton(
          tooltip: 'Back to family dashboard',
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            AppRoutes.familyDashboard,
          ),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: Color(0xFF073F42), size: 20),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _MissedMark()),
                      const SizedBox(height: 10),
                      const Text(
                        'Missed Check-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Mrs. Silva's scheduled check-in\nwas not completed.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _OlderAdultCard(),
                      const SizedBox(height: 10),
                      const _StatusCard(),
                      const SizedBox(height: 10),
                      const _ExplanationCard(),
                      const SizedBox(height: 16),
                      _ActionButton(
                        label: 'View Details',
                        filled: true,
                        // Family caregivers see check-in updates on their
                        // own dashboard; coordinator cases are not theirs.
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.familyDashboard,
                        ),
                      ),
                      const SizedBox(height: 11),
                      _ActionButton(label: 'Dismiss', filled: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _NotificationNavigationBar(),
    );
  }
}

class _MissedMark extends StatelessWidget {
  const _MissedMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: MissedSessionNotificationScreen._lightWarning,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.warning_amber_rounded,
            color: MissedSessionNotificationScreen._orange, size: 42),
      );
}

class _OlderAdultCard extends StatelessWidget {
  const _OlderAdultCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: MissedSessionNotificationScreen._line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A073F42),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: MissedSessionNotificationScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 30, color: MissedSessionNotificationScreen._teal),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mrs. Silva',
                      style: TextStyle(
                        color: MissedSessionNotificationScreen._darkTeal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                  SizedBox(height: 1),
                  Text('Mother',
                      style: TextStyle(
                          color: MissedSessionNotificationScreen._secondary,
                          fontSize: 12)),
                  SizedBox(height: 3),
                  Text('30 Sep 2026, 10:30 AM',
                      style: TextStyle(color: Color(0xFF9AABAC), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MissedSessionNotificationScreen._lightWarning,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text('Status',
                  style: TextStyle(
                    color: MissedSessionNotificationScreen._darkTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            Icon(Icons.circle,
                size: 9, color: MissedSessionNotificationScreen._orange),
            SizedBox(width: 6),
            Text('Missed',
                style: TextStyle(
                  color: MissedSessionNotificationScreen._orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      );
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F6F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MissedSessionNotificationScreen._line),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                color: MissedSessionNotificationScreen._teal, size: 21),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'The session will be reviewed\naccording to the CareLink safety\nprocess.',
                style: TextStyle(
                  color: MissedSessionNotificationScreen._secondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled, this.onPressed});

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: Material(
          color: filled ? MissedSessionNotificationScreen._coral : Colors.white,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: filled
                    ? null
                    : Border.all(
                        color: MissedSessionNotificationScreen._coral,
                        width: 1.3,
                      ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : MissedSessionNotificationScreen._coral,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
}

class _NotificationNavigationBar extends StatelessWidget {
  const _NotificationNavigationBar();

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          height: 66,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: MissedSessionNotificationScreen._line),
            ),
          ),
          child: const Row(
            children: [
              _NavigationItem(icon: Icons.home_rounded, label: 'Home'),
              _NavigationItem(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                selected: true,
                badge: true,
              ),
              _NavigationItem(
                  icon: Icons.shield_outlined, label: 'Consent'),
            ],
          ),
        ),
      );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? MissedSessionNotificationScreen._teal
        : const Color(0xFF708486);
    return Expanded(
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 25,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (badge)
                    Positioned(
                      right: -7,
                      top: -5,
                      child: Container(
                        width: 14,
                        height: 14,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: MissedSessionNotificationScreen._coral,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('1',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE7F6F1),
          shape: BoxShape.circle,
        ),
      );
}
