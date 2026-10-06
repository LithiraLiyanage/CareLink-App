import 'package:flutter/material.dart';

import '../../../app/routes.dart';

class FamilyLinkingScreen extends StatelessWidget {
  const FamilyLinkingScreen({super.key});

  static const _ink = Color(0xFF00695C);
  static const _titleInk = Color(0xFF004D40);
  static const _muted = Color(0xFF55706E);
  static const _hint = Color(0xFF8AA09D);
  static const _mint = Color(0xFFF2F9F7);
  static const _coral = Color(0xFFF26F6A);
  static const _line = Color(0xFFD5E5E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mint,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _mint,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 48,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: const Center(
            child: Icon(Icons.arrow_back_rounded, color: _ink, size: 23),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'CareLink',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          SizedBox(
            width: 48,
            child: Center(
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFE0F2EF),
                child: Icon(Icons.person_rounded, color: _ink, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172, color: Color(0xFFDFF1ED)),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38, color: Color(0xFFDFF1ED)),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _FamilyIllustration()),
                      const SizedBox(height: 9),
                      const Text(
                        'Link with an Older Adult',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _titleInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Send a request to connect with your\nfamily member.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 19),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _line),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A00695C),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InputField(
                              label: "Elder's Name",
                              hint: "Enter elder's full name",
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                            ),
                            SizedBox(height: 12),
                            _DropdownField(
                              label: 'Relationship',
                              hint: 'Select relationship',
                              icon: Icons.family_restroom_rounded,
                              options: ['Daughter', 'Son'],
                            ),
                            SizedBox(height: 12),
                            _InputField(
                              label: 'Contact / ID',
                              hint: 'Phone number or ID',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Semantics(
                        button: true,
                        label: 'Send Request',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                Navigator.of(context).pushNamed(AppRoutes.familyPending),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _coral,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20E85D5A),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 9),
                                  Text(
                                    'Send Request',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: TextField(
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        cursorColor: FamilyLinkingScreen._ink,
        style: _fieldTextStyle,
        decoration: _fieldDecoration(hint, icon),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
  });

  final String label;
  final String hint;
  final IconData icon;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        hint: Text(hint, style: _fieldHintStyle),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 21,
          color: FamilyLinkingScreen._ink,
        ),
        style: _fieldTextStyle,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(11),
        decoration: _fieldDecoration(null, icon),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (_) {},
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: FamilyLinkingScreen._titleInk,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

const _fieldTextStyle = TextStyle(
  color: FamilyLinkingScreen._titleInk,
  fontSize: 13,
);

const _fieldHintStyle = TextStyle(
  color: FamilyLinkingScreen._hint,
  fontSize: 13,
);

InputDecoration _fieldDecoration(String? hint, IconData icon) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    hintText: hint,
    hintStyle: _fieldHintStyle,
    prefixIcon: Icon(icon, size: 19, color: FamilyLinkingScreen._ink),
    prefixIconConstraints: const BoxConstraints(minWidth: 41, minHeight: 46),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: border(FamilyLinkingScreen._line),
    focusedBorder: border(FamilyLinkingScreen._ink, 1.5),
  );
}

class _FamilyIllustration extends StatelessWidget {
  const _FamilyIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 112,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 126,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF1ED),
              borderRadius: BorderRadius.circular(42),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 4,
            child: _PersonFigure(
              skin: const Color(0xFFE9B99B),
              hair: const Color(0xFF465B55),
              shirt: const Color(0xFF5C8F88),
              size: 61,
              elder: false,
            ),
          ),
          Positioned(
            right: 14,
            bottom: 1,
            child: _PersonFigure(
              skin: const Color(0xFFD9A986),
              hair: const Color(0xFF89938A),
              shirt: const Color(0xFF557F78),
              size: 75,
              elder: true,
            ),
          ),
          Positioned(
            top: 7,
            right: 17,
            child: Container(
              width: 29,
              height: 29,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFDFC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, size: 16, color: FamilyLinkingScreen._coral),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonFigure extends StatelessWidget {
  const _PersonFigure({
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.size,
    required this.elder,
  });

  final Color skin;
  final Color hair;
  final Color shirt;
  final double size;
  final bool elder;

  @override
  Widget build(BuildContext context) {
    final head = size * 0.40;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: size * 0.76,
            height: size * 0.52,
            decoration: BoxDecoration(
              color: shirt,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(size * 0.30),
                bottom: const Radius.circular(13),
              ),
            ),
          ),
          Positioned(
            top: 1,
            child: Container(
              width: head,
              height: head,
              decoration: BoxDecoration(color: skin, shape: BoxShape.circle),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: head,
                  height: head * (elder ? 0.40 : 0.48),
                  decoration: BoxDecoration(
                    color: hair,
                    borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(30),
                      bottom: Radius.circular(head * 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (elder)
            Positioned(
              top: head * 0.65,
              child: Container(
                width: head * 0.17,
                height: 2,
                color: const Color(0xFF8B6657),
              ),
            ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
