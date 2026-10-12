/// Firebase-independent helpers for companion model serialization.
List<String> companionStringList(Object? value) => value is List
    ? List.unmodifiable(value.whereType<String>())
    : const <String>[];

DateTime companionDateTime(Object? value) => switch (value) {
  DateTime date => date,
  String text => DateTime.parse(text),
  int milliseconds => DateTime.fromMillisecondsSinceEpoch(milliseconds),
  _ => throw const FormatException('A companion date is missing or invalid.'),
};

DateTime? companionOptionalDateTime(Object? value) =>
    value == null ? null : companionDateTime(value);
