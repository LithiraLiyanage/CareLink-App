import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../services/family_link_service.dart';
import 'family_notifications_screen.dart';

class FamilyLinkingScreen extends StatefulWidget {
  const FamilyLinkingScreen({super.key});

  static const _ink = Color(0xFF00776F);
  static const _titleInk = Color(0xFF073F42);
  static const _muted = Color(0xFF708486);
  static const _hint = Color(0xFF9AABAC);
  static const _background = Color(0xFFF5FBF9);
  static const _coral = Color(0xFFFF5369);
  static const _line = Color(0xFFD1EBE7);

  @override
  State<FamilyLinkingScreen> createState() => _FamilyLinkingScreenState();
}

class _FamilyLinkingScreenState extends State<FamilyLinkingScreen> {
  static const _titleInk = FamilyLinkingScreen._titleInk;
  static const _muted = FamilyLinkingScreen._muted;
  static const _background = FamilyLinkingScreen._background;
  static const _coral = FamilyLinkingScreen._coral;
  static const _line = FamilyLinkingScreen._line;

  final _elderNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  String? _relationship;
  bool _sending = false;

  @override
  void dispose() {
    _elderNameController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendRequest() async {
    final elderName = _elderNameController.text.trim();
    final idNumber = _idNumberController.text.trim();
    final relationship = _relationship;

    if (elderName.isEmpty || relationship == null || idNumber.isEmpty) {
      _showMessage('Please fill in all the fields.');
      return;
    }

    setState(() => _sending = true);
    try {
      await FamilyLinkService.instance.sendRequest(
        elderName: elderName,
        relationship: relationship,
        idNumber: idNumber,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.familyPending);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not send the request: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: _titleInk,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 48,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: const Center(
            child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 23),
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'CareLink',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: const [
          SizedBox(
            width: 48,
            child: Center(child: _ProfileApprovalButton()),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -48,
            left: -54,
            child: _SoftCircle(size: 172, color: Color(0xFFE7F6F1)),
          ),
          const Positioned(
            top: 50,
            left: 56,
            child: _SoftCircle(size: 38, color: Color(0xFFE7F6F1)),
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
                              color: Color(0x14073F42),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InputField(
                              controller: _elderNameController,
                              label: "Elder's Name",
                              hint: "Enter elder's full name",
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),
                            _DropdownField(
                              label: 'Relationship',
                              hint: 'Select relationship',
                              icon: Icons.family_restroom_rounded,
                              options: const ['Daughter', 'Son'],
                              value: _relationship,
                              onChanged: (value) =>
                                  setState(() => _relationship = value),
                            ),
                            const SizedBox(height: 12),
                            _InputField(
                              controller: _idNumberController,
                              label: 'ID Number',
                              hint: 'Enter your ID number',
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
                            onTap: _sending ? null : _sendRequest,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _coral,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33FF5369),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_sending)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.send_rounded,
                                        size: 18, color: Colors.white),
                                  const SizedBox(width: 9),
                                  Text(
                                    _sending ? 'Sending...' : 'Send Request',
                                    style: const TextStyle(
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

/// Profile avatar that shows a badge with the number of unread approval
/// notifications; tapping it opens the notifications list.
class _ProfileApprovalButton extends StatefulWidget {
  const _ProfileApprovalButton();

  @override
  State<_ProfileApprovalButton> createState() => _ProfileApprovalButtonState();
}

class _ProfileApprovalButtonState extends State<_ProfileApprovalButton> {
  late final Stream<List<FamilyLinkRequest>> _approvals =
      FamilyLinkService.instance.watchApprovals();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyLinkRequest>>(
      stream: _approvals,
      builder: (context, snapshot) {
        final approvals = snapshot.data ?? const <FamilyLinkRequest>[];
        final count =
            approvals.where((request) => !request.seenByRequester).length;

        return Semantics(
          button: true,
          label: count == 0
              ? 'Profile'
              : 'Profile, $count request${count == 1 ? '' : 's'} approved',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FamilyNotificationsScreen(),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    color: FamilyLinkingScreen._titleInk,
                    size: 20,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FamilyLinkingScreen._coral,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: FamilyLinkingScreen._titleInk,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
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
        controller: controller,
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
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        initialValue: value,
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
        onChanged: onChanged,
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
              color: const Color(0xFFE7F6F1),
              borderRadius: BorderRadius.circular(42),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 4,
            child: _PersonFigure(
              skin: const Color(0xFFE9B99B),
              hair: const Color(0xFF465B55),
              shirt: const Color(0xFF00776F),
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
              shirt: const Color(0xFF073F42),
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
