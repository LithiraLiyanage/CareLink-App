'use strict';
// LOCAL EMULATOR ONLY. The final test deliberately asserts privacy protection
// that the user's uploaded LIVE rules did not provide. Its failure is a BLOCKER,
// not a reason to make the test weaker or deploy the rules unchanged.
const { before, beforeEach, after, test } = require('node:test');
const {
  initializeTestEnvironment, assertFails, assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, collection, getDoc, getDocs, setDoc, updateDoc, serverTimestamp, Timestamp } = require('firebase/firestore');
const fs = require('node:fs');
const path = require('node:path');
const RULES = path.join(__dirname, 'CareLink_Merged_Privacy_Fixed.rules');
let env;
const db = uid => env.authenticatedContext(uid).firestore();
const seed = async fn => env.withSecurityRulesDisabled(ctx => fn(ctx.firestore()));

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'carelink-hci',
    firestore: { host: '127.0.0.1', port: 8080,
      rules: fs.readFileSync(RULES, 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await seed(async admin => {
    await setDoc(doc(admin, 'users/elderA'), { role: 'Older Adult', fullName: 'Kamala Silva' });
    await setDoc(doc(admin, 'users/elderB'), { role: 'Older Adult', fullName: 'Nimali Perera' });
    await setDoc(doc(admin, 'users/familyA'), { role: 'Family Caregiver', fullName: 'Amali' });
    await setDoc(doc(admin, 'users/familyB'), { role: 'Family Caregiver', fullName: 'Other Family' });
    await setDoc(doc(admin, 'check_ins/sensitiveElderB'), {
      elderId: 'elderB', companionId: 'studentA', elderName: 'Nimali',
      companionName: 'Nethmi', scheduledAt: Timestamp.now(),
      durationMinutes: 30, mode: 'Video', status: 'scheduled',
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
  });
});
after(async () => { if (env) await env.cleanup(); });
function requestData() {
  return {
    requesterId: 'familyA', requesterName: 'Amali', elderName: 'Kamala Silva',
    elderFirstNameLower: 'kamala', relationship: 'Daughter',
    idNumber: 'TEST-ID-001', status: 'pending',
    createdAt: serverTimestamp(), respondedAt: null,
  };
}

test('Family Linking: caregiver can submit and read own request', async () => {
  await assertSucceeds(setDoc(doc(db('familyA'), 'family_link_requests/req1'), requestData()));
  await assertSucceeds(getDoc(doc(db('familyA'), 'family_link_requests/req1')));
});

test('Family Linking: addressed elder can accept request', async () => {
  await seed(admin => setDoc(doc(admin, 'family_link_requests/req1'), {
    requesterId: 'familyA', requesterName: 'Amali', elderName: 'Kamala Silva',
    elderFirstNameLower: 'kamala', relationship: 'Daughter', idNumber: 'TEST-ID-001',
    status: 'pending', createdAt: Timestamp.now(), respondedAt: null,
  }));
  await assertSucceeds(getDoc(doc(db('elderA'), 'family_link_requests/req1')));
  await assertSucceeds(updateDoc(doc(db('elderA'), 'family_link_requests/req1'), {
    status: 'accepted', respondedAt: serverTimestamp(),
  }));
});

test('Family Linking: an unrelated caregiver cannot read somebody else\'s request', async () => {
  await seed(admin => setDoc(doc(admin, 'family_link_requests/req1'), {
    requesterId: 'familyA', requesterName: 'Amali', elderName: 'Kamala Silva',
    elderFirstNameLower: 'kamala', relationship: 'Daughter', idNumber: 'TEST-ID-001',
    status: 'pending', createdAt: Timestamp.now(), respondedAt: null,
  }));
  await assertFails(getDoc(doc(db('familyB'), 'family_link_requests/req1')));
});

test('SECURITY BLOCKER: unlinked family caregiver must NOT read elderB check-in', async () => {
  // This should be DENIED: familyA has no relationship to elderB.
  // Uploaded LIVE rules grant it to all Family Caregivers. Expect FAIL until
  // secure, elder-UID-based authorization is implemented.
  await assertFails(getDoc(doc(db('familyA'), 'check_ins/sensitiveElderB')));
});

// Additional tests: an authenticated caregiver must NEVER be able to forge a link.
test('Untrusted client cannot create a family link', async () => {
  await assertFails(setDoc(doc(db('familyA'), 'family_links/elderA/caregivers/familyA'), {
    elderId: 'elderA', caregiverId: 'familyA', status: 'active',
  }));
});

test('Server-provisioned active UID link permits only the linked elder check-in', async () => {
  await seed(async admin => {
    await setDoc(doc(admin, 'family_links/elderA/caregivers/familyA'), {
      elderId: 'elderA', caregiverId: 'familyA', status: 'active',
    });
    await setDoc(doc(admin, 'check_ins/linkedElderA'), {
      elderId: 'elderA', companionId: 'studentA', elderName: 'Kamala',
      companionName: 'Nethmi', scheduledAt: Timestamp.now(),
      durationMinutes: 30, mode: 'Video', status: 'scheduled',
      createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
    });
  });
  await assertSucceeds(getDoc(doc(db('familyA'), 'check_ins/linkedElderA')));
  await assertFails(getDoc(doc(db('familyA'), 'check_ins/sensitiveElderB')));
  await assertFails(getDoc(doc(db('familyB'), 'check_ins/linkedElderA')));
});

test('Inactive UID link does not grant access to check-ins', async () => {
  await seed(async admin => {
    await setDoc(doc(admin, 'family_links/elderB/caregivers/familyA'), {
      elderId: 'elderB', caregiverId: 'familyA', status: 'revoked',
    });
  });
  await assertFails(getDoc(doc(db('familyA'), 'check_ins/sensitiveElderB')));
});

test('Linked caregiver cannot change link status using client SDK', async () => {
  await seed(admin => setDoc(doc(admin, 'family_links/elderB/caregivers/familyA'), {
    elderId: 'elderB', caregiverId: 'familyA', status: 'active',
  }));
  await assertFails(updateDoc(doc(db('familyA'), 'family_links/elderB/caregivers/familyA'), {
    status: 'revoked',
  }));
});
