// Grant or revoke the coordinator custom claim on an existing Firebase Auth user.
// Requires Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS).
// Usage: node tools/set_coordinator_claim.cjs user@example.com [--revoke]
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

const projectId = 'carelink-hci';
const [email, flag] = process.argv.slice(2);
if (!email || (flag && flag !== '--revoke')) {
  console.error('Usage: node tools/set_coordinator_claim.cjs <email> [--revoke]');
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId });

(async () => {
  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  const claims = { ...(user.customClaims || {}) };
  if (flag === '--revoke') {
    delete claims.coordinator;
  } else {
    claims.coordinator = true;
  }
  await auth.setCustomUserClaims(user.uid, claims);
  if (flag === '--revoke') {
    await auth.revokeRefreshTokens(user.uid);
  }
  console.log(`${flag === '--revoke' ? 'Revoked' : 'Granted'} coordinator claim for ${email} (${user.uid}).`);
})().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
