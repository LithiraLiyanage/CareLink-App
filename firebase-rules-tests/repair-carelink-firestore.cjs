'use strict';
// Repair only the malformed regular-expression literals in CareLink firestore.rules.
// Place in CareLink-App/firebase-rules-tests/ and run: node .\repair-carelink-firestore.cjs
const fs = require('node:fs');
const path = require('node:path');

const rulesPath = path.resolve(__dirname, '..', 'firestore.rules');
if (!fs.existsSync(rulesPath)) {
  console.error('Not found:', rulesPath);
  console.error('Put this script in CareLink-App/firebase-rules-tests/.');
  process.exit(1);
}
const original = fs.readFileSync(rulesPath, 'utf8');
const newline = original.includes('\r\n') ? '\r\n' : '\n';
const lines = original.split(/\r?\n/);
const edits = [
  {
    name: 'university matches',
    match: (s) => s.includes('request.resource.data.university.matches('),
    correct: String.raw`&& request.resource.data.university.matches('.*\\S.*')`,
  },
  {
    name: 'studentId matches',
    match: (s) => s.includes('request.resource.data.studentId.matches('),
    correct: String.raw`&& request.resource.data.studentId.matches('.*\\S.*')`,
  },
  {
    name: 'universityEmail pattern',
    match: (s) => s.includes("'^[A-Za-z0-9.") && s.includes('@') && s.includes('[A-Za-z]{2,}'),
    correct: String.raw`'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'`,
  },
  {
    name: 'fullName matches',
    match: (s) => s.includes('data.fullName.matches('),
    correct: String.raw`&& data.fullName.matches('.*\\S.*')`,
  },
  {
    name: 'requestPairId underscore',
    match: (s) => s.includes('return string(elderId.size()) +'),
    correct: "return string(elderId.size()) + '_' + elderId + companionId;",
  },
];
let changed = 0;
for (const edit of edits) {
  const indices = lines.map((v, i) => edit.match(v) ? i : -1).filter((i) => i !== -1);
  if (indices.length !== 1) {
    console.error(`Stopping safely: expected exactly 1 line for ${edit.name}, found ${indices.length}.`);
    console.error('No file has been changed. Send your current firestore.rules for a review.');
    process.exit(1);
  }
  const i = indices[0];
  const indent = lines[i].match(/^\s*/)[0];
  const replacement = indent + edit.correct;
  if (lines[i] !== replacement) {
    lines[i] = replacement;
    changed++;
    console.log(`Fix: ${edit.name} (line ${i + 1})`);
  } else {
    console.log(`OK: ${edit.name}`);
  }
}
const result = lines.join(newline);
if (result.includes('request.r).data.role') || result.includes('Older Adult\' esource.data')) {
  console.error('Stopping safely: unrelated malformed connection code was found.');
  console.error('No file has been changed. Send your current firestore.rules for a review.');
  process.exit(1);
}
if (changed > 0) {
  const backup = path.resolve(__dirname, `firestore.rules.backup-${Date.now()}.bak`);
  fs.writeFileSync(backup, original, 'utf8');
  fs.writeFileSync(rulesPath, result, 'utf8');
  console.log(`Backup saved: ${backup}`);
}
console.log(`Done. ${changed} line(s) corrected. Other rules left unchanged.`);
console.log('Next: node --test .\\carelink.rules.test.cjs');
