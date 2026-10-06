import 'package:flutter/material.dart';

/// Static coordinator view for recording a safety case outcome before
/// closing the case.
class AuditOutcomeCloseCaseScreen extends StatelessWidget {
  const AuditOutcomeCloseCaseScreen({super.key});

  static const _teal = Color(0xFF00695C);
  static const _darkTeal = Color(0xFF004D40);
  static const _coral = Color(0xFFF26F6A);
  static const _darkCoral = Color(0xFFE85D5A);
  static const _mint = Color(0xFFF2F9F7);
  static const _lightTeal = Color(0xFFE0F2EF);
  static const _primaryText = Color(0xFF123B3A);
  static const _secondary = Color(0xFF55706E);
  static const _muted = Color(0xFF829390);
  static const _line = Color(0xFFD5E5E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: _teal, size: 21),
        ),
        title: const Text(
          'CareLink',
          style: TextStyle(
            color: _teal,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _lightTeal,
              child: Icon(Icons.person_rounded, color: _teal, size: 19),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -72,
            right: -70,
            child: _SoftCircle(size: 176),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: const SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Case Outcome',
                        style: TextStyle(
                          color: _darkTeal,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Record the actions taken and close the case.',
                        style: TextStyle(color: _secondary, fontSize: 12),
                      ),
                      SizedBox(height: 16),
                      _CaseCard(),
                      SizedBox(height: 16),
                      _FieldLabel('Action Taken'),
                      SizedBox(height: 6),
                      _DropdownField('Contacted Approved Person'),
                      SizedBox(height: 13),
                      _FieldLabel('Outcome'),
                      SizedBox(height: 6),
                      _DropdownField('Elder contacted successfully'),
                      SizedBox(height: 13),
                      _FieldLabel('Notes'),
                      SizedBox(height: 6),
                      _NotesField(),
                      SizedBox(height: 18),
                      _CloseCaseButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: AuditOutcomeCloseCaseScreen._lightTeal,
              child: Icon(Icons.person_rounded,
                  size: 27, color: AuditOutcomeCloseCaseScreen._teal),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mrs. Silva',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AuditOutcomeCloseCaseScreen._darkTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mother',
                    style: TextStyle(
                      color: AuditOutcomeCloseCaseScreen._secondary,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Case #001',
                    style: TextStyle(
                      color: AuditOutcomeCloseCaseScreen._muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AuditOutcomeCloseCaseScreen._darkTeal,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.fromLTRB(13, 8, 10, 8),
        decoration: _fieldDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AuditOutcomeCloseCaseScreen._primaryText,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down,
                size: 22, color: AuditOutcomeCloseCaseScreen._teal),
          ],
        ),
      );
}

class _NotesField extends StatelessWidget {
  const _NotesField();

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: _fieldDecoration(),
        child: const Text(
          'Spoke with daughter. Elder is safe and well.',
          style: TextStyle(
            color: AuditOutcomeCloseCaseScreen._primaryText,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      );
}

class _CloseCaseButton extends StatelessWidget {
  const _CloseCaseButton();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: ElevatedButton(
          // Visual only: case closing is not implemented.
          onPressed: () => Navigator.of(context).pushNamed('/case-closed'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AuditOutcomeCloseCaseScreen._coral,
            foregroundColor: Colors.white,
            overlayColor: AuditOutcomeCloseCaseScreen._darkCoral,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Close Case',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

BoxDecoration _fieldDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: AuditOutcomeCloseCaseScreen._line),
    );

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AuditOutcomeCloseCaseScreen._line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0800695C),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    );

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFDFF1ED),
          shape: BoxShape.circle,
        ),
      );
}
