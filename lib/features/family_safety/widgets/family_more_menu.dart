import 'package:flutter/material.dart';

import '../../../app/routes.dart';

const _ink = Color(0xFF00776F);
const _titleInk = Color(0xFF073F42);
const _muted = Color(0xFF708486);

/// Shortcuts to the other family screens. Only screens with a route in
/// app.dart are listed.
void showFamilyMoreMenu(BuildContext context) {
  final navigator = Navigator.of(context);

  void open(String route) {
    navigator.pop();
    navigator.pushNamed(route);
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'More',
                style: TextStyle(
                  color: _titleInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _MoreMenuItem(
              icon: Icons.verified_user_outlined,
              title: 'Approved connection',
              subtitle: 'See who you are linked with',
              onTap: () => open(AppRoutes.familyApproved),
            ),
            _MoreMenuItem(
              icon: Icons.hourglass_top_rounded,
              title: 'My requests',
              subtitle: 'Requests waiting for approval',
              onTap: () => open(AppRoutes.familyPending),
            ),
            _MoreMenuItem(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Link a family member',
              subtitle: 'Send a new link request',
              onTap: () => open(AppRoutes.familyLinking),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: _ink),
      title: Text(
        title,
        style: const TextStyle(
          color: _titleInk,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _muted,
      ),
    );
  }
}
