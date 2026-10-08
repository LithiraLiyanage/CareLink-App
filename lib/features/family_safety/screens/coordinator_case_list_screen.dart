import 'package:flutter/material.dart';

import '../../../app/routes.dart';

/// Static coordinator view of missed check-in safety cases.
class CoordinatorCaseListScreen extends StatelessWidget {
  const CoordinatorCaseListScreen({super.key});

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _secondary = Color(0xFF708486);
  static const _line = Color(0xFFD1EBE7);

  static const _cases = [
    _CaseData('Mrs. Silva', '30 Sep 2026, 10:30 AM', 'Pending Review',
        Color(0xFFF59E0B), Color(0xFFFFF4DF)),
    _CaseData('Mr. Perera', '30 Sep 2026, 2:00 PM', 'Retry Requested',
        Color(0xFF2196F3), Color(0xFFE8F3FF)),
    _CaseData('Ms. Fernando', '29 Sep 2026, 11:00 AM', 'Rescheduled',
        Color(0xFF2196F3), Color(0xFFE8F3FF)),
    _CaseData('Ms. Jayasinghe', '29 Sep 2026, 3:00 PM', 'Contact Follow-up',
        Color(0xFF00A878), Color(0xFFDFF5ED)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF073F42),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Open missed session',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.missedSession),
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
        ),
        title: const Text('CareLink', style: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        )),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Open case details',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.coordinatorCaseDetail,
            ),
            padding: const EdgeInsets.only(right: 18),
            constraints: const BoxConstraints(),
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, color: Color(0xFF073F42), size: 19),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              children: [
                const Text('Safety Cases', style: TextStyle(
                  color: _darkTeal, fontSize: 20, fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 4),
                const Text('Review and manage missed check-ins.', style: TextStyle(
                  color: _secondary, fontSize: 13,
                )),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(label: 'All (12)', selected: true),
                    _FilterChip(label: 'Pending (5)'),
                    _FilterChip(label: 'Closed (7)'),
                  ],
                ),
                const SizedBox(height: 14),
                for (final item in _cases) ...[
                  _CaseCard(item: item),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _CoordinatorNavigationBar(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CoordinatorCaseListScreen._teal : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: selected ? null : Border.all(color: CoordinatorCaseListScreen._line),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : CoordinatorCaseListScreen._teal,
          fontSize: 11, fontWeight: FontWeight.w600,
        )),
      );
}

class _CaseData {
  const _CaseData(this.name, this.time, this.status, this.statusColor, this.statusBg);
  final String name;
  final String time;
  final String status;
  final Color statusColor;
  final Color statusBg;
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.item});
  final _CaseData item;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: CoordinatorCaseListScreen._line),
          boxShadow: const [BoxShadow(
            color: Color(0x0A073F42), blurRadius: 10, offset: Offset(0, 2),
          )],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: CoordinatorCaseListScreen._lightTeal,
              child: Icon(Icons.person_rounded, size: 26,
                  color: CoordinatorCaseListScreen._teal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: CoordinatorCaseListScreen._darkTeal,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  const Text('Missed Check-in', style: TextStyle(
                    color: CoordinatorCaseListScreen._secondary, fontSize: 11,
                  )),
                  const SizedBox(height: 2),
                  Text(item.time, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF9AABAC), fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: item.statusBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(item.status, maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: item.statusColor, fontSize: 9,
                    fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              tooltip: 'Open case details',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.coordinatorCaseDetail,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.chevron_right_rounded,
                color: CoordinatorCaseListScreen._teal, size: 20),
            ),
          ],
        ),
      );
}

class _CoordinatorNavigationBar extends StatelessWidget {
  const _CoordinatorNavigationBar();

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          height: 66,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: CoordinatorCaseListScreen._line)),
          ),
          child: const Row(children: [
            _NavigationItem(icon: Icons.assignment_outlined, label: 'Cases', selected: true),
            _NavigationItem(icon: Icons.notifications_none_rounded, label: 'Notifications'),
            _NavigationItem(icon: Icons.person_outline_rounded, label: 'Profile'),
          ]),
        ),
      );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.icon, required this.label, this.selected = false});
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CoordinatorCaseListScreen._teal : const Color(0xFF708486);
    return Expanded(
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
