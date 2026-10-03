import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import 'recommended_companions_screen.dart';

class MatchingPreferencesScreen extends StatefulWidget {
  const MatchingPreferencesScreen({super.key});

  @override
  State<MatchingPreferencesScreen> createState() =>
      _MatchingPreferencesScreenState();
}

class _MatchingPreferencesScreenState extends State<MatchingPreferencesScreen> {
  static const Color _careLinkTeal = Color(0xFF087F83);
  static const Color _careLinkCoral = Color(0xFFFF625F);
  static const Color _chipBorderColor = Color(0xFFE7E0EC);

  static const List<String> _interestOptions = [
    'Gardening',
    'Music',
    'Cooking',
    'Books',
    'Movies',
    'Travel',
    'Culture',
  ];

  static const List<String> _availabilityOptions = ['Weekdays', 'Weekends'];

  static const List<String> _preferredTimeOptions = [
    'Morning',
    'Afternoon',
    'Evening',
  ];

  static const List<String> _checkInTypeOptions = ['Voice', 'Video'];

  CompanionLanguage _selectedLanguage = CompanionLanguage.english;
  final Set<String> _selectedInterests = {};
  String? _selectedAvailability;
  String? _selectedPreferredTime;
  String? _selectedCheckInType;

  void _toggleInterest(String interest, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedInterests.add(interest);
      } else {
        _selectedInterests.remove(interest);
      }
    });
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onFindCompanions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/companion-recommendations'),
        builder: (_) =>
            RecommendedCompanionsScreen(selectedLanguage: _selectedLanguage),
      ),
    );
  }

  void _onNavigationSelected(int index) {
    if (index == 1) {
      return;
    }

    _showPlaceholderMessage('Navigation will be connected in a later step.');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandHeader(),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'Find Your Companion',
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose what matters most to you.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _buildProfileHelper(textTheme),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Preferred Companion Language',
                    children: CompanionLanguage.values.map((language) {
                      final displayLabel = language.displayLabel;
                      final isSelected = _selectedLanguage == language;

                      return _buildChoiceChip(
                        label: displayLabel,
                        semanticsLabel:
                            '$displayLabel preferred companion language',
                        isSelected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedLanguage = language;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Shared interests',
                    children: _interestOptions.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);

                      return _buildFilterChip(
                        label: interest,
                        semanticsLabel: '$interest shared interest',
                        isSelected: isSelected,
                        onSelected: (selected) {
                          _toggleInterest(interest, selected);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Availability',
                    children: _availabilityOptions.map((availability) {
                      return _buildChoiceChip(
                        label: availability,
                        semanticsLabel: '$availability availability',
                        isSelected: _selectedAvailability == availability,
                        onSelected: (_) {
                          setState(() {
                            _selectedAvailability = availability;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Preferred time',
                    children: _preferredTimeOptions.map((time) {
                      return _buildChoiceChip(
                        label: time,
                        semanticsLabel: '$time preferred time',
                        isSelected: _selectedPreferredTime == time,
                        onSelected: (_) {
                          setState(() {
                            _selectedPreferredTime = time;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Check-in type',
                    helperText: 'Optional',
                    children: _checkInTypeOptions.map((type) {
                      return _buildChoiceChip(
                        label: type,
                        semanticsLabel: '$type check-in type',
                        isSelected: _selectedCheckInType == type,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCheckInType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onFindCompanions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _careLinkTeal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: const Text('Find Companions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          selectedIndex: 1,
          backgroundColor: CareLinkTheme.surfaceColor,
          indicatorColor: _careLinkCoral.withValues(alpha: 0.16),
          onDestinationSelected: _onNavigationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: _careLinkTeal),
              label: 'Matches',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event, color: _careLinkTeal),
              label: 'Check-ins',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Semantics(
      container: true,
      label: 'CareLink',
      child: ExcludeSemantics(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/carelink_logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Care',
                    style: TextStyle(color: _careLinkTeal),
                  ),
                  TextSpan(
                    text: 'Link',
                    style: TextStyle(color: _careLinkCoral),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHelper(TextTheme textTheme) {
    return Semantics(
      label: 'Preferences are from your approved profile',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _careLinkCoral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 17,
                color: _careLinkCoral,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'From your approved profile',
                  style: textTheme.bodySmall?.copyWith(
                    color: CareLinkTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    String? helperText,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CareLinkTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _chipBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: textTheme.titleMedium),
                ),
              ),
              if (helperText != null)
                Text(
                  helperText,
                  style: textTheme.bodySmall?.copyWith(
                    color: _careLinkTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String semanticsLabel,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return Semantics(
      label: semanticsLabel,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        showCheckmark: false,
        selectedColor: _careLinkCoral,
        backgroundColor: CareLinkTheme.surfaceColor,
        side: BorderSide(color: isSelected ? _careLinkCoral : _chipBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: TextStyle(
          color: CareLinkTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String semanticsLabel,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return Semantics(
      label: semanticsLabel,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        showCheckmark: false,
        selectedColor: _careLinkCoral,
        backgroundColor: CareLinkTheme.surfaceColor,
        side: BorderSide(color: isSelected ? _careLinkCoral : _chipBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: TextStyle(
          color: CareLinkTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
