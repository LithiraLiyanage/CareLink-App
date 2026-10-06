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

  Map<String, Object?> toMap() => {
    'id': id,
    'interest': interest,
    'textEn': textEn,
    'textSi': textSi,
    'textTa': textTa,
    'active': active,
  };

  factory ConversationIdea.fromMap(Map<String, dynamic> map) =>
      ConversationIdea(
        id: map['id'] as String,
        interest: map['interest'] as String? ?? 'General',
        textEn: map['textEn'] as String? ?? '',
        textSi: map['textSi'] as String? ?? '',
        textTa: map['textTa'] as String? ?? '',
        active: map['active'] != false,
      );

  // Existing W09 renders its approved translations through CompanionStrings.
  String get category => interest;
  String get prompt => textEn;
}
