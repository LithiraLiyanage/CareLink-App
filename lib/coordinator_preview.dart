import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/coordinator/coordinator_access_guard.dart';
import 'features/coordinator/coordinator_case_scope.dart';
import 'features/coordinator/services/coordinator_case_repository.dart';
import 'features/coordinator/services/firestore_coordinator_case_repository.dart';
import 'features/coordinator/services/mock_coordinator_case_repository.dart';
import 'firebase_options.dart';

/// Development-only entrypoint for manually testing the Coordinator screens
/// without going through the app's login flow.
///
/// Mock data (no backend):
///
///   flutter run -t lib/coordinator_preview.dart --route /coordinator-case
///
/// Real Firestore data on the local emulators, signed in as the seeded
/// coordinator (see `tools/seed_coordinator_emulator.cjs`):
///
///   flutter run -t lib/coordinator_preview.dart --route /coordinator-case \
///     --dart-define=CARELINK_EMULATOR=true
///
/// On web, use `-d chrome --web-port 5000` and open `/#/coordinator-case`.
/// On a physical phone, also pass `--dart-define=CARELINK_EMULATOR_HOST=<your
/// computer's LAN IP>`. `lib/main.dart` never imports this file, so production
/// builds keep the real Coordinator/Admin custom-claims check.
const _useEmulators = bool.fromEnvironment('CARELINK_EMULATOR');
const _emulatorHostOverride = String.fromEnvironment('CARELINK_EMULATOR_HOST');

// Must match firebase.emulators.json and the seed script.
const _authEmulatorPort = 9299;
const _firestoreEmulatorPort = 8188;
const _coordinatorEmail = 'coordinator@carelink.test';
const _coordinatorPassword = 'CareLink-test-123!';

Future<void> main() async {
  // Fail closed if this entrypoint is ever built in release mode.
  if (kReleaseMode) {
    throw StateError('Coordinator preview is a development-only entrypoint.');
  }

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final repository = _useEmulators
      ? await _emulatorRepository()
      : MockCoordinatorCaseRepository();

  runApp(
    CoordinatorAccessScope(
      // Only skips the app-side guard; with emulators, Firestore rules still
      // require the seeded account's coordinator claim.
      check: () async => !kReleaseMode,
      child: CoordinatorCaseScope(
        repository: repository,
        child: const CareLinkApp(),
      ),
    ),
  );
}

/// A repository on a separate Firebase app signed in as the seeded
/// coordinator. The default app stays signed out, so the splash screen under
/// the Coordinator route does not redirect into the account setup flow.
Future<CoordinatorCaseRepository> _emulatorRepository() async {
  final app = await Firebase.initializeApp(
    name: 'coordinator-preview',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  final firestore = FirebaseFirestore.instanceFor(app: app);
  // The Android emulator reaches the host machine through 10.0.2.2.
  final host = _emulatorHostOverride.isNotEmpty
      ? _emulatorHostOverride
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : '127.0.0.1';
  await auth.useAuthEmulator(host, _authEmulatorPort);
  firestore.useFirestoreEmulator(host, _firestoreEmulatorPort);
  await auth.signInWithEmailAndPassword(
    email: _coordinatorEmail,
    password: _coordinatorPassword,
  );
  return FirestoreCoordinatorCaseRepository(firestore: firestore, auth: auth);
}
