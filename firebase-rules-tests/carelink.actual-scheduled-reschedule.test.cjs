// Focused CareLink Firestore regression for the REAL Flutter reschedule write.
// Reads project-root firestore.rules; local emulator at 127.0.0.1:8080 only.
'use strict';
const {before, beforeEach, after, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, getDoc, Timestamp, serverTimestamp} = require('firebase/firestore');
let env;
function dbFor(uid) { return env.authenticatedContext(uid).firestore(); }
function future(days) { return Timestamp.fromMillis(Date.now() + days*86400000); }
function data(status='ready') {
  return {
    connectionId:'conn1', matchRequestId:'req1',
    elderId:'elderA', elderName:'Kamala', companionId:'studentA', companionName:'Nethmi',
    scheduledAt:future(1), durationMinutes:30, mode:'Video', status,
    reflection:null, createdAt:Timestamp.now(), updatedAt:Timestamp.now(),
  };
}
before(async () => {
  env=await initializeTestEnvironment({
    projectId:'carelink-hci',
    firestore:{host:'127.0.0.1',port:8080,
      rules:fs.readFileSync(path.resolve(__dirname,'..','firestore.rules'),'utf8')},
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db=ctx.firestore();
    await setDoc(doc(db,'users','elderA'), {role:'Older Adult', fullName:'Kamala', verificationStatus:'notRequired'});
    await setDoc(doc(db,'users','studentA'), {role:'Student Companion', fullName:'Nethmi', verificationStatus:'verified'});
    await setDoc(doc(db,'users','studentB'), {role:'Student Companion', fullName:'Other', verificationStatus:'verified'});
    await setDoc(doc(db,'match_requests','req1'), {elderId:'elderA',companionId:'studentA',status:'accepted'});
    await setDoc(doc(db,'connections','conn1'), {elderId:'elderA',companionId:'studentA',matchRequestId:'req1',status:'active'});
    await setDoc(doc(db,'check_ins','check1'), data('ready'));
  });
});
after(async () => { if(env) await env.cleanup(); });
test('ACTUAL FLOW: Student can reschedule ready -> scheduled with a new future time', async () => {
  const ref=doc(dbFor('studentA'),'check_ins','check1');
  await assertSucceeds(updateDoc(ref,{
    scheduledAt:future(3), status:'scheduled', updatedAt:serverTimestamp(),
  }));
  const updated=await assertSucceeds(getDoc(ref));
  if(updated.data().status!=='scheduled') throw Error('status not saved');
});
test('Reschedule rejects outsider', async () => {
  await assertFails(updateDoc(doc(dbFor('studentB'),'check_ins','check1'),{
    scheduledAt:future(3),status:'scheduled',updatedAt:serverTimestamp(),
  }));
});
test('Ready -> scheduled without changing time is rejected', async () => {
  const db=dbFor('studentA');
  const ref=doc(db,'check_ins','check1');
  const existing=await assertSucceeds(getDoc(ref));
  await assertFails(updateDoc(ref,{
    scheduledAt:existing.data().scheduledAt,status:'scheduled',updatedAt:serverTimestamp(),
  }));
});
test('Ready -> scheduled to a past time is rejected', async () => {
  await assertFails(updateDoc(doc(dbFor('studentA'),'check_ins','check1'),{
    scheduledAt:Timestamp.fromMillis(Date.now()-86400000),status:'scheduled',updatedAt:serverTimestamp(),
  }));
});
test('Completed check-in cannot be rescheduled', async () => {
  await env.withSecurityRulesDisabled(async ctx=>{
    await updateDoc(doc(ctx.firestore(),'check_ins','check1'),{status:'completed'});
  });
  await assertFails(updateDoc(doc(dbFor('studentA'),'check_ins','check1'),{
    scheduledAt:future(3),status:'scheduled',updatedAt:serverTimestamp(),
  }));
});

test('ACTUAL PROBLEM: Student can reschedule scheduled -> scheduled', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(),'check_ins','check1'), {status:'scheduled'});
  });
  const ref=doc(dbFor('studentA'),'check_ins','check1');
  await assertSucceeds(updateDoc(ref, {
    scheduledAt:future(4),status:'scheduled',updatedAt:serverTimestamp(),
  }));
  const updated=await assertSucceeds(getDoc(ref));
  if(updated.data().status!=='scheduled') throw Error('status not saved');
});

test('ACTUAL PROBLEM: completed check-in cannot be changed to scheduled', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(),'check_ins','check1'), {status:'completed'});
  });
  await assertFails(updateDoc(doc(dbFor('studentA'),'check_ins','check1'), {
    scheduledAt:future(4),status:'scheduled',updatedAt:serverTimestamp(),
  }));
});

test('SECURITY: reschedule does not permit companionId modification', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(),'check_ins','check1'), {status:'scheduled'});
  });
  await assertFails(updateDoc(doc(dbFor('studentA'),'check_ins','check1'), {
    scheduledAt:future(4),status:'scheduled',updatedAt:serverTimestamp(), companionId:'studentB',
  }));
});

test('SECURITY: paused connection cannot reschedule', async () => {
  await env.withSecurityRulesDisabled(async ctx => {
    await updateDoc(doc(ctx.firestore(),'connections','conn1'), {status:'paused'});
  });
  await assertFails(updateDoc(doc(dbFor('studentA'),'check_ins','check1'), {
    scheduledAt:future(4),status:'scheduled',updatedAt:serverTimestamp(),
  }));
});
