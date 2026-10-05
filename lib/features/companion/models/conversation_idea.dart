class ConversationIdea {
  final String id;
  final String interest;
  final String textEn;
  final String textSi;
  final String textTa;
  final bool active;

  const ConversationIdea({
    required this.id,
    String? interest,
    String? textEn,
    String? category,
    String? prompt,
    this.textSi = '',
    this.textTa = '',
    this.active = true,
  }) : assert(interest != null || category != null),
       assert(textEn != null || prompt != null),
       interest = interest ?? category ?? '',
       textEn = textEn ?? prompt ?? '';

  // Existing W09 renders its approved translations through CompanionStrings.
  String get category => interest;
  String get prompt => textEn;
}
