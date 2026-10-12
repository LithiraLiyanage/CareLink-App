import 'package:flutter/material.dart';

import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';

class CheckInReflectionResult {
  const CheckInReflectionResult({required this.feeling, required this.note});

  final String feeling;
  final String note;
}

class CheckInReflectionScreen extends StatefulWidget {
  const CheckInReflectionScreen({
    super.key,
    required this.companionName,
    this.initialFeeling,
    this.initialNote = '',
  });

  final String companionName;
  final String? initialFeeling;
  final String initialNote;

  @override
  State<CheckInReflectionScreen> createState() =>
      _CheckInReflectionScreenState();
}

class _CheckInReflectionScreenState extends State<CheckInReflectionScreen> {
  late final TextEditingController _noteController;
  String? _feeling;

  @override
  void initState() {
    super.initState();
    _feeling = widget.initialFeeling;

    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _finishReflection() {
    final feeling = _feeling;

    if (feeling == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose how you felt.')),
      );
      return;
    }

    Navigator.of(context).pop(
      CheckInReflectionResult(
        feeling: feeling,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ElderBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(height: 28),
          const CircleAvatar(
            radius: 40,
            backgroundColor: ElderColors.mintSoft,
            child: Icon(
              Icons.favorite_rounded,
              color: ElderColors.coral,
              size: 45,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How are you feeling?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ElderColors.textDark,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'How did your check-in with '
            '${widget.companionName} make you feel?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ElderColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          _option(label: 'Happy', icon: Icons.sentiment_very_satisfied_rounded),
          const SizedBox(height: 11),
          _option(label: 'Okay', icon: Icons.sentiment_satisfied_rounded),
          const SizedBox(height: 11),
          _option(label: 'Low', icon: Icons.sentiment_dissatisfied_rounded),
          const SizedBox(height: 26),
          const Text(
            'Would you like to add a note?',
            style: TextStyle(
              color: ElderColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: _noteController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Today I enjoyed talking about...',
              hintStyle: const TextStyle(
                color: ElderColors.textMuted,
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: ElderColors.deepTeal,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElderPrimaryButton(
            label: 'Done',
            height: 54,
            color: ElderColors.coral,
            onPressed: _finishReflection,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your answer will appear on the '
            'Check-in Complete screen. '
            'Firestore saving is not enabled yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ElderColors.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _option({required String label, required IconData icon}) {
    final selected = _feeling == label;

    return Material(
      color: selected ? ElderColors.mintSoft : Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () {
          setState(() {
            _feeling = label;
          });
        },
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? ElderColors.deepTeal : ElderColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: ElderColors.deepTeal),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: ElderColors.deepTeal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
