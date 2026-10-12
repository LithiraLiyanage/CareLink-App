// Firestore rules contract for the Coordinator safety-case workflow.
//
// Run against local emulators only:
//   firebase emulators:exec --config firebase.emulators.json --project demo-carelink-hci --only auth,firestore,storage "node --test test/coordinator_safety_case_rules_test.cjs"
const assert = require('node:assert/strict');
const { test } = require('node:test');

const project = 'demo-carelink-hci';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(authHost && firestoreHost, 'Run this test with Firebase emulators:exec.');
for (const host of [authHost, firestoreHost]) {
  assert.match(host, /^(127\.0\.0\.1|localhost):\d+$/, 'Only local emulators may be tested.');
}

const documentRoot = `projects/${project}/databases/(default)/documents`;
const firestoreUrl = `http://${firestoreHost}/v1/${documentRoot}`;
const authUrl = `http://${authHost}/identitytoolkit.googleapis.com/v1`;
// The emulator treats "owner" as an admin that bypasses rules; used to seed.
const owner = 'owner';

async function request(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  return { ok: response.ok, status: response.status, body };
}

const json = (token, body) => ({
  method: 'POST',
  headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  body: JSON.stringify(body),
});

function value(input) {
  if (input === null) return { nullValue: null };
  if (input instanceof Date) return { timestampValue: input.toISOString() };
  if (typeof input === 'boolean') return { booleanValue: input };
  if (typeof input === 'number') return { integerValue: String(input) };
  if (typeof input === 'string') return { stringValue: input };
  return { mapValue: { fields: Object.fromEntries(Object.entries(input).map(([k, v]) => [k, value(v)])) } };
}

// `serverTimes` lists field paths set to the request time, like
// FieldValue.serverTimestamp() in the app.
function write(path, data, serverTimes = [], { create = false, merge = false } = {}) {
  return {
    update: { name: `${documentRoot}/${path}`, fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])) },
    ...(merge ? { updateMask: { fieldPaths: Object.keys(data) } } : {}),
    ...(create ? { currentDocument: { exists: false } } : {}),
    updateTransforms: serverTimes.map(fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })),
  };
}

const commit = (token, writes) => request(`${firestoreUrl}:commit`, json(token, { writes }));
const read = (token, path) => request(`${firestoreUrl}/${path}`, { headers: { Authorization: `Bearer ${token}` } });
const remove = (token, path) => request(`${firestoreUrl}/${path}`, { method: 'DELETE', headers: { Authorization: `Bearer ${token}` } });

async function allowed(result, label) {
  const response = await result;
  assert.equal(response.ok, true, `${label}: ${JSON.stringify(response.body)}`);
  return response.body;
}

async function denied(result, label) {
  const response = await result;
  assert.ok([401, 403].includes(response.status), `${label}: expected denial, got ${response.status}`);
}

async function account(email, role, claims, { userDoc = true } = {}) {
  const signUp = await request(`${authUrl}/accounts:signUp?key=emulator-only`, json(owner, {
    email, password: 'CareLink-test-123!', returnSecureToken: true,
  }));
  assert.equal(signUp.ok, true, JSON.stringify(signUp.body));
  const uid = signUp.body.localId;
  if (claims) {
    await allowed(request(`${authUrl}/projects/${project}/accounts:update`, json(owner, {
      localId: uid, customAttributes: JSON.stringify(claims),
    })), 'set custom claims');
  }
  if (userDoc) {
    await allowed(commit(owner, [write(`users/${uid}`, { fullName: email, role, profileCompleted: true })]), 'seed user');
  }
  // Sign in again so the ID token carries the claims.
  const signIn = await request(`${authUrl}/accounts:signInWithPassword?key=emulator-only`, json(owner, {
    email, password: 'CareLink-test-123!', returnSecureToken: true,
  }));
  return { uid, token: signIn.body.idToken };
}

const scheduledAt = new Date(Date.now() - 2 * 60 * 60 * 1000);

function newCase(coordinator, checkInId, elder, caseNumber, { counterExists = false } = {}) {
  return [
    write('counters/safety_cases', { next: caseNumber }, [], { create: !counterExists }),
    write(`safety_cases/${checkInId}`, {
      checkInId, elderId: elder.uid, elderName: 'Mrs. Silva', caseNumber,
      status: 'pendingReview', scheduledAt, previousAttempts: 0, updatedBy: coordinator.uid,
    }, ['openedAt', 'updatedAt'], { create: true }),
    auditEvent(coordinator, checkInId, 'checkInMissed', 'system', 'Safety case opened'),
  ];
}

function auditEvent(user, caseId, type, actor, result, note = '') {
  const eventId = `${type}-${Math.random().toString(36).slice(2)}`;
  return write(`safety_cases/${caseId}/audit_events/${eventId}`, {
    type, actor, actorUid: user.uid, result, note,
  }, ['occurredAt'], { create: true });
}

test('Coordinator safety cases: access, case lifecycle and append-only audit', async t => {
  const id = Date.now();
  const coordinator = await account(`coordinator-${id}@carelink.test`, 'Coordinator', { coordinator: true });
  const caregiver = await account(`caregiver-${id}@carelink.test`, 'Family Caregiver');
  const elder = await account(`elder-${id}@carelink.test`, 'Older Adult');
  const studentWithClaim = await account(`student-${id}@carelink.test`, 'Student Companion', { coordinator: true });
  // Created in the Firebase console + set_coordinator_claim.cjs: no users doc.
  const consoleCoordinator = await account(`staff-${id}@carelink.test`, null, { coordinator: true }, { userDoc: false });

  const checkInId = `checkin-${id}`;
  const upcomingId = `upcoming-${id}`;
  await allowed(commit(owner, [
    write(`check_ins/${checkInId}`, { elderId: elder.uid, elderName: 'Mrs. Silva', status: 'missed', scheduledAt, durationMinutes: 30 }),
    write(`check_ins/${upcomingId}`, { elderId: elder.uid, elderName: 'Mrs. Silva', status: 'scheduled', scheduledAt: new Date(Date.now() + 86400000), durationMinutes: 30 }),
    write(`consents/${elder.uid}`, { userId: elder.uid, privacyAccepted: true, familyLinkConsent: true, communicationConsent: true }, ['updatedAt']),
    write(`family_links/${elder.uid}_${caregiver.uid}`, { elderId: elder.uid, caregiverId: caregiver.uid, caregiverName: 'Jane Silva', relationship: 'Daughter' }, ['createdAt']),
  ]), 'seed check-ins and consent');

  await t.test('only Coordinators/Admins read case inputs', async () => {
    await allowed(read(coordinator.token, `check_ins/${checkInId}`), 'coordinator reads check-in');
    await allowed(read(coordinator.token, `consents/${elder.uid}`), 'coordinator reads consent');
    await allowed(read(coordinator.token, `family_links/${elder.uid}_${caregiver.uid}`), 'coordinator reads family link');
    await denied(read(caregiver.token, `consents/${elder.uid}`), 'caregiver reads elder consent');
    await denied(read(studentWithClaim.token, `check_ins/${checkInId}`), 'student with coordinator claim');
  });

  await t.test('a coordinator without a users document still has access', async () => {
    await allowed(read(consoleCoordinator.token, `check_ins/${checkInId}`), 'console coordinator reads check-in');
    await allowed(read(consoleCoordinator.token, `consents/${elder.uid}`), 'console coordinator reads consent');
    await allowed(read(consoleCoordinator.token, 'safety_cases'), 'console coordinator lists cases');
  });

  await t.test('cases are opened only for missed check-ins with the next number', async () => {
    await denied(commit(caregiver.token, newCase(caregiver, checkInId, elder, 1)), 'non-coordinator opens case');
    await denied(commit(coordinator.token, newCase(coordinator, upcomingId, elder, 1)), 'case for upcoming check-in');
    await denied(commit(coordinator.token, newCase(coordinator, checkInId, elder, 5)), 'skipped case number');
    await allowed(commit(coordinator.token, newCase(coordinator, checkInId, elder, 1)), 'coordinator opens case');
    await denied(commit(coordinator.token, newCase(coordinator, checkInId, elder, 2, { counterExists: true })), 'second case for one check-in');
    await denied(read(caregiver.token, `safety_cases/${checkInId}`), 'caregiver reads case');
    await allowed(read(coordinator.token, `safety_cases/${checkInId}`), 'coordinator reads case');
  });

  await t.test('actions update the case together with an audit event', async () => {
    await allowed(commit(coordinator.token, [
      write(`safety_cases/${checkInId}`, { status: 'retryRequested', previousAttempts: 1, updatedBy: coordinator.uid }, ['updatedAt'], { merge: true }),
      auditEvent(coordinator, checkInId, 'retryRequested', 'coordinator', 'Status set to Retry Requested'),
    ]), 'record retry');
    await denied(commit(coordinator.token, [
      write(`safety_cases/${checkInId}`, { previousAttempts: 5, updatedBy: coordinator.uid }, ['updatedAt'], { merge: true }),
    ]), 'jump attempts');
    await denied(commit(coordinator.token, [
      write(`safety_cases/${checkInId}`, { elderId: caregiver.uid, updatedBy: coordinator.uid }, ['updatedAt'], { merge: true }),
    ]), 'change elder');
    await denied(commit(coordinator.token, [
      auditEvent(coordinator, checkInId, 'checkInMissed', 'system', 'Forged system entry'),
    ]), 'system entry after opening');
  });

  await t.test('audit events are append-only', async () => {
    const list = await allowed(read(coordinator.token, `safety_cases/${checkInId}/audit_events`), 'list audit');
    const name = list.documents[0].name.split('/documents/')[1];
    await denied(commit(coordinator.token, [write(name, { note: 'edited' }, [], { merge: true })]), 'edit audit event');
    await denied(remove(coordinator.token, name), 'delete audit event');
  });

  await t.test('closing requires a consistent outcome and is final', async () => {
    const close = (outcome) => commit(coordinator.token, [
      write(`safety_cases/${checkInId}`, {
        status: 'closed', updatedBy: coordinator.uid, outcome,
      }, ['updatedAt', 'closedAt', 'outcome.recordedAt'], { merge: true }),
      auditEvent(coordinator, checkInId, 'caseClosed', 'coordinator', 'Closed'),
    ]);
    await denied(close({ actionTaken: 'retriedCheckIn', result: 'elderNotReached', closureReason: 'safetyConfirmed', notes: 'No answer' }), 'safety confirmed when unresolved');
    await denied(close({ actionTaken: 'retriedCheckIn', result: 'elderNotReached', closureReason: 'noFurtherActionAvailable', notes: '' }), 'unresolved without notes');
    await allowed(close({ actionTaken: 'retriedCheckIn', result: 'elderContactedSuccessfully', closureReason: 'safetyConfirmed', notes: '' }), 'valid close');
    await denied(commit(coordinator.token, [
      write(`safety_cases/${checkInId}`, { status: 'pendingReview', updatedBy: coordinator.uid }, ['updatedAt'], { merge: true }),
    ]), 'reopen closed case');
    await denied(remove(coordinator.token, `safety_cases/${checkInId}`), 'delete case');
  });
});
