import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../models/conversation_idea.dart';

/// W09: optional, local-only ideas for a friendly check-in conversation.
class ConversationIdeasScreen extends StatefulWidget {
  const ConversationIdeasScreen({
    super.key,
    required this.profile,
    required this.selectedLanguage,
    this.openedFromCheckIn = false,
  });

  final CompanionProfile profile;
  final CompanionLanguage selectedLanguage;

  /// Set to true only when an agreed check-in flow pushes this screen.
  final bool openedFromCheckIn;

  @override
  State<ConversationIdeasScreen> createState() =>
      _ConversationIdeasScreenState();
}

class _ConversationIdeasScreenState extends State<ConversationIdeasScreen> {
  static const Color _teal = Color(0xFF087F83);
  static const Color _coral = Color(0xFFFF625F);
  static const Color _border = Color(0xFFE7E0EC);

  // English source text and stable IDs; translated display text stays in
  // CompanionStrings. No private conversation content is collected or saved.
  static const List<ConversationIdea> _ideas = [
    ConversationIdea(
      id: 'gardening',
      category: 'Gardening',
      prompt: 'What plant do you enjoy growing most?',
    ),
    ConversationIdea(
      id: 'music',
      category: 'Music',
      prompt: 'What song brings back a happy memory?',
    ),
    ConversationIdea(
      id: 'food-traditions',
      category: 'Food & Traditions',
      prompt: 'What meal reminds you of home?',
    ),
    ConversationIdea(
      id: 'memories',
      category: 'Memories',
      prompt: 'Would you like to talk about a favourite photograph?',
    ),
  ];

  final ScrollController _scrollController = ScrollController();
  String? _selectedIdeaId;
  int _firstIdeaIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAnotherIdea() {
    setState(() => _firstIdeaIndex = (_firstIdeaIndex + 1) % _ideas.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _backToCheckIn(CompanionStrings strings) {
    // TODO: The shared check-in flow should pass openedFromCheckIn: true when
    // its route is agreed. This screen does not navigate into another module.
    if (widget.openedFromCheckIn && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _showMessage(strings.navigationComingSoon);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = CompanionStrings(widget.selectedLanguage);
    final textTheme = Theme.of(context).textTheme;
    final orderedIdeas = [
      for (var offset = 0; offset < _ideas.length; offset++)
        _ideas[(_firstIdeaIndex + offset) % _ideas.length],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('CareLink')),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      strings.conversationIdeas,
                      style: textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: _teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.conversationIdeasHelper,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final idea in orderedIdeas) ...[
                    _buildIdeaCard(context, strings, idea),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: CareLinkTheme.surfaceColor,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showAnotherIdea,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          strings.showAnotherIdea,
                          textAlign: TextAlign.center,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(color: _teal),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _backToCheckIn(strings),
                        style: TextButton.styleFrom(
                          foregroundColor: _teal,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(
                          strings.backToCheckIn,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.favorite_outline,
                            size: 18,
                            color: _teal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              strings.conversationIdeasReassurance,
                              style: textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            NavigationBar(
              height: 72,
              selectedIndex: 2,
              backgroundColor: CareLinkTheme.surfaceColor,
              indicatorColor: _coral.withValues(alpha: 0.16),
              onDestinationSelected: (index) {
                if (index == 2) {
                  _backToCheckIn(strings);
                } else {
                  _showMessage(strings.navigationComingSoon);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: strings.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: strings.matches,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.event_outlined),
                  selectedIcon: const Icon(Icons.event, color: _teal),
                  label: strings.checkIns,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaCard(
    BuildContext context,
    CompanionStrings strings,
    ConversationIdea idea,
  ) {
    final selected = _selectedIdeaId == idea.id;
    final category = strings.conversationIdeaCategory(idea);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      key: ValueKey('conversation-idea-${idea.id}'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? _coral : _border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    category,
                    style: textTheme.bodySmall?.copyWith(
                      color: CareLinkTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.conversationIdeaPrompt(idea),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Semantics(
              selected: selected,
              hint: category,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _selectedIdeaId = idea.id),
                icon: Icon(
                  selected
                      ? Icons.check_circle_outline
                      : Icons.lightbulb_outline,
                ),
                label: Text(
                  selected ? strings.ideaSelected : strings.useThisIdea,
                  textAlign: TextAlign.center,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: selected ? _coral : _teal,
                  side: BorderSide(color: selected ? _coral : _teal),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
