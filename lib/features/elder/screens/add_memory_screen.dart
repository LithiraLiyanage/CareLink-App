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
  final titleController = TextEditingController(text: 'Family New Year');
  int visibility = 0;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Only me', 'Family', 'Companion'];

    return ElderPhoneScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 7, 18, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElderBackButton(onPressed: () => Navigator.pop(context)),
            const SizedBox(height: 10),
            const Text(
              'Add a memory',
              style: TextStyle(
                color: ElderColors.textDark,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Save a photo, story or voice note',
              style: TextStyle(
                color: ElderColors.textMuted,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      ElderAssets.addMemoryPhoto,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: ElderColors.mintSoft,
                      border: Border.all(color: ElderColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.add_rounded,
                            color: ElderColors.deepTeal,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add photo',
                          style: TextStyle(
                            color: ElderColors.textDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tap to replace',
                          style: TextStyle(
                            color: ElderColors.textMuted,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _label('Memory title'),
            const SizedBox(height: 5),
            TextField(
              controller: titleController,
              style: const TextStyle(
                color: ElderColors.textDark,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.title_rounded,
                  color: ElderColors.deepTeal,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _label('Date'),
            const SizedBox(height: 5),
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ElderColors.deepTeal),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: ElderColors.deepTeal,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '01 Jan 1998',
                    style: TextStyle(
                      color: ElderColors.textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _label('Visibility'),
            const SizedBox(height: 5),
            Row(
              children: List.generate(labels.length, (i) {
                final selected = visibility == i;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () => setState(() => visibility = i),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? ElderColors.darkTeal
                              : Colors.white,
                          foregroundColor: selected
                              ? Colors.white
                              : ElderColors.deepTeal,
                          side: const BorderSide(
                            color: ElderColors.deepTeal,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: Text(
                          labels[i],
                          style: const TextStyle(fontSize: 8.5),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            const ElderInfoCard(
              icon: Icons.check_rounded,
              title: 'Private by default.',
              subtitle: 'You choose who can see it.',
            ),
            const SizedBox(height: 10),
            ElderPrimaryButton(
              label: 'Save memory',
              height: 50,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              height: 46,
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
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC94354),
                  side: const BorderSide(color: ElderColors.coral),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text(
                  'Delete memory',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: ElderColors.textMuted,
        fontSize: 8.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
