import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_strings.dart';

/// The same destination styling is used on every companion tabbed screen.
class CompanionBottomNavigation extends StatelessWidget {
  const CompanionBottomNavigation({
    super.key,
    required this.selectedLanguage,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.matchesIcon = Icons.people_outline,
    this.selectedMatchesIcon = Icons.people,
  });

  final CompanionLanguage selectedLanguage;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final IconData matchesIcon;
  final IconData selectedMatchesIcon;

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(selectedLanguage);
    return NavigationBar(
      height: MediaQuery.textScalerOf(context).scale(72).clamp(72.0, 112.0),
      selectedIndex: selectedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: strings.home,
        ),
        NavigationDestination(
          icon: Icon(matchesIcon),
          selectedIcon: Icon(selectedMatchesIcon),
          label: strings.matches,
        ),
        NavigationDestination(
          icon: const Icon(Icons.event_outlined),
          selectedIcon: const Icon(Icons.event),
          label: strings.checkIns,
        ),
      ],
    );
  }
}
