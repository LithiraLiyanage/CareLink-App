import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/coordinator/coordinator_access_guard.dart';
import 'firebase_options.dart';

/// Development-only entrypoint for manually testing the Coordinator screens
/// without a Coordinator account:
///
///   flutter run -d chrome -t lib/coordinator_preview.dart --web-port 5000
///
/// then open `/#/coordinator-case`. The case screens use the in-memory
/// mock repository. `lib/main.dart` never imports this file, so production
/// builds keep the real Coordinator/Admin custom-claims check.
Future<void> main() async {
  // Fail closed if this entrypoint is ever built in release mode.
  if (kReleaseMode) {
    throw StateError('Coordinator preview is a development-only entrypoint.');
  }

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    CoordinatorAccessScope(
      check: () async => !kReleaseMode,
      child: const CareLinkApp(),
    ),
  );
}
