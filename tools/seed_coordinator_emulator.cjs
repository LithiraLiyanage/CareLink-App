// Seeds the LOCAL Firebase emulators with a Coordinator account and real-shaped
// data (elders, consent, family links, missed check-ins) for the Coordinator
// safety-case screens. Never touches the live project.
//
// 1. Start the emulators (keep this running):
//      firebase emulators:start --config firebase.emulators.json --project carelink-hci --only auth,firestore
// 2. In another terminal:
//      node tools/seed_coordinator_emulator.cjs
// 3. Run the preview against the emulators:
//      flutter run -t lib/coordinator_preview.dart --route /coordinator-case --dart-define=CARELINK_EMULATOR=true
//
// Safe to re-run: accounts are reused and seed documents are overwritten.
// Safety cases are not seeded; the app opens them from the missed check-ins.
const assert = require('node:assert/strict');

// Must match lib/firebase_options.dart so the app reads the same namespace.
const project = 'carelink-hci';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9299';
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8188';
for (const host of [authHost, firestoreHost]) {
  assert.match(host, /^(127\.0\.0\.1|localhost):\d+$/, 'Only local emulators may be seeded.');
}

const documentRoot = `projects/${project}/databases/(default)/documents`;
const firestoreUrl = `http://${firestoreHost}/v1/${documentRoot}`;
const authUrl = `http://${authHost}/identitytoolkit.googleapis.com/v1`;
const password = 'CareLink-test-123!';

async function post(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    // "owner" is the emulator's admin token; it bypasses security rules.
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify(body),
  });
  return { ok: response.ok, body: await response.json() };
}

function value(input) {
  if (input === null) return { nullValue: null };
  if (input instanceof Date) return { timestampValue: input.toISOString() };
  if (typeof input === 'boolean') return { booleanValue: input };
  if (typeof input === 'number') return { integerValue: String(input) };
  if (typeof input === 'string') return { stringValue: input };
  return { mapValue: { fields: Object.fromEntries(Object.entries(input).map(([k, v]) => [k, value(v)])) } };
}

const write = (path, data) => ({
  update: { name: `${documentRoot}/${path}`, fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])) },
});

async function account(email, fullName, role, claims) {
  let result = await post(`${authUrl}/accounts:signUp?key=emulator-only`, { email, password, returnSecureToken: true });
  if (!result.ok && result.body.error?.message === 'EMAIL_EXISTS') {
    result = await post(`${authUrl}/accounts:signInWithPassword?key=emulator-only`, { email, password, returnSecureToken: true });
  }
  assert.ok(result.ok, `${email}: ${JSON.stringify(result.body)}`);
  const uid = result.body.localId;
  if (claims) {
    const update = await post(`${authUrl}/projects/${project}/accounts:update`, {
      localId: uid, customAttributes: JSON.stringify(claims),
    });
    assert.ok(update.ok, JSON.stringify(update.body));
  }
  const now = new Date();
  return {
    uid,
    email,
    fullName,
    userDoc: write(`users/${uid}`, {
      fullName, email, role, profileCompleted: true, setupStage: 'complete',
      verificationStatus: 'notRequired', emailVerified: true, createdAt: now, updatedAt: now,
    }),
  };
}

const hoursFromNow = hours => new Date(Date.now() + hours * 60 * 60 * 1000);

function checkIn(id, elder, companion, scheduledAt, status) {
  return write(`check_ins/${id}`, {
    connectionId: `seed_connection_${elder.uid}`, matchRequestId: `seed_match_${elder.uid}`,
    elderId: elder.uid, elderName: elder.fullName, companionId: companion.uid, companionName: companion.fullName,
    scheduledAt, durationMinutes: 30, mode: 'Video', status, createdAt: hoursFromNow(-72), updatedAt: hoursFromNow(-1),
  });
}

async function main() {
  const coordinator = await account('coordinator@carelink.test', 'Test Coordinator', 'Coordinator', { coordinator: true });
  const silva = await account('silva@carelink.test', 'Mrs. Silva', 'Older Adult');
  const perera = await account('perera@carelink.test', 'Mr. Perera', 'Older Adult');
  const fernando = await account('fernando@carelink.test', 'Ms. Fernando', 'Older Adult');
  const jane = await account('jane@carelink.test', 'Jane Silva', 'Family Caregiver');
  const student = await account('student@carelink.test', 'Kasun Student', 'Student Companion');

  const now = new Date();
  const result = await post(`${firestoreUrl}:commit`, {
    writes: [
      ...[coordinator, silva, perera, fernando, jane, student].map(user => user.userDoc),
      // Silva: family sharing approved with Jane as the approved contact.
      write(`consents/${silva.uid}`, { userId: silva.uid, privacyAccepted: true, familyLinkConsent: true, communicationConsent: true, updatedAt: now }),
      write(`family_links/${silva.uid}_${jane.uid}`, {
        elderId: silva.uid, caregiverId: jane.uid, requestId: 'seed_request_silva', elderDisplayName: silva.fullName,
        caregiverName: jane.fullName, relationship: 'Daughter', createdAt: hoursFromNow(-24 * 30),
      }),
      // Perera: family sharing declined. Fernando: no consent record at all.
      write(`consents/${perera.uid}`, { userId: perera.uid, privacyAccepted: true, familyLinkConsent: false, communicationConsent: true, updatedAt: now }),
      // Missed: two marked missed, one still "scheduled" after its slot ended.
      checkIn('seed_checkin_silva_missed', silva, student, hoursFromNow(-3), 'missed'),
      checkIn('seed_checkin_perera_missed', perera, student, hoursFromNow(-26), 'missed'),
      checkIn('seed_checkin_fernando_overdue', fernando, student, hoursFromNow(-2), 'scheduled'),
      // Not missed, so no case should open for these.
      checkIn('seed_checkin_silva_completed', silva, student, hoursFromNow(-48), 'completed'),
      checkIn('seed_checkin_perera_upcoming', perera, student, hoursFromNow(24), 'scheduled'),
    ],
  });
  assert.ok(result.ok, JSON.stringify(result.body));

  console.log('Seeded the local emulators (project carelink-hci).');
  console.log(`Coordinator: coordinator@carelink.test / ${password}`);
  console.log('Expect 3 safety cases: Mrs. Silva, Mr. Perera and Ms. Fernando.');
}

main().catch(error => {
  console.error(error.message || error);
  console.error('Are the emulators running? See the instructions at the top of this file.');
  process.exit(1);
});
