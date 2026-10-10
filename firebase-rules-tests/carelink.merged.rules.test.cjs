'use strict';

// CareLink: LOCAL Firebase Firestore + Storage security-rules tests.
// Put this file in CareLink-App/firebase-rules-tests/.
// Run from that folder using: node --test carelink.rules.test.cjs
// Requires the Firestore emulator on 127.0.0.1:8080 and Storage on :9199.

const { before, beforeEach, after, test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  collection,
  query,
  where,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');
const { ref, uploadBytes, getMetadata } = require('firebase/storage');

const PROJECT_ID = 'carelink-hci';
const ROOT = path.resolve(__dirname, '..');
let env;

function dbFor(uid) {
  return env.authenticatedContext(uid).firestore();
}
function storageFor(uid) {
  return env.authenticatedContext(uid).storage('carelink-test.appspot.com');
}
function checkInData() {
  return {
    connectionId: 'conn1',
    matchRequestId: 'req1',
    elderId: 'elderA',
    elderName: 'Kamala',
    companionId: 'studentA',
    companionName: 'Nethmi',
    scheduledAt: Timestamp.fromMillis(Date.now() + 86_400_000),
    durationMinutes: 30,
    mode: 'Video',
    status: 'scheduled',
    reflection: null,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}
function scheduleData() {
  return {
    connectionId: 'conn1',
    matchRequestId: 'req1',
    elderId: 'elderA',
    elderName: 'Kamala',
    companionId: 'studentA',
    companionName: 'Nethmi',
    weekdays: [1, 3],
    hour: 18,
    minute: 30,
    durationMinutes: 30,
    isActive: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}
function memoryData(visibility) {
  return {
    connectionId: 'conn1',
    matchRequestId: 'req1',
    elderId: 'elderA',
    companionId: 'studentA',
    ownerId: 'studentA',
    type: 'photo',
    title: 'A happy memory',
    caption: 'CareLink check-in',
    mediaPath: null,
    memoryDate: Timestamp.now(),
    createdAt: Timestamp.now(),
    visibility,
    updatedAt: serverTimestamp(),
  };
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(path.join(__dirname, 'CareLink_Merged_Review.rules'), 'utf8'),
    },
    storage: {
      host: '127.0.0.1',
      port: 9199,
      rules: fs.readFileSync(path.join(ROOT, 'storage.rules'), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  // Seed users and an ACCEPTED, ACTIVE pair with rules disabled.
  // Tests below run with rules ENABLED; this is not a test of connection creation.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', 'elderA'), {
      role: 'Older Adult', fullName: 'Kamala', verificationStatus: 'notRequired',
    });
    await setDoc(doc(db, 'users', 'studentA'), {
      role: 'Student Companion', fullName: 'Nethmi', verificationStatus: 'verified',
    });
    await setDoc(doc(db, 'users', 'studentB'), {
      role: 'Student Companion', fullName: 'Other Student', verificationStatus: 'verified',
    });
    await setDoc(doc(db, 'match_requests', 'req1'), {
      elderId: 'elderA', companionId: 'studentA', status: 'accepted',
      elderDisplayName: 'Kamala',
    });
    await setDoc(doc(db, 'connections', 'conn1'), {
      elderId: 'elderA', companionId: 'studentA', matchRequestId: 'req1', status: 'active',
    });
  });
});

after(async () => {
  if (env) await env.cleanup();
});

test('Matching: participants can read their connection; outsider cannot', async () => {
  await assertSucceeds(getDoc(doc(dbFor('elderA'), 'connections', 'conn1')));
  await assertSucceeds(getDoc(doc(dbFor('studentA'), 'connections', 'conn1')));
  await assertFails(getDoc(doc(dbFor('studentB'), 'connections', 'conn1')));
});

test('Student companion can create and read a paired check-in', async () => {
  const db = dbFor('studentA');
  await assertSucceeds(setDoc(doc(db, 'check_ins', 'check1'), checkInData()));
  await assertSucceeds(getDoc(doc(db, 'check_ins', 'check1')));
  await assertSucceeds(getDoc(doc(dbFor('elderA'), 'check_ins', 'check1')));
  await assertFails(getDoc(doc(dbFor('studentB'), 'check_ins', 'check1')));
});

test('Another student cannot spoof a connection for a check-in', async () => {
  const data = { ...checkInData(), companionId: 'studentB' };
  await assertFails(setDoc(doc(dbFor('studentB'), 'check_ins', 'fake'), data));
});

test('Student companion can create and read a recurring schedule', async () => {
  const db = dbFor('studentA');
  await assertSucceeds(setDoc(doc(db, 'recurring_schedules', 'schedule1'), scheduleData()));
  await assertSucceeds(getDoc(doc(db, 'recurring_schedules', 'schedule1')));
  await assertFails(getDoc(doc(dbFor('studentB'), 'recurring_schedules', 'schedule1')));
});

test('Paused connections cannot create new paired check-ins', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'connections', 'conn1'), { status: 'paused' });
  });
  await assertFails(setDoc(doc(dbFor('studentA'), 'check_ins', 'newPaused'), checkInData()));
});

test('Only me memory is private to its creator', async () => {
  const ownerDb = dbFor('studentA');
  await assertSucceeds(setDoc(doc(ownerDb, 'memories', 'private1'), memoryData('Only me')));
  await assertSucceeds(getDoc(doc(ownerDb, 'memories', 'private1')));
  await assertFails(getDoc(doc(dbFor('elderA'), 'memories', 'private1')));
  await assertFails(getDoc(doc(dbFor('studentB'), 'memories', 'private1')));
  const result = await assertSucceeds(getDocs(query(
    collection(ownerDb, 'memories'), where('ownerId', '==', 'studentA'),
  )));
  if (result.size !== 1) throw Error(`Expected 1 owner memory, got ${result.size}`);
});

test('Companion-shared memory is visible to its paired elder', async () => {
  await assertSucceeds(setDoc(
    doc(dbFor('studentA'), 'memories', 'shared1'), memoryData('Companion'),
  ));
  await assertSucceeds(getDoc(doc(dbFor('elderA'), 'memories', 'shared1')));
  await assertFails(getDoc(doc(dbFor('studentB'), 'memories', 'shared1')));
  const result = await assertSucceeds(getDocs(query(
    collection(dbFor('elderA'), 'memories'),
    where('elderId', '==', 'elderA'),
    where('visibility', '==', 'Companion'),
  )));
  if (result.size !== 1) throw Error(`Expected 1 shared memory, got ${result.size}`);
});

test('Storage: owner can upload and read their photo; other student cannot', async () => {
  const filename = 'memories/studentA/test.png';
  // A real tiny PNG, so file-upload behavior stays realistic.
  const png = new Uint8Array(Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/3WQAAAAASUVORK5CYII=',
    'base64',
  ));
  await assertSucceeds(uploadBytes(ref(storageFor('studentA'), filename), png, {
    contentType: 'image/png',
  }));
  await assertSucceeds(getMetadata(ref(storageFor('studentA'), filename)));
  await assertFails(getMetadata(ref(storageFor('studentB'), filename)));
  await assertFails(uploadBytes(
    ref(storageFor('studentB'), 'memories/studentA/stolen.png'), png,
    { contentType: 'image/png' },
  ));
});

test('Storage: owner cannot upload a non-image type', async () => {
  await assertFails(uploadBytes(
    ref(storageFor('studentA'), 'memories/studentA/not-image.txt'),
    new Uint8Array([65, 66, 67]),
    { contentType: 'text/plain' },
  ));
});
