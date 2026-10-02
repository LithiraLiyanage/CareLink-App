import 'package:flutter/material.dart';

/// Static family caregiver dashboard shown after a connection is approved.
class FamilyDashboardScreen extends StatelessWidget {
  const FamilyDashboardScreen({super.key});

  static const _ink = Color(0xFF00695C);
  static const _titleInk = Color(0xFF004D40);
  static const _muted = Color(0xFF55706E);
  static const _mint = Color(0xFFF2F9F7);
  static const _line = Color(0xFFD5E5E2);
  static const _success = Color(0xFF00A878);
  static const _lightSuccess = Color(0xFFDFF5ED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Open family linking',
          onPressed: () =>
              Navigator.of(context).pushNamed('/family-linking'),
          icon: const Icon(Icons.menu_rounded, color: _ink, size: 24),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE0F2EF),
              child: Icon(Icons.person_rounded, color: _ink, size: 19),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -68,
            right: -64,
            child: _SoftCircle(size: 176),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 13, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Hello, Jane 👋',
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Here's an overview of your family member.",
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      const _MemberCard(),
                      const SizedBox(height: 12),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CheckInCard(
                              title: "Today's Check-in",
                              status: 'Completed',
                              time: '9:15 AM',
                              icon: Icons.check_rounded,
                              iconColor: _success,
                              statusColor: _success,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _CheckInCard(
                              title: 'Next Check-in',
                              status: 'Tomorrow',
                              time: '10:00 AM',
                              icon: Icons.calendar_month_rounded,
                              iconColor: _ink,
                              statusColor: _titleInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _FamilyStatusCard(),
                      const SizedBox(height: 12),
                      const _ConsentCard(),
                      const SizedBox(height: 18),
                      const Text(
                        'Recent Updates',
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _UpdatesCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _DashboardNavigationBar(),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE0F2EF),
            child: Icon(Icons.person_rounded,
                size: 31, color: FamilyDashboardScreen._ink),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mrs. Silva',
                  style: TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text('Mother',
                    style: TextStyle(
                        color: FamilyDashboardScreen._muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: FamilyDashboardScreen._lightSuccess,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: FamilyDashboardScreen._success),
                SizedBox(width: 5),
                Text(
                  'Connected',
                  style: TextStyle(
                    color: FamilyDashboardScreen._success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.title,
    required this.status,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.statusColor,
  });

  final String title;
  final String status;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon == Icons.check_rounded)
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                )
              else
                Icon(icon, size: 23, color: iconColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(time,
              style: const TextStyle(
                  color: FamilyDashboardScreen._muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FamilyStatusCard extends StatelessWidget {
  const _FamilyStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFF2E8D3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.bar_chart_rounded,
              color: FamilyDashboardScreen._ink, size: 23),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Status',
                  style: TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'All scheduled check-ins are on track.',
                  style: TextStyle(
                    color: FamilyDashboardScreen._muted,
                    fontSize: 12,
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

class _ConsentCard extends StatelessWidget {
  const _ConsentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              color: FamilyDashboardScreen._ink, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consent',
                  style: TextStyle(
                    color: FamilyDashboardScreen._titleInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Information sharing',
                  style: TextStyle(
                      color: FamilyDashboardScreen._muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FamilyDashboardScreen._lightSuccess,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Enabled',
                    style: TextStyle(
                      color: FamilyDashboardScreen._success,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View Details',
                style: TextStyle(
                  color: FamilyDashboardScreen._ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: FamilyDashboardScreen._ink, size: 19),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdatesCard extends StatelessWidget {
  const _UpdatesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _UpdateRow(
            icon: Icons.check_rounded,
            iconColor: FamilyDashboardScreen._success,
            title: 'Check-in completed',
            time: 'Today, 9:15 AM',
          ),
          Divider(height: 1, thickness: 1, color: Color(0xFFEAF1EF)),
          _UpdateRow(
            icon: Icons.calendar_month_rounded,
            iconColor: FamilyDashboardScreen._ink,
            title: 'Next check-in scheduled',
            time: 'Tomorrow, 10:00 AM',
          ),
        ],
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51,
      child: Row(
        children: [
          if (icon == Icons.check_rounded)
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
              child: Icon(icon, size: 14, color: Colors.white),
            )
          else
            Icon(icon, size: 21, color: iconColor),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FamilyDashboardScreen._titleInk,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              color: FamilyDashboardScreen._muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardNavigationBar extends StatelessWidget {
  const _DashboardNavigationBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: FamilyDashboardScreen._line)),
        ),
        child: Row(
          children: [
            const _NavigationItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
            ),
            _NavigationItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () => Navigator.of(context).pushNamed('/missed-session'),
            ),
            const _NavigationItem(
              icon: Icons.shield_outlined,
              label: 'Consent',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? FamilyDashboardScreen._ink : const Color(0xFF6F8582);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
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
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: FamilyDashboardScreen._line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0800695C),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    );

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFDFF1ED),
          shape: BoxShape.circle,
        ),
      );
}
