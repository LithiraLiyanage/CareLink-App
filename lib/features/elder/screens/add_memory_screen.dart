import 'package:flutter/material.dart';

import '../widgets/elder_assets.dart';
import '../widgets/elder_colors.dart';
import '../widgets/elder_ui.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final titleController = TextEditingController(
    text: 'Family New Year',
  );

  int visibility = 0;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElderPhoneScaffold(
      backgroundColor: ElderColors.background,
      statusBarColor: ElderColors.background,
      darkStatusBar: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _mediaSection(),
                  _titleField(),
                  _dateField(),
                  _visibilitySection(),
                  const _PrivacyCard(),
                  _actions(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElderBackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Add a memory',
          style: TextStyle(
            color: ElderColors.textDark,
            fontSize: 24,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Save a photo, story or voice note',
          style: TextStyle(
            color: ElderColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _mediaSection() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              ElderAssets.addMemoryPhoto,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: ElderColors.mintSoft,
              border: Border.all(color: ElderColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: ElderColors.deepTeal,
                    size: 23,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Add photo',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Tap to replace',
                  style: TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Memory title'),
        const SizedBox(height: 7),
        SizedBox(
          height: 56,
          child: TextField(
            controller: titleController,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              color: ElderColors.textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.title_rounded,
                color: ElderColors.deepTeal,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 11),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: ElderColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: ElderColors.deepTeal),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date'),
        const SizedBox(height: 7),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: ElderColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ElderColors.mintSoft,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: ElderColors.deepTeal,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '01 Jan 1998',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ElderColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _visibilitySection() {
    const labels = ['Only me', 'Family', 'Companion'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Visibility'),
        const SizedBox(height: 7),
        Row(
          children: List.generate(labels.length, (index) {
            final selected = visibility == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 7,
                ),
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        visibility = index;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          selected ? ElderColors.darkTeal : Colors.white,
                      foregroundColor:
                          selected ? Colors.white : ElderColors.deepTeal,
                      side: BorderSide(
                        color: selected
                            ? ElderColors.darkTeal
                            : ElderColors.border,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                    ),
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        ElderPrimaryButton(
          label: 'Save memory',
          height: 54,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () async {
              final ok = await elderConfirm(
                context,
                title: 'Delete this memory?',
                message: 'This action cannot be undone.',
                confirmLabel: 'Delete',
                destructive: true,
              );

              if (!ok || !context.mounted) return;
              Navigator.of(context).maybePop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC94354),
              side: const BorderSide(color: ElderColors.coral),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Delete memory',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: ElderColors.textMuted,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ElderColors.mintSoft,
        border: Border.all(color: ElderColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.lock_outline_rounded,
              color: ElderColors.deepTeal,
              size: 19,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private by default.',
                  style: TextStyle(
                    color: ElderColors.textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'You choose who can see it.',
                  style: TextStyle(
                    color: ElderColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
