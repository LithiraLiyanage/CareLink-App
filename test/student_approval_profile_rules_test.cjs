// Firestore rules contract: a Coordinator's student approval publishes the
// student's companion profile, so the student is recommended to elders.
//
// Run against local emulators only:
//   firebase emulators:exec --config firebase.emulators.json --project demo-carelink-hci --only auth,firestore "node --test test/student_approval_profile_rules_test.cjs"
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
  if (Array.isArray(input)) return { arrayValue: { values: input.map(value) } };
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
const recommendable = token => request(`${firestoreUrl}:runQuery`, json(token, {
  structuredQuery: {
    from: [{ collectionId: 'companion_profiles' }],
    where: { compositeFilter: { op: 'AND', filters: [
      { fieldFilter: { field: { fieldPath: 'active' }, op: 'EQUAL', value: { booleanValue: true } } },
      { fieldFilter: { field: { fieldPath: 'verificationStatus' }, op: 'EQUAL', value: { stringValue: 'verified' } } },
    ] } },
  },
}));

async function allowed(result, label) {
  const response = await result;
  assert.equal(response.ok, true, `${label}: ${JSON.stringify(response.body)}`);
  return response.body;
}

async function denied(result, label) {
  const response = await result;
  assert.ok([401, 403].includes(response.status), `${label}: expected denial, got ${response.status}`);
}

async function account(email, user, claims) {
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
  await allowed(commit(owner, [write(`users/${uid}`, { fullName: email, profileCompleted: true, ...user })]), 'seed user');
  // Sign in again so the ID token carries the claims.
  const signIn = await request(`${authUrl}/accounts:signInWithPassword?key=emulator-only`, json(owner, {
    email, password: 'CareLink-test-123!', returnSecureToken: true,
  }));
  return { uid, token: signIn.body.idToken };
}

async function pendingStudent(email, fullName) {
  const student = await account(email, {
    fullName, role: 'Student Companion', verificationStatus: 'pending', language: 'Sinhala',
  });
  await allowed(commit(owner, [write(`student_verifications/${student.uid}`, {
    userId: student.uid, university: 'SLIIT', studentId: 'IT123', universityEmail: email,
    status: 'pending', submittedAt: new Date(), reviewedAt: null, reviewedBy: null,
    rejectionReason: null,
  })]), 'seed pending verification');
  return student;
}

// The writes StudentVerificationReviewService.reviewRequest makes.
function review(reviewer, student, status, profile) {
  return [
    write(`student_verifications/${student.uid}`, {
      status, reviewedBy: reviewer.uid, rejectionReason: null,
    }, ['reviewedAt'], { merge: true }),
    write(`users/${student.uid}`, { verificationStatus: status }, ['updatedAt'], { merge: true }),
    ...(profile ? [profile] : []),
  ];
}

const newProfile = (student, fullName, overrides = {}) => write(`companion_profiles/${student.uid}`, {
  userId: student.uid, fullName, languages: ['Sinhala'], interests: [],
  active: true, verificationStatus: 'verified', ...overrides,
}, ['updatedAt'], { create: true });

test('Coordinator approval publishes the companion profile', async t => {
  const id = Date.now();
  const coordinator = await account(`coordinator-${id}@carelink.test`, { role: 'Coordinator' }, { coordinator: true });
  const elder = await account(`elder-${id}@carelink.test`, { role: 'Older Adult' });
  const caregiver = await account(`caregiver-${id}@carelink.test`, { role: 'Family Caregiver' });

  await t.test('approval creates a profile elders can be recommended', async () => {
    const student = await pendingStudent(`student-a-${id}@carelink.test`, 'Nethmi Perera');
    await denied(read(elder.token, `companion_profiles/${student.uid}`), 'no profile before approval');
    // The review transaction reads the (still missing) profile first.
    const missing = await read(coordinator.token, `companion_profiles/${student.uid}`);
    assert.equal(missing.status, 404, `coordinator reads missing profile: ${JSON.stringify(missing.body)}`);

    await allowed(commit(coordinator.token, review(coordinator, student, 'verified',
      newProfile(student, 'Nethmi Perera'))), 'coordinator approves and publishes');

    await allowed(read(elder.token, `companion_profiles/${student.uid}`), 'elder reads approved profile');
    const results = await allowed(recommendable(elder.token), 'elder lists recommendable profiles');
    assert.ok(results.some(row => row.document?.name.endsWith(`/companion_profiles/${student.uid}`)),
      'approved student is in the recommendations query');
  });

  await t.test('a profile cannot be published without approving the student', async () => {
    const student = await pendingStudent(`student-b-${id}@carelink.test`, 'Amaya Silva');
    await denied(commit(coordinator.token, [newProfile(student, 'Amaya Silva')]),
      'coordinator publishes without a review');
    await denied(commit(caregiver.token, review(caregiver, student, 'verified',
      newProfile(student, 'Amaya Silva'))), 'non-coordinator approves');
    await denied(commit(coordinator.token, review(coordinator, student, 'rejected',
      newProfile(student, 'Amaya Silva'))), 'rejected student published as verified');
  });

  await t.test('rejection withdraws an existing profile', async () => {
    const student = await pendingStudent(`student-c-${id}@carelink.test`, 'Kavindu Fernando');
    await allowed(commit(owner, [write(`companion_profiles/${student.uid}`, {
      userId: student.uid, fullName: 'Kavindu Fernando', bio: 'Loves chess', interests: ['Chess'],
      active: false, verificationStatus: 'pending', updatedAt: new Date(),
    })]), 'seed student-written profile');

    await denied(commit(coordinator.token, review(coordinator, student, 'rejected',
      write(`companion_profiles/${student.uid}`, { verificationStatus: 'rejected', active: false, bio: 'changed' },
        ['updatedAt'], { merge: true }))), 'reviewer edits student-written fields');
    await allowed(commit(coordinator.token, review(coordinator, student, 'rejected',
      write(`companion_profiles/${student.uid}`, { verificationStatus: 'rejected', active: false },
        ['updatedAt'], { merge: true }))), 'coordinator rejects and withdraws');
    await denied(read(elder.token, `companion_profiles/${student.uid}`), 'elder reads rejected profile');
  });
});
