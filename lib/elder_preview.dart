import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';

import 'features/elder/screens/active_video_call_kamala_screen.dart';
import 'features/elder/screens/active_video_call_nethmi_screen.dart';
import 'features/elder/screens/add_memory_screen.dart';
import 'features/elder/screens/checkin_complete_kamala_screen.dart';
import 'features/elder/screens/checkin_complete_nethmi_screen.dart';
import 'features/elder/screens/elder_home_screen.dart';
import 'features/elder/screens/kamala_ready_screen.dart';
import 'features/elder/screens/memory_lane_screen.dart';
import 'features/elder/screens/my_schedule_screen.dart';
import 'features/elder/screens/nethmi_ready_screen.dart';
import 'features/elder/screens/new_recurring_checkin_screen.dart';
import 'features/elder/screens/reschedule_checkin_screen.dart';
import 'features/elder/services/firebase_elder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseElderService.instance.seedDemoDataIfEmpty();

  runApp(const ElderPreviewApp());
}

class ElderPreviewApp extends StatelessWidget {
  const ElderPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareLink Elder Preview',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorSchemeSeed: const Color(0xFF006E69),
      ),
      home: const ElderPreviewMenu(),
    );
  }
}

class ElderPreviewMenu extends StatelessWidget {
  const ElderPreviewMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final screens = <(String, Widget)>[
      ('E01 — Elder Home', const ElderHomeScreen()),
      ('E02 — My Schedule', const MyScheduleScreen()),
      ('E03 — New recurring check-in', const NewRecurringCheckInScreen()),
      ('E04 — Reschedule check-in', const RescheduleCheckInScreen()),
      ('E05 — Nethmi is ready', const NethmiReadyScreen()),
      ('E06 — Kamala is ready', const KamalaReadyScreen()),
      ('E07 — Active call — Kamala', const ActiveVideoCallKamalaScreen()),
      ('E08 — Active call — Nethmi', const ActiveVideoCallNethmiScreen()),
      ('E09 — Complete — Nethmi', const CheckInCompleteNethmiScreen()),
      ('E10 — Complete — Kamala', const CheckInCompleteKamalaScreen()),
      ('E11 — Memory Lane', const MemoryLaneScreen()),
      ('E12 — Add a memory', const AddMemoryScreen()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        title: const Text(
          'CareLink — Elder Screens',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: screens.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final item = screens[index];

              return SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ElderScaledPreview(initialScreen: item.$2),
                      ),
                    );
                  },
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ElderScaledPreview extends StatelessWidget {
  static const double phoneWidth = 393;
  static const double phoneHeight = 852;

  final Widget initialScreen;

  const ElderScaledPreview({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14100F),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: RepaintBoundary(
                  // Paint the 393 x 852 phone as one layer first.
                  // This prevents 1-pixel hairline seams when the desktop
                  // browser scales the phone by a fractional amount.
                  child: SizedBox(
                    width: phoneWidth,
                    height: phoneHeight,
                    child: Navigator(
                      onGenerateRoute: (_) {
                        return MaterialPageRoute(builder: (_) => initialScreen);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: SafeArea(
              child: Material(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(22),
                elevation: 2,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(22),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 17,
                          color: Color(0xFF005B59),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'All screens',
                          style: TextStyle(
                            color: Color(0xFF005B59),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
