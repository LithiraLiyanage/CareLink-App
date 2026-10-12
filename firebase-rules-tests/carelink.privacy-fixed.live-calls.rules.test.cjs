'use strict';

// CareLink real-call Firestore signaling permission tests.
// Runs ONLY against the LOCAL Firestore emulator at 127.0.0.1:8080.
// The rules file is the user's proposed rule set in Downloads, not production.
const { before, beforeEach, after, test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc, collection, query, where, getDoc, getDocs, setDoc,
  updateDoc, deleteDoc, serverTimestamp,
} = require('firebase/firestore');

const RULES = path.join(__dirname, 'CareLink_Merged_Privacy_Fixed.rules');
const PROJECT = 'carelink-hci';
let env;

function db(uid) { return env.authenticatedContext(uid).firestore(); }
function roomPath(id = 'room1') { return `carelink_live_calls/${id}`; }
function roomData(callerId = 'studentA', extra = {}) {
  return {
    connectionId: 'conn1',
    matchRequestId: 'req1',
    checkInId: 'check1',
    elderId: 'elderA',
    companionId: 'studentA',
    callerId,
    calleeId: callerId === 'studentA' ? 'elderA' : 'studentA',
    mode: 'Video',
    status: 'ringing',
    offer: { type: 'offer', sdp: 'sample-offer-for-rules-test' },
    answer: null,
    createdAt: serverTimestamp(),
    answeredAt: null,
    endedAt: null,
    endedBy: null,
    ...extra,
  };
}
function candidate() {
  return {
    candidate: 'candidate:1 1 UDP 2122252543 127.0.0.1 12345 typ host',
    sdpMid: '0', sdpMLineIndex: 0, createdAt: serverTimestamp(),
  };
}
async function seed(fn) {
  return env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}
async function start(caller = 'studentA', id = 'room1') {
  await assertSucceeds(setDoc(doc(db(caller), roomPath(id)), roomData(caller)));
}

before(async () => {
  if (!fs.existsSync(RULES)) {
    throw new Error(`Proposed rules file not found: ${RULES}`);
  }
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: {
      host: '127.0.0.1', port: 8080,
      rules: fs.readFileSync(RULES, 'utf8'),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (admin) => {
    await setDoc(doc(admin, 'users/elderA'), {
      role: 'Older Adult', fullName: 'Kamala',
    });
    await setDoc(doc(admin, 'users/studentA'), {
      role: 'Student Companion', verificationStatus: 'verified', fullName: 'Nethmi',
    });
    await setDoc(doc(admin, 'users/studentB'), {
      role: 'Student Companion', verificationStatus: 'verified', fullName: 'Other Student',
    });
    await setDoc(doc(admin, 'users/outsider'), {
      role: 'Family Caregiver', fullName: 'Outsider',
    });
    await setDoc(doc(admin, 'connections/conn1'), {
      elderId: 'elderA', companionId: 'studentA',
      matchRequestId: 'req1', status: 'active',
    });
    await setDoc(doc(admin, 'check_ins/check1'), {
      connectionId: 'conn1', matchRequestId: 'req1',
      elderId: 'elderA', companionId: 'studentA',
      status: 'ready',
    });
  });
});

after(async () => { if (env) await env.cleanup(); });

test('Student can start a Video call; connected Elder receives and reads it', async () => {
  await start();
  await assertSucceeds(getDoc(doc(db('studentA'), roomPath())));
  await assertSucceeds(getDoc(doc(db('elderA'), roomPath())));
  const invitations = await assertSucceeds(getDocs(query(
    collection(db('elderA'), 'carelink_live_calls'),
    where('calleeId', '==', 'elderA'),
  )));
  assert.equal(invitations.size, 1);
});

test('Connected Elder can also start Voice call to verified Student', async () => {
  await assertSucceeds(setDoc(doc(db('elderA'), roomPath('voice1')),
    roomData('elderA', { mode: 'Voice' })));
  const invitations = await assertSucceeds(getDocs(query(
    collection(db('studentA'), 'carelink_live_calls'),
    where('calleeId', '==', 'studentA'),
  )));
  assert.equal(invitations.size, 1);
});

test('Only the recipient can answer an incoming call', async () => {
  await start();
  await assertFails(updateDoc(doc(db('studentA'), roomPath()), {
    status: 'answered', answer: { type: 'answer', sdp: 'fake-answer' },
    answeredAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(doc(db('elderA'), roomPath()), {
    status: 'answered', answer: { type: 'answer', sdp: 'fake-answer' },
    answeredAt: serverTimestamp(),
  }));
});

test('Caller and callee can write their own ICE candidates; reverse/outsider denied', async () => {
  await start();
  await assertSucceeds(setDoc(doc(db('studentA'), `${roomPath()}/offerCandidates/ice1`), candidate()));
  await assertSucceeds(setDoc(doc(db('elderA'), `${roomPath()}/answerCandidates/ice2`), candidate()));
  await assertFails(setDoc(doc(db('elderA'), `${roomPath()}/offerCandidates/ice3`), candidate()));
  await assertFails(setDoc(doc(db('studentA'), `${roomPath()}/answerCandidates/ice4`), candidate()));
  await assertFails(setDoc(doc(db('outsider'), `${roomPath()}/offerCandidates/ice5`), candidate()));
});

test('Only participants can access room and candidate documents', async () => {
  await start();
  await assertSucceeds(setDoc(doc(db('studentA'), `${roomPath()}/offerCandidates/ice1`), candidate()));
  await assertFails(getDoc(doc(db('studentB'), roomPath())));
  await assertFails(getDocs(query(collection(db('studentB'), 'carelink_live_calls'),
    where('calleeId', '==', 'elderA'))));
  await assertFails(getDoc(doc(db('outsider'), `${roomPath()}/offerCandidates/ice1`)));
  await assertSucceeds(getDoc(doc(db('elderA'), `${roomPath()}/offerCandidates/ice1`)));
});

test('Participant can hang up; unrelated account cannot; room cannot be deleted', async () => {
  await start();
  await assertFails(updateDoc(doc(db('outsider'), roomPath()), {
    status: 'ended', endedAt: serverTimestamp(), endedBy: 'outsider',
  }));
  await assertSucceeds(updateDoc(doc(db('studentA'), roomPath()), {
    status: 'ended', endedAt: serverTimestamp(), endedBy: 'studentA',
  }));
  await assertFails(deleteDoc(doc(db('studentA'), roomPath())));
});

test('Paused connection cannot start a call', async () => {
  await seed(async (admin) => updateDoc(doc(admin, 'connections/conn1'), { status: 'paused' }));
  await assertFails(setDoc(doc(db('studentA'), roomPath()), roomData()));
});

test('Unverified Student cannot start a call', async () => {
  await seed(async (admin) => updateDoc(doc(admin, 'users/studentA'), { verificationStatus: 'pending' }));
  await assertFails(setDoc(doc(db('studentA'), roomPath()), roomData()));
});

test('Unrelated Student cannot create a call pretending to be the companion', async () => {
  await assertFails(setDoc(doc(db('studentB'), roomPath()), roomData('studentA')));
});

test('Wrong check-in or ended check-in cannot start a call', async () => {
  await assertFails(setDoc(doc(db('studentA'), roomPath('wrong')), roomData('studentA', {
    checkInId: 'missing-checkin',
  })));
  await seed(async (admin) => updateDoc(doc(admin, 'check_ins/check1'), { status: 'completed' }));
  await assertFails(setDoc(doc(db('studentA'), roomPath('finished')), roomData()));
});
