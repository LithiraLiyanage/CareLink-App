// Grants (or revokes) the Coordinator custom claim on an existing Firebase Auth
// account. Coordinators cannot self-register in the app: create the account
// (Firebase console > Authentication > Add user), then run this script.
//
// Needs the Admin SDK and a service account key for the project:
//      npm install --no-save firebase-admin
//      set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account.json
//      node tools/set_coordinator_claim.cjs coordinator@example.com
//      node tools/set_coordinator_claim.cjs coordinator@example.com --revoke
//
// Against the local emulators instead, set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9299
// (no key needed).
//
// The user picks up the claim on their next login; the app refreshes the ID
// token after sign-in, so signing out and back in is enough.
const admin = require('firebase-admin');

// Must match lib/firebase_options.dart.
const projectId = 'carelink-hci';

const [email, flag] = process.argv.slice(2);
if (!email || (flag && flag !== '--revoke')) {
  console.error('Usage: node tools/set_coordinator_claim.cjs <email> [--revoke]');
  process.exit(1);
}

admin.initializeApp({ projectId });

(async () => {
  const user = await admin.auth().getUserByEmail(email);
  const claims = { ...(user.customClaims || {}) };
  if (flag === '--revoke') {
    delete claims.coordinator;
  } else {
    claims.coordinator = true;
  }
  await admin.auth().setCustomUserClaims(user.uid, claims);
  // Ends existing sessions so a revoked coordinator loses access promptly.
  if (flag === '--revoke') await admin.auth().revokeRefreshTokens(user.uid);
  console.log(`${flag === '--revoke' ? 'Revoked' : 'Granted'} coordinator claim for ${email} (${user.uid}).`);
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
