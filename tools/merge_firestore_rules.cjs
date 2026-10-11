const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const local = fs.readFileSync(path.join(root, 'firestore.rules'), 'utf8').replace(/\r\n/g, '\n');
const live = fs.readFileSync(path.join(root, 'build/firebase-audit/firestore.live.rules'), 'utf8').replace(/\r\n/g, '\n');

// Match a rules block without treating braces inside strings/comments as syntax.
function block(source, marker) {
  const start = source.indexOf(marker);
  assert.ok(start >= 0 && start === source.lastIndexOf(marker), `Expected one ${marker}`);
  const open = source.indexOf(' {', start) + 1;
  assert.ok(open > start);
  let depth = 0;
  let quote = null;
  for (let i = open; i < source.length; i++) {
    const char = source[i];
    if (quote) {
      if (char === '\\') i++;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === "'" || char === '"') { quote = char; continue; }
    if (char === '/' && source[i + 1] === '/') {
      i = source.indexOf('\n', i);
      assert.ok(i >= 0);
      continue;
    }
    if (char === '/' && source[i + 1] === '*') {
      i = source.indexOf('*/', i + 2) + 1;
      assert.ok(i > 0);
      continue;
    }
    if (char === '{') depth++;
    if (char === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`Unclosed ${marker}`);
}

let merged = live;
function replace(marker, replacement) {
  const original = block(merged, marker);
  merged = merged.replace(original, () => replacement);
}

const helpers = [
  'hasSafeUpdatedVerificationStatus', 'hasValidSetupStage', 'hasValidCompletion',
  'completedRoleIsLocked', 'isValidStudentSubmission',
].map(name => block(local, `function ${name}(`)).join('\n\n    ');
assert.ok(!live.includes('function hasValidSetupStage('), 'This live snapshot has already been merged.');
replace('function hasClientWritableVerificationStatus(',
  `${block(local, 'function hasClientWritableVerificationStatus(')}\n\n    ${helpers}`);

replace('function validOwnerUserUpdate(', `function validOwnerUserUpdate(userId) {
      return isOwner(userId)
        && hasValidRole(request.resource.data)
        && hasSafeUpdatedVerificationStatus(request.resource.data)
        && hasValidSetupStage(request.resource.data)
        && (
          hasValidCompletion(userId, request.resource.data)
          || (
            resource.data.get('profileCompleted', false) == true
            && !resource.data.keys().hasAny(['setupStage'])
            && !request.resource.data.diff(resource.data).affectedKeys()
              .hasAny(['role', 'verificationStatus', 'setupStage', 'profileCompleted'])
          )
        )
        && completedRoleIsLocked(request.resource.data)
        && (
          !resource.data.keys().hasAny(['createdAt'])
          || request.resource.data.createdAt == resource.data.createdAt
        );
    }`);

let submission = block(live, 'function validVerificationSubmission(');
const lastKey = "'rejectionReason'\n      ])";
assert.equal(submission.split(lastKey).length - 1, 2);
submission = submission.replaceAll(lastKey,
  "'rejectionReason',\n        'role',\n        'documentName',\n        'documentUrl',\n        'documentPath',\n        'updatedAt'\n      ])");
submission = submission.replace(
  ").data.verificationStatus == 'pending';",
  ").data.verificationStatus == 'pending'\n      && isValidStudentSubmission(userId, request.resource.data);",
);
assert.ok(submission.includes('&& isValidStudentSubmission('));
replace('function validVerificationSubmission(', submission);

const users = block(live, 'match /users/{userId} {');
replace('match /users/{userId} {', users.replace(
  '&& hasClientWritableVerificationStatus(request.resource.data);',
  '&& hasClientWritableVerificationStatus(request.resource.data)\n        && hasValidSetupStage(request.resource.data)\n        && hasValidCompletion(userId, request.resource.data);',
));
replace('match /consents/{userId} {', block(local, 'match /consents/{userId} {'));

// Everything after the auth section, including existing reviewer behavior, stays intact.
const teamMarker = '    // USER ROLE HELPERS';
assert.equal(merged.slice(merged.indexOf(teamMarker)), live.slice(live.indexOf(teamMarker)));
assert.equal(block(merged, 'function validReviewerUserUpdate('), block(live, 'function validReviewerUserUpdate('));
assert.equal(block(merged, 'function validReviewerVerificationUpdate('), block(live, 'function validReviewerVerificationUpdate('));
assert.equal(block(merged, 'match /student_verifications/{userId} {'), block(live, 'match /student_verifications/{userId} {'));

const output = path.join(root, 'build/firebase-audit/firestore.merged.rules');
fs.writeFileSync(output, merged);
if (process.argv.includes('--apply')) fs.writeFileSync(path.join(root, 'firestore.rules'), merged);
console.log('Merged auth changes; existing team collection rules and reviewer rules preserved byte-for-byte.');
