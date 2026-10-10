# CareLink Authentication and Trust Completion Report

Date: 2026-10-10. Project: `carelink-hci`.

## Verification Boundaries

PASS below means the implementation was inspected and the stated automated checks passed. It does not imply that every action was performed against production. No live test users or student documents were created, and no existing user data was deleted. Android device testing was deferred at the user's request; web testing is the current target.

**Final verdict: BACKEND HAS BLOCKING ISSUES.** The remaining live blocker is that the project has no Firebase Storage bucket. Upload code and Storage security tests pass locally, but real student uploads cannot be called working until the bucket is provisioned, rules are deployed, and an actual upload is tested.

## Feature Checklist

| Feature | Result | Evidence / remaining verification |
| --- | --- | --- |
| Firebase Core | PASS | `main.dart` initializes Firebase before `runApp`; existing Android/Web options and project IDs preserved. |
| Email/password registration | PASS: code and emulator | Auth UID owns `users/{uid}`; trimmed name/email, server timestamps, safe failure handling. Live provider enabled. |
| Email/password login | PASS: code and emulator | Firebase sign-in followed by shared account-progress routing. Live account login still needs interactive retest. |
| Logout | PASS: inspected code | Firebase/provider sign-out and accessibility reset; signed-in Welcome exposes Sign Out. Interactive retest required. |
| Google authentication | PASS: inspected code/configuration | Existing native and web sign-in preserved; live Google provider enabled. User previously confirmed success; no new OAuth session was automated. |
| Forgot password | PASS: code and emulator | Reset action/password change tested locally; honest account-existence message. Actual inbox delivery remains a manual check. |
| Email verification | PASS: code and emulator | Resend/check screen; reload and ID-token refresh; password users cannot advance in UI without verification. Actual inbox link needs manual check. |
| Post-login routing | PASS: automated resolver tests | Password verification, missing role, incomplete setup, pending/rejected/trusted verified students and completed accounts covered. |
| Interrupted setup resume | PASS: automated resolver tests | Stored `setupStage` determines next screen; signed-in splash resumes; saved form/preferences/consent are loaded. |
| User creation | PASS: code and emulator | Primary document ID is Auth UID; no separate random user document. |
| Role persistence | PASS: code and emulator | Role confirmation saves `role`, `setupStage` and `updatedAt` before navigation. |
| Profile persistence | PASS: code and emulator | Name, phone, location and role saved without replacing unrelated fields. |
| Language/accessibility persistence | PASS: code and emulator | Language and three accessibility flags saved under the user document. |
| Accessibility applied across app | PASS: widget tests | Larger text, high contrast and reduced motion applied at app level; larger OS text and OS reduced-animation preference preserved. |
| Privacy consent persistence | PASS: code and emulator | Atomic consent/user writes; Privacy Policy required; no medical/emergency consent claims. |
| Student file selection | PASS: inspected implementation | Existing picker accepts JPG/JPEG/PNG/PDF; displays filename. Actual browser/device file selection needs interactive retest. |
| Document size validation | PASS: unit/emulator tests | Nonempty files up to 10 MB accepted; oversized files denied in client and Storage rules. |
| Storage upload | FAIL: live prerequisite missing | Upload implementation and emulator tests pass; live bucket list is empty and no Storage rules release exists. |
| Firestore student submission | PASS: code and emulator | Atomic pending submission plus user update; role/ownership checked; failed writes do not navigate forward. |
| `users.verificationStatus` | PASS: code and emulator | Pending submission updates status and setup completion atomically; clients cannot set approved/verified. |
| Pending status navigation | PASS: inspected code/resolver tests | Successful submission replaces with pending status; Back to Welcome clears previous routes. No approval claim. |
| Firestore security | PASS: emulator and live deployment comparison | Owner isolation/self-approval denial tested; merged file deployed and live source matches local. Existing team/reviewer rules preserved. |
| Storage security | PASS locally; NOT DEPLOYED | Ownership, persisted student role, MIME type and 10 MB cap tested locally. No live bucket/rules release. |
| Relevant automated tests | PASS | Flutter: 20 tests. Firebase emulator suite: 10 tests including parent suite. No real Firebase accounts created. |
| Android full end-to-end test | DEFERRED | User requested web testing now and phone testing later. Not claimed complete. |
| Live Firebase rules verification | PARTIAL | Firestore verified; Storage not deployed because bucket is absent. |

## Live Firebase Evidence

Read-only Firebase Rules, Authentication configuration and bucket-list APIs were used, not inferred from local files.

- Firebase CLI: installed, v15.32.1, authenticated.
- Email/password provider: enabled, password required.
- Google provider: enabled.
- Authorized domains: `localhost`, `carelink-hci.firebaseapp.com`, `carelink-hci.web.app`.
- Firestore deployment: explicitly authorized by user; CLI reported successful compilation and release.
- Firestore release: `projects/carelink-hci/releases/cloud.firestore`.
- Ruleset: `projects/carelink-hci/rulesets/1c773873-ffcb-4a41-8a86-1b2a63e6b7b2`.
- Released at: `2026-10-10T07:34:13.520767Z`.
- Read-back comparison: `localMatchesLive: true`.
- Storage bucket API: HTTP 200, empty bucket list.
- Storage rules release: absent.
- `firebase.json` references `firestore.rules` and `storage.rules`; no index manifest is referenced. The audited auth module uses document lookups, not queries requiring composite indexes. Other team modules' index requirements are outside this assertion.

The deployed baseline contained team matching, connections, scheduling, calls, memories and family-link rules. These were preserved when merging the authentication rules. Existing trusted reviewer behavior was retained; no new approval backend was added. The compiler reported warnings for the baseline's unused `verificationPendingAfter` helper and its `getAfter` call; rules compiled and deployed successfully. These are not Dart analyzer warnings.

## Navigation

Signed out:

`Splash -> Stay Connected -> Trusted Companions -> Privacy Control -> Welcome`.

`Welcome -> Register -> Email Verification -> Choose Role -> Profile Setup -> Language & Accessibility -> Privacy & Consent`.

Google sign-in uses the same account-progress routing but does not require password-account email verification when Firebase already reports the email verified.

- Student Companion: `Privacy & Consent -> Student Verification -> Verification Submitted / Pending Review -> Welcome`.
- Older Adult / Family Caregiver: `Privacy & Consent -> Setup Complete dialog -> Welcome`.
- Returning incomplete accounts resume the persisted step.
- Returning pending students see Pending Review; rejected students can resubmit. Existing trusted approved/verified students can return to Welcome.
- Normal setup back buttons pop; a resumed root step signs out and returns to Welcome rather than trapping the user on an unpoppable route.
- No role dashboards or coordinator approval backend were added.

## Commands and Tests

| Command/check | Result |
| --- | --- |
| `flutter pub get` | PASS |
| `flutter analyze --no-pub` | PASS: No issues found! |
| `flutter test --no-pub` | PASS: 20 tests |
| `flutter build web --no-pub` | PASS |
| `flutter run -d web-server --release --web-hostname localhost --web-port 8093 --no-pub` | PASS: latest code built and served |
| Firebase Auth/Firestore/Storage emulators | PASS: 10 tests; emulator-only `demo-carelink-hci` ID, not a new live project |
| `firebase deploy --project carelink-hci --only firestore:rules --non-interactive` | PASS: authorized Firestore-only deployment |
| `node tools/verify_firebase_rules.cjs --configuration` | PASS: live read-back matches Firestore; Storage absence confirmed |
| Browser smoke test | PASS: mobile onboarding/login navigation, invalid reset email, registration validation and desktop rendering; no live accounts created |

The web app is served at `http://localhost:8093`. Browser smoke tests cover mobile onboarding/login navigation and invalid form input, plus desktop rendering. They do not replace authenticated end-to-end testing.

## Files Modified

- `firestore.rules`
- `storage.rules`
- `lib/app/app.dart`
- `lib/app/theme.dart`
- `lib/features/auth/screens/choose_role_screen.dart`
- `lib/features/auth/screens/forgot_password_screen.dart`
- `lib/features/auth/screens/language_accessibility_screen.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/privacy_consent_screen.dart`
- `lib/features/auth/screens/profile_setup_screen.dart`
- `lib/features/auth/screens/register_screen.dart`
- `lib/features/auth/screens/splash_screen.dart`
- `lib/features/auth/screens/student_verification_screen.dart`
- `lib/features/auth/screens/welcome_screen.dart`
- `lib/features/auth/services/account_setup_service.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/services/student_verification_service.dart`

## Files Created

- `firebase.emulators.json`
- `lib/features/auth/screens/email_verification_screen.dart`
- `lib/features/auth/services/accessibility_controller.dart`
- `lib/features/auth/services/account_flow.dart`
- `lib/features/auth/services/account_flow_navigation.dart`
- `lib/features/auth/services/setup_back_navigation.dart`
- `test/accessibility_controller_test.dart`
- `test/account_flow_resolver_test.dart`
- `test/firebase_backend_emulator_test.cjs`
- `test/web_smoke_test.cjs`
- `tools/verify_firebase_rules.cjs`
- `tools/merge_firestore_rules.cjs`
- `docs/auth_trust_completion_report.md`

Existing `firebase_options.dart`, Android `google-services.json`, project IDs and production package dependencies were not changed. Pre-existing `.vscode` changes were not touched. Build outputs are not application source changes.

## Remaining Firebase Console Steps

1. Open Firebase Console -> **carelink-hci -> Storage -> Get Started**. Provision the bucket, selecting the intended region and approving billing only if you choose to do so when prompted.
2. Confirm the bucket is `carelink-hci.firebasestorage.app`, matching the existing app configuration. If Firebase creates a different bucket name, stop and verify the configuration rather than regenerating the project or silently changing IDs.
3. After provisioning, deploy the reviewed `storage.rules` with `firebase deploy --project carelink-hci --only storage`. This deployment has not been performed. Review any Firebase prompt granting Storage rules access to Firestore for the role check.
4. Read back the Storage release and compare it with the local file; then perform one real student upload and verify both the blob and Firestore documents.

## Manual End-to-End Checklist

Use intentional test accounts; do not delete existing real users. Do not post passwords here.

1. Register an email/password account, open the verification email, refresh verification in the app, and finish each setup step.
2. Close/reload at role, profile, preferences and consent steps; sign in again and verify saved values and the correct resume screen.
3. Test Older Adult and Family Caregiver completion; neither should open student verification.
4. Test Google sign-in with a new and an existing account; verify it does not overwrite completed profile fields. Test logout and sign-in again.
5. Request password reset for an email/password account; check Inbox/Spam and follow the link. Check sender/action URL in Authentication -> Templates if delivery remains missing. Google-only accounts should use Google sign-in.
6. Enable larger text/high contrast/reduce motion, navigate between screens and reload; verify settings persist and content remains readable on the actual device.
7. After Storage setup, choose a supported student document, submit, and inspect `student_verifications/{uid}`, `users/{uid}.verificationStatus == pending` and the user-specific Storage path.
8. Test an oversized/unsupported file and a network/upload failure; ensure no forward navigation or duplicate submission occurs.
9. Check an authenticated different user cannot read/write another user's records or Storage path. Do not loosen rules to test mode.
10. Connect an Android device later and repeat the full flow, including native Google sign-in and file picker. That device pass remains outstanding.

No automatic student approval, Cloud Functions, medical monitoring, emergency detection or surveillance were implemented.
