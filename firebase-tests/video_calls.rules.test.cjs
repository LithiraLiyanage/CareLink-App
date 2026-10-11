
const { test, before, beforeEach, after } = require('node:test');
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
  getDoc,
  setDoc,
  addDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');

let env;

const PROJECT_ID = 'carelink-hci';
const ELDER_ID = 'test-elder';
const STUDENT_ID = 'test-student';
const STRANGER_ID = 'test-stranger';

const connectionId = 'test-connection';
const checkInId = 'test-checkin';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(
        path.join(__dirname, '../firestore.rules'),
        'utf8'
      ),
    },
  });
});

after(async () => {
  if (env) {
    await env.cleanup();
  }
});

beforeEach(async () => {
  await env.clearFirestore();

  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    await setDoc(doc(db, 'users', ELDER_ID), {
      role: 'Older Adult',
      fullName: 'Kamala',
    });

    await setDoc(doc(db, 'users', STUDENT_ID), {
      role: 'Student Companion',
      fullName: 'Amaya',
      verificationStatus: 'verified',
    });

    await setDoc(doc(db, 'users', STRANGER_ID), {
      role: 'Older Adult',
      fullName: 'Other User',
    });

    await setDoc(doc(db, 'connections', connectionId), {
      elderId: ELDER_ID,
      companionId: STUDENT_ID,
      status: 'active',
    });

    await setDoc(doc(db, 'check_ins', checkInId), {
      elderId: ELDER_ID,
      companionId: STUDENT_ID,
      status: 'ready',
      mode: 'Video',
      scheduledAt: Timestamp.fromMillis(
        Date.now() - 2 * 60 * 1000
      ),
      durationMinutes: 45,
    });
  });
});

function elderDB() {
  return env.authenticatedContext(ELDER_ID).firestore();
}

function studentDB() {
  return env.authenticatedContext(STUDENT_ID).firestore();
}

function strangerDB() {
  return env.authenticatedContext(STRANGER_ID).firestore();
}

function callData(overrides = {}) {
  return {
    checkInId,
    connectionId,
    elderId: ELDER_ID,
    companionId: STUDENT_ID,
    mode: 'Video',
    status: 'ringing',
    offer: {
      type: 'offer',
      sdp: 'v=0\r\n',
    },
    answer: null,
    createdAt: serverTimestamp(),
    answeredAt: null,
    endedAt: null,
    endedBy: null,
    ...overrides,
  };
}

test('Kamala can create a valid call', async () => {
  await assertSucceeds(
    setDoc(
      doc(elderDB(), 'video_calls', 'call-1'),
      callData()
    )
  );
});

test('Amaya can answer and exchange ICE candidates', async () => {
  const callId = 'call-2';

  await assertSucceeds(
    setDoc(
      doc(elderDB(), 'video_calls', callId),
      callData()
    )
  );

  await assertSucceeds(
    getDoc(doc(studentDB(), 'video_calls', callId))
  );

  await assertSucceeds(
    updateDoc(doc(studentDB(), 'video_calls', callId), {
      status: 'answered',
      answer: {
        type: 'answer',
        sdp: 'v=0\r\n',
      },
      answeredAt: serverTimestamp(),
    })
  );

  await assertSucceeds(
    addDoc(
      collection(
        elderDB(),
        'video_calls',
        callId,
        'callerCandidates'
      ),
      {
        candidate: 'test-caller-candidate',
        sdpMid: '0',
        sdpMLineIndex: 0,
        createdAt: serverTimestamp(),
      }
    )
  );

  await assertSucceeds(
    addDoc(
      collection(
        studentDB(),
        'video_calls',
        callId,
        'calleeCandidates'
      ),
      {
        candidate: 'test-callee-candidate',
        sdpMid: '0',
        sdpMLineIndex: 0,
        createdAt: serverTimestamp(),
      }
    )
  );
});

test('Unauthorized user cannot read or end a call', async () => {
  const callId = 'call-3';

  await assertSucceeds(
    setDoc(
      doc(elderDB(), 'video_calls', callId),
      callData()
    )
  );

  await assertFails(
    getDoc(doc(strangerDB(), 'video_calls', callId))
  );

  await assertFails(
    updateDoc(doc(strangerDB(), 'video_calls', callId), {
      status: 'ended',
      endedAt: serverTimestamp(),
      endedBy: STRANGER_ID,
    })
  );
});

test('Student cannot create an elder-owned call', async () => {
  await assertFails(
    setDoc(
      doc(studentDB(), 'video_calls', 'call-4'),
      callData()
    )
  );
});

test('Call before scheduled time is denied', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'check_ins', 'future-checkin'),
      {
        elderId: ELDER_ID,
        companionId: STUDENT_ID,
        status: 'ready',
        mode: 'Video',
        scheduledAt: Timestamp.fromMillis(
          Date.now() + 10 * 60 * 1000
        ),
        durationMinutes: 45,
      }
    );
  });

  await assertFails(
    setDoc(
      doc(elderDB(), 'video_calls', 'call-5'),
      callData({ checkInId: 'future-checkin' })
    )
  );
});

test('Kamala can end an answered call', async () => {
  const callId = 'call-6';

  await assertSucceeds(
    setDoc(
      doc(elderDB(), 'video_calls', callId),
      callData()
    )
  );

  await assertSucceeds(
    updateDoc(doc(studentDB(), 'video_calls', callId), {
      status: 'answered',
      answer: {
        type: 'answer',
        sdp: 'v=0\r\n',
      },
      answeredAt: serverTimestamp(),
    })
  );

  await assertSucceeds(
    updateDoc(doc(elderDB(), 'video_calls', callId), {
      status: 'ended',
      endedAt: serverTimestamp(),
      endedBy: ELDER_ID,
    })
  );
});
