const assert = require('node:assert/strict');
const { test } = require('node:test');

const project = 'demo-carelink-hci';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const storageHost = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
assert.ok(authHost && firestoreHost && storageHost, 'Run this test with Firebase emulators:exec.');
for (const host of [authHost, firestoreHost, storageHost]) {
  assert.match(host, /^(127\.0\.0\.1|localhost):\d+$/, 'Only local emulators may be tested.');
}

const documentRoot = `projects/${project}/databases/(default)/documents`;
const firestoreUrl = `http://${firestoreHost}/v1/${documentRoot}`;

async function request(url, options = {}) {
  const response = await fetch(url, options);
  const text = await response.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  return { ok: response.ok, status: response.status, body };
}

async function auth(action, body) {
  const result = await request(
    `http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:${action}?key=emulator-only`,
    { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) },
  );
  assert.equal(result.ok, true, `Auth ${action} failed: ${result.body.error?.message}`);
  return result.body;
}

function value(input) {
  if (input === null) return { nullValue: null };
  if (typeof input === 'boolean') return { booleanValue: input };
  if (typeof input === 'string') return { stringValue: input };
  return { mapValue: { fields: Object.fromEntries(Object.entries(input).map(([k, v]) => [k, value(v)])) } };
}

function write(path, data, timestamps = ['updatedAt']) {
  return {
    update: { name: `${documentRoot}/${path}`, fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, value(v)])) },
    updateMask: { fieldPaths: Object.keys(data) },
    updateTransforms: timestamps.map(fieldPath => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })),
  };
}

function commit(token, writes) {
  return request(`${firestoreUrl}:commit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({ writes }),
  });
}

function read(token, path) {
  return request(`${firestoreUrl}/${path}`, { headers: { Authorization: `Bearer ${token}` } });
}

async function allowed(result, label) {
  const response = await result;
  assert.equal(response.ok, true, `${label}: ${JSON.stringify(response.body)}`);
  return response.body;
}

async function denied(result, label) {
  const response = await result;
  assert.ok([401, 403].includes(response.status), `${label}: expected denial, got ${response.status}`);
}

async function account(email) {
  const user = await auth('signUp', { email, password: 'CareLink-test-123!', returnSecureToken: true });
  await allowed(commit(user.idToken, [write(`users/${user.localId}`, {
    fullName: 'Test User', email, role: null, phone: '', location: '', language: 'English',
    accessibilitySettings: { largerText: false, highContrast: false, reduceMotion: false },
    emailVerified: false, setupStage: 'emailVerification', profileCompleted: false, verificationStatus: 'notSubmitted',
  }, ['createdAt', 'updatedAt'])]), 'registration document');
  return { uid: user.localId, token: user.idToken, email };
}

async function completeGeneralSetup(user, role) {
  const path = `users/${user.uid}`;
  await allowed(commit(user.token, [write(path, { role, setupStage: 'profile' })]), 'role persistence');
  await allowed(commit(user.token, [write(path, {
    fullName: 'Saved Name', phone: '0771234567', location: 'Colombo', setupStage: 'preferences',
  })]), 'profile persistence');
  await allowed(commit(user.token, [write(path, {
    language: 'English', accessibilitySettings: { largerText: true, highContrast: true, reduceMotion: true }, setupStage: 'consent',
  })]), 'accessibility persistence');
  const student = role === 'Student Companion';
  await allowed(commit(user.token, [
    write(`consents/${user.uid}`, { userId: user.uid, privacyAccepted: true, familyLinkConsent: false, communicationConsent: true }),
    write(path, { profileCompleted: !student, setupStage: student ? 'studentVerification' : 'complete', verificationStatus: student ? 'notSubmitted' : 'notRequired' }),
  ]), 'atomic consent and setup state');
}

function upload(user, name, bytes = Buffer.from('%PDF-1.4\nCareLink test document'), contentType = 'application/pdf', token = user.token) {
  return request(`http://${storageHost}/v0/b/${project}.appspot.com/o?uploadType=media&name=${encodeURIComponent(`student_verifications/${user.uid}/${name}`)}`, {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': contentType }, body: bytes,
  });
}

test('Firebase authentication, account setup, student upload and security contracts', async t => {
  const older = await account('older@example.test');
  const student = await account('student@example.test');
  const family = await account('family@example.test');

  await t.test('email verification and password reset actions work', async () => {
    await auth('sendOobCode', { requestType: 'VERIFY_EMAIL', idToken: older.token });
    let codes = (await request(`http://${authHost}/emulator/v1/projects/${project}/oobCodes`)).body.oobCodes;
    const verification = codes.find(code => code.email === older.email && code.requestType === 'VERIFY_EMAIL');
    assert.ok(verification);
    await auth('update', { oobCode: verification.oobCode });
    const signedIn = await auth('signInWithPassword', { email: older.email, password: 'CareLink-test-123!', returnSecureToken: true });
    older.token = signedIn.idToken;
    await auth('sendOobCode', { requestType: 'PASSWORD_RESET', email: older.email });
    codes = (await request(`http://${authHost}/emulator/v1/projects/${project}/oobCodes`)).body.oobCodes;
    const reset = codes.find(code => code.email === older.email && code.requestType === 'PASSWORD_RESET');
    assert.ok(reset);
    await auth('resetPassword', { oobCode: reset.oobCode, newPassword: 'CareLink-reset-456!' });
    const login = await auth('signInWithPassword', { email: older.email, password: 'CareLink-reset-456!', returnSecureToken: true });
    older.token = login.idToken;
    const details = await auth('lookup', { idToken: older.token });
    assert.equal(details.users[0].emailVerified, true);
  });

  await t.test('other users and unauthenticated clients cannot access user data', async () => {
    await denied(read(student.token, `users/${older.uid}`), 'foreign read');
    await denied(commit(student.token, [write(`users/${older.uid}`, { fullName: 'Other user' })]), 'foreign write');
    await denied(request(`${firestoreUrl}/users/${older.uid}`), 'unauthenticated read');
  });

  await t.test('Older Adult and Family Caregiver setup completes without verification', async () => {
    await completeGeneralSetup(older, 'Older Adult');
    await completeGeneralSetup(family, 'Family Caregiver');
    for (const user of [older, family]) {
      const data = await allowed(read(user.token, `users/${user.uid}`), 'owner read');
      assert.equal(data.fields.profileCompleted.booleanValue, true);
      assert.equal(data.fields.verificationStatus.stringValue, 'notRequired');
      assert.ok(data.fields.createdAt.timestampValue);
      assert.ok(data.fields.updatedAt.timestampValue);
    }
  });

  await t.test('student remains incomplete after general consent', async () => {
    await completeGeneralSetup(student, 'Student Companion');
    const data = await allowed(read(student.token, `users/${student.uid}`), 'student read');
    assert.equal(data.fields.profileCompleted.booleanValue, false);
    await denied(commit(student.token, [write(`users/${student.uid}`, { profileCompleted: true, verificationStatus: 'pending' })]), 'completion without verification');
  });

  await t.test('only an owner with Student Companion role can upload', async () => {
    await denied(upload(older, 'not-student.pdf'), 'non-student upload');
    await denied(upload(student, 'other-user.pdf', undefined, undefined, older.token), 'foreign upload');
    await allowed(upload(student, 'proof.pdf'), 'student upload');
  });

  await t.test('document type and 10 MB boundary are enforced', async () => {
    await denied(upload(student, 'text.txt', Buffer.from('text'), 'text/plain'), 'wrong content type');
    await denied(upload(student, 'empty.pdf', Buffer.alloc(0)), 'empty document');
    await denied(upload(student, 'too-big.pdf', Buffer.alloc(10 * 1024 * 1024 + 1)), 'oversize document');
    await allowed(upload(student, 'limit.pdf', Buffer.alloc(10 * 1024 * 1024)), 'exact 10 MB document');
  });

  await t.test('verification and user pending state commit atomically', async () => {
    const path = `student_verifications/${student.uid}/proof.pdf`;
    await allowed(commit(student.token, [
      write(`student_verifications/${student.uid}`, {
        userId: student.uid, role: 'Student Companion', university: 'Test University', studentId: 'ST123',
        universityEmail: student.email, documentName: 'proof.pdf', documentPath: path,
        documentUrl: `http://${storageHost}/v0/b/${project}.appspot.com/o/${encodeURIComponent(path)}?alt=media`, status: 'pending',
        reviewedAt: null, reviewedBy: null, rejectionReason: null,
      }, ['submittedAt', 'updatedAt']),
      write(`users/${student.uid}`, { verificationStatus: 'pending', profileCompleted: true, setupStage: 'complete' }),
    ]), 'pending submission batch');
    const submission = await allowed(read(student.token, `student_verifications/${student.uid}`), 'submission read');
    assert.equal(submission.fields.status.stringValue, 'pending');
  });

  await t.test('clients cannot approve themselves or change a completed role', async () => {
    await denied(commit(student.token, [write(`users/${student.uid}`, { verificationStatus: 'approved' })]), 'user self approval');
    await denied(commit(student.token, [write(`users/${student.uid}`, { verificationStatus: 'verified' })]), 'user self verification');
    await denied(commit(student.token, [write(`student_verifications/${student.uid}`, { status: 'approved' })]), 'submission self approval');
    await denied(commit(student.token, [write(`users/${student.uid}`, { role: 'Older Adult', verificationStatus: 'notRequired' })]), 'completed role change');
    await denied(commit(student.token, [write(`users/${student.uid}`, { createdAt: 'changed' })]), 'createdAt change');
  });

  await t.test('legacy records without verificationStatus remain writable', async () => {
    const legacy = await auth('signUp', { email: 'legacy@example.test', password: 'Legacy-test-123!', returnSecureToken: true });
    await allowed(commit(legacy.idToken, [write(`users/${legacy.localId}`, { role: 'Older Adult', profileCompleted: false }, ['createdAt', 'updatedAt'])]), 'legacy record');
    await allowed(commit(legacy.idToken, [write(`users/${legacy.localId}`, { phone: '0771234567' })]), 'legacy profile update');
  });
});
