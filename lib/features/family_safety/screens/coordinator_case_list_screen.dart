import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../auth/services/auth_service.dart';
import '../../coordinator/coordinator_case_scope.dart';
import '../../coordinator/coordinator_case_ui.dart';
import '../../coordinator/models/safety_case.dart';
import '../../coordinator/services/coordinator_case_repository.dart';

/// Coordinator view of missed check-in safety cases from the
/// [CoordinatorCaseRepository].
class CoordinatorCaseListScreen extends StatefulWidget {
  const CoordinatorCaseListScreen({super.key});

  static const _teal = Color(0xFF00776F);
  static const _darkTeal = Color(0xFF073F42);
  static const _mint = Color(0xFFF5FBF9);
  static const _lightTeal = Color(0xFFE7F6F1);
  static const _secondary = Color(0xFF708486);
  static const _line = Color(0xFFD1EBE7);

  @override
  State<CoordinatorCaseListScreen> createState() =>
      _CoordinatorCaseListScreenState();
}

class _CoordinatorCaseListScreenState extends State<CoordinatorCaseListScreen> {
  CoordinatorCaseRepository? _repository;
  late Stream<List<SafetyCase>> _cases;
  SafetyCaseFilter _filter = SafetyCaseFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = CoordinatorCaseScope.of(context);
    if (repository != _repository) {
      _repository = repository;
      _cases = repository.watchCases();
    }
  }

  void _reload() => setState(() => _cases = _repository!.watchCases());

  Future<void> _signOut() async {
    try {
      await AuthService().logoutUser();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    }
  }

  void _openCase(SafetyCase safetyCase) => Navigator.pushNamed(
    context,
    AppRoutes.coordinatorCaseDetail,
    arguments: safetyCase.id,
  );

  List<Widget> _content(AsyncSnapshot<List<SafetyCase>> snapshot) {
    if (snapshot.hasError) {
      return [
        CoordinatorCaseMessage(
          icon: Icons.error_outline_rounded,
          title: 'Could not load safety cases.',
          message: describeCaseError(snapshot.error!),
          actionLabel: 'Try again',
          onAction: _reload,
        ),
      ];
    }
    final cases = snapshot.data;
    if (cases == null) return const [CoordinatorCaseMessage.loading()];

    final counts = SafetyCaseCounts.fromCases(cases);
    final visible = _filter.apply(cases);
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final filter in SafetyCaseFilter.values)
            _FilterChip(
              label: '${filter.label} (${counts.countFor(filter)})',
              selected: filter == _filter,
              onTap: () => setState(() => _filter = filter),
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (visible.isEmpty)
        CoordinatorCaseMessage(
          icon: Icons.inbox_outlined,
          title: switch (_filter) {
            SafetyCaseFilter.all => 'No safety cases yet.',
            SafetyCaseFilter.pending => 'No pending cases.',
            SafetyCaseFilter.closed => 'No closed cases.',
          },
          message: 'Missed check-ins that need review will appear here.',
        )
      else
        for (final safetyCase in visible) ...[
          _CaseCard(safetyCase: safetyCase, onTap: () => _openCase(safetyCase)),
          const SizedBox(height: 10),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoordinatorCaseListScreen._mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF073F42),
        surfaceTintColor: Colors.transparent,
        // No Coordinator menu destination exists yet, so no leading control.
        automaticallyImplyLeading: false,
        title: const Text('CareLink', style: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        )),
        centerTitle: true,
        // Account menu; there is no Coordinator profile screen yet.
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: PopupMenuButton<void>(
              tooltip: 'Account',
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, color: Color(0xFF073F42), size: 19),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<void>(
                  onTap: _signOut,
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: StreamBuilder<List<SafetyCase>>(
              stream: _cases,
              builder: (context, snapshot) => ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                children: [
                  const Text('Safety Cases', style: TextStyle(
                    color: CoordinatorCaseListScreen._darkTeal,
                    fontSize: 20, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 4),
                  const Text('Review and manage missed check-ins.', style: TextStyle(
                    color: CoordinatorCaseListScreen._secondary, fontSize: 13,
                  )),
                  if (_repository!.usesMockData) ...[
                    const SizedBox(height: 6),
                    const CoordinatorMockDataNote(
                      'Showing mock sample cases. Not connected to live data.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  ..._content(snapshot),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _CoordinatorNavigationBar(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onTap, this.selected = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? CoordinatorCaseListScreen._teal : Colors.white,
          shape: StadiumBorder(
            side: selected
                ? BorderSide.none
                : const BorderSide(color: CoordinatorCaseListScreen._line),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Text(label, style: TextStyle(
                color: selected ? Colors.white : CoordinatorCaseListScreen._teal,
                fontSize: 11, fontWeight: FontWeight.w600,
              )),
            ),
          ),
        ),
      );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.safetyCase, required this.onTap});
  final SafetyCase safetyCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = caseStatusColors(safetyCase.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Ink(
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
                    Text(safetyCase.elderDisplayName, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: CoordinatorCaseListScreen._darkTeal,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(safetyCase.reason.label, style: const TextStyle(
                      color: CoordinatorCaseListScreen._secondary, fontSize: 11,
                    )),
                    const SizedBox(height: 2),
                    Text(formatCaseDateTime(safetyCase.scheduledAt), maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF9AABAC), fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(safetyCase.status.label, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: status.foreground, fontSize: 9,
                      fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                tooltip: 'Open ${safetyCase.caseLabel}',
                onPressed: onTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_right_rounded,
                  color: CoordinatorCaseListScreen._teal, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          child: Row(children: [
            const _NavigationItem(icon: Icons.assignment_outlined, label: 'Cases', selected: true),
            _NavigationItem(
              icon: Icons.verified_user_outlined,
              label: 'Verifications',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.coordinatorVerifications,
              ),
            ),
            const _NavigationItem(icon: Icons.notifications_none_rounded,
              label: 'Notifications', unavailable: true),
            const _NavigationItem(icon: Icons.person_outline_rounded,
              label: 'Profile', unavailable: true),
          ]),
        ),
      );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.unavailable = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;

  /// No Coordinator screen exists for this item yet: it is dimmed and tapping
  /// it explains that instead of navigating.
  final bool unavailable;
  final VoidCallback? onTap;

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is not available yet.')));
  }

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? CoordinatorCaseListScreen._teal
        : unavailable
            ? const Color(0xFFB4C2C3)
            : const Color(0xFF708486);
    return Expanded(
      child: InkWell(
        onTap: unavailable ? () => _showUnavailable(context) : onTap,
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
      ),
    );
  }
}
