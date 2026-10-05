import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/match_preferences.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_option_chip.dart';
import '../widgets/companion_route.dart';
import '../widgets/companion_scaffold.dart';
import 'recommended_companions_screen.dart';

class MatchingPreferencesScreen extends StatefulWidget {
  const MatchingPreferencesScreen({super.key});

  @override
  State<MatchingPreferencesScreen> createState() =>
      _MatchingPreferencesScreenState();
}

class _MatchingPreferencesScreenState extends State<MatchingPreferencesScreen> {
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
  bool _findButtonPressed = false;

  void _setFindButtonPressed(bool pressed) {
    if (_findButtonPressed == pressed) return;
    setState(() => _findButtonPressed = pressed);
  }

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
    final preferences = MatchPreferences(
      preferredLanguage: _selectedLanguage.storedValue,
      interests: List.unmodifiable(_selectedInterests),
      availability: _selectedAvailability ?? '',
      preferredTime: _selectedPreferredTime ?? '',
      checkInType: _selectedCheckInType ?? '',
    );
    Navigator.of(context).push(
      CompanionRoute<void>(
        context: context,
        settings: const RouteSettings(name: '/companion-recommendations'),
        builder: (_) => RecommendedCompanionsScreen(
          selectedLanguage: _selectedLanguage,
          preferences: preferences,
        ),
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
    final textTheme = CompanionScaffold.textTheme(context);
    final animationDuration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return CompanionScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/companion_w01_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
          ),
          const ColoredBox(color: Color(0xC8FFFDF9)),
          CompanionEntrance(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBrandHeader(),
                              const SizedBox(height: 22),
                              Semantics(
                                header: true,
                                child: Text(
                                  'Find Your Companion',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: 30,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose what matters most to you.',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 9),
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: CompanionPalette.coral,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildProfileHelper(textTheme),
                              const SizedBox(height: 20),
                              _buildSection(
                                context,
                                title: 'Preferred Companion Language',
                                children: CompanionLanguage.values.map((
                                  language,
                                ) {
                                  final displayLabel = language.displayLabel;
                                  final isSelected =
                                      _selectedLanguage == language;

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
                              const SizedBox(height: 20),
                              _buildSection(
                                context,
                                title: 'Shared interests',
                                children: _interestOptions.map((interest) {
                                  final isSelected = _selectedInterests
                                      .contains(interest);

                                  return _buildChoiceChip(
                                    label: interest,
                                    semanticsLabel: '$interest shared interest',
                                    isSelected: isSelected,
                                    onSelected: (selected) {
                                      _toggleInterest(interest, selected);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
                              _buildSection(
                                context,
                                title: 'Availability',
                                children: _availabilityOptions.map((
                                  availability,
                                ) {
                                  return _buildChoiceChip(
                                    label: availability,
                                    semanticsLabel:
                                        '$availability availability',
                                    isSelected:
                                        _selectedAvailability == availability,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedAvailability = availability;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 20),
                              _buildSection(
                                context,
                                title: 'Check-in type (optional)',
                                children: _checkInTypeOptions.map((type) {
                                  return _buildChoiceChip(
                                    label: type,
                                    semanticsLabel: '$type check-in type',
                                    isSelected: _selectedCheckInType == type,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCheckInType = selected
                                            ? type
                                            : null;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: SizedBox(
                          width: double.infinity,
                          child: Listener(
                            onPointerDown: (_) => _setFindButtonPressed(true),
                            onPointerUp: (_) => _setFindButtonPressed(false),
                            onPointerCancel: (_) =>
                                _setFindButtonPressed(false),
                            child: AnimatedScale(
                              scale: _findButtonPressed ? 0.98 : 1,
                              duration: animationDuration,
                              curve: Curves.easeOut,
                              child: ElevatedButton(
                                onPressed: _onFindCompanions,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CompanionPalette.teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                ),
                                child: const Text('Find Companions'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CompanionBottomNavigation(
          selectedLanguage: CompanionLanguage.english,
          selectedIndex: 1,
          onDestinationSelected: _onNavigationSelected,
          matchesIcon: Icons.favorite_border,
          selectedMatchesIcon: Icons.favorite_border,
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
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CompanionPalette.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'CareLink',
              style: TextStyle(
                color: CompanionPalette.teal,
                fontSize: 15,
                fontWeight: FontWeight.w700,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CompanionPalette.mint.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'From your approved profile',
            style: textTheme.bodySmall?.copyWith(
              color: CompanionPalette.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final textTheme = CompanionScaffold.textTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 8, children: children),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String semanticsLabel,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return CompanionOptionChip(
      label: label,
      semanticsLabel: semanticsLabel,
      selected: isSelected,
      onSelected: onSelected,
    );
  }
}
