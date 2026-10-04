import 'package:flutter/material.dart';

import '../models/companion_language.dart';
import '../models/companion_profile.dart';
import '../models/companion_strings.dart';
import '../models/conversation_idea.dart';
import '../widgets/companion_bottom_navigation.dart';
import '../widgets/companion_entrance.dart';
import '../widgets/companion_flow_header.dart';
import '../widgets/companion_scaffold.dart';

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
  static const Color _coral = CompanionPalette.coral;
  static const Color _amber = Color(0xFF9A6200);

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
        if (MediaQuery.of(context).disableAnimations) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
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
    final textTheme = CompanionScaffold.textTheme(context);
    final orderedIdeas = [
      for (var offset = 0; offset < _ideas.length; offset++)
        _ideas[(_firstIdeaIndex + offset) % _ideas.length],
    ];

    return CompanionScaffold(
      body: SafeArea(
        bottom: false,
        child: CompanionEntrance(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompanionFlowHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      backTooltip: strings.backToCheckIn,
                      trailingIcon: null,
                      showCoralDot: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  strings.conversationIdeas,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontSize: 27,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 34,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: _coral,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ExcludeSemantics(
                          child: Image.asset(
                            'assets/images/companion_conversation_illustration.png',
                            width: 108,
                            height: 88,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _coral),
                      ),
                      child: Text(
                        strings.conversationIdeasHelper,
                        style: const TextStyle(
                          color: _coral,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final idea in orderedIdeas) ...[
                      _buildIdeaCard(context, strings, idea),
                      const SizedBox(height: 11),
                    ],
                  ],
                ),
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
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.36,
              ),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  color: CompanionPalette.background,
                  padding: const EdgeInsets.fromLTRB(20, 7, 20, 8),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final anotherButton = OutlinedButton(
                                onPressed: _showAnotherIdea,
                                child: Text(
                                  strings.showAnotherIdea,
                                  textAlign: TextAlign.center,
                                ),
                              );
                              final backButton = ElevatedButton(
                                onPressed: () => _backToCheckIn(strings),
                                child: Text(
                                  strings.backToCheckIn,
                                  textAlign: TextAlign.center,
                                ),
                              );
                              final compactEnglish =
                                  widget.selectedLanguage ==
                                      CompanionLanguage.english &&
                                  MediaQuery.textScalerOf(context).scale(1) <=
                                      1.2 &&
                                  constraints.maxWidth >= 320;
                              if (!compactEnglish) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    anotherButton,
                                    const SizedBox(height: 8),
                                    backButton,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: anotherButton),
                                  const SizedBox(width: 10),
                                  Expanded(child: backButton),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.conversationIdeasReassurance,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            CompanionBottomNavigation(
              selectedLanguage: widget.selectedLanguage,
              selectedIndex: 1,
              matchesIcon: Icons.favorite_border,
              selectedMatchesIcon: Icons.favorite_border,
              onDestinationSelected: (index) {
                if (index == 2) {
                  _backToCheckIn(strings);
                } else if (index != 1) {
                  _showMessage(strings.navigationComingSoon);
                }
              },
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
    final (accent, icon) = switch (idea.id) {
      'gardening' => (const Color(0xFF2F855F), Icons.local_florist_rounded),
      'music' => (CompanionPalette.coral, Icons.music_note_rounded),
      'food-traditions' => (_amber, Icons.ramen_dining_rounded),
      _ => (CompanionPalette.coral, Icons.photo_library_rounded),
    };
    final compactEnglish =
        widget.selectedLanguage == CompanionLanguage.english &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.2 &&
        MediaQuery.sizeOf(context).width >= 380;
    final useButton = Semantics(
      selected: selected,
      hint: category,
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedIdeaId = idea.id),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? _coral.withValues(alpha: 0.12)
              : CompanionPalette.mint,
          foregroundColor: selected ? _coral : CompanionPalette.teal,
          side: BorderSide(color: selected ? _coral : Colors.transparent),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        child: Text(
          selected ? strings.ideaSelected : strings.useThisIdea,
          textAlign: TextAlign.center,
        ),
      ),
    );

    return Card(
      key: ValueKey('conversation-idea-${idea.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? _coral : CompanionPalette.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 2,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, size: 28, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: textTheme.titleMedium?.copyWith(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (compactEnglish)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  strings.conversationIdeaPrompt(idea),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: CompanionPalette.ink,
                                    fontSize: 13,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              useButton,
                            ],
                          )
                        else ...[
                          Text(
                            strings.conversationIdeaPrompt(idea),
                            style: textTheme.bodyMedium?.copyWith(
                              color: CompanionPalette.ink,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: useButton,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
