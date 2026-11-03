import { test } from 'node:test';
import assert from 'node:assert/strict';

// Use only the local emulator. Unsigned tokens are deliberately emulator-only.
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host), 'Run with npm run test:rules; never against production');
const project = 'demo-task-manager';
const base = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const path = (owner, id) => `users/${owner}/tasks/${id}`;
function token(uid) {
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    sub: uid, user_id: uid, aud: project, iss: `https://securetoken.google.com/${project}`,
    iat: now, exp: now + 3600, firebase: { identities: {}, sign_in_provider: 'custom' }
  })}.`;
}
function headers(uid) {
  return { 'Content-Type': 'application/json', ...(uid ? { Authorization: `Bearer ${token(uid)}` } : {}) };
}
function fields(title = 'Read a chapter', notes = '') {
  return { title: { stringValue: title }, notes: { stringValue: notes }, isDone: { booleanValue: false } };
}
async function write(uid, owner, id, data, { update = false, createdAt = true } = {}) {
  const write = {
    update: { name: `projects/${project}/databases/(default)/documents/${path(owner, id)}`, fields: data },
    updateTransforms: [
      ...(createdAt ? [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }] : []),
      { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }
    ],
    ...(update ? { updateMask: { fieldPaths: Object.keys(data) } } : {})
  };
  return fetch(`${base}:commit`, { method: 'POST', headers: headers(uid), body: JSON.stringify({ writes: [write] }) });
}
async function status(response, expected) {
  const body = await response.text();
  assert.equal(response.status, expected, body);
}

test('task ownership, CRUD and schema validation', async () => {
  await status(await write('alice', 'alice', 'valid', fields()), 200);
  await status(await fetch(`${base}/${path('alice', 'valid')}`, { headers: headers('alice') }), 200);
  await status(await fetch(`${base}/users/alice/tasks`, { headers: headers('alice') }), 200);
  await status(await fetch(`${base}/${path('alice', 'valid')}`, { headers: headers('bob') }), 403);
  await status(await fetch(`${base}/users/alice/tasks`, { headers: headers('bob') }), 403);
  await status(await fetch(`${base}/${path('alice', 'valid')}`, { headers: headers() }), 403);
  await status(await write('bob', 'alice', 'intruder', fields()), 403);
  await status(await write(null, 'alice', 'anonymous', fields()), 403);
  await status(await write('alice', 'alice', 'empty', fields('')), 403);
  await status(await write('alice', 'alice', 'spaces', fields('  \n  ')), 403);
  await status(await write('alice', 'alice', 'long-title', fields('x'.repeat(121))), 403);
  await status(await write('alice', 'alice', 'long-notes', fields('Title', 'x'.repeat(501))), 403);
  await status(await write('alice', 'alice', 'boundary', fields('x'.repeat(120), 'x'.repeat(500))), 200);
  await status(await write('alice', 'alice', 'emoji', fields('😀'.repeat(60))), 200);
  await status(await write('alice', 'alice', 'emoji-long', fields('😀'.repeat(61))), 403);
  await status(await write('alice', 'alice', 'multiline', fields('Read\na chapter')), 200);
  await status(await write('alice', 'alice', 'extra', { ...fields(), owner: { stringValue: 'alice' } }), 403);
  const missing = fields(); delete missing.notes;
  await status(await write('alice', 'alice', 'missing', missing), 403);
  await status(await write('alice', 'alice', 'bad-type', { ...fields(), isDone: { stringValue: 'false' } }), 403);
  await status(await write('alice', 'alice', 'already-done', { ...fields(), isDone: { booleanValue: true } }), 403);
  await status(await write('alice', 'alice', 'no-created', fields(), { createdAt: false }), 403);
  await status(await write('alice', 'alice', 'valid', { title: { stringValue: 'Edited' }, notes: { stringValue: 'Details' } }, { update: true, createdAt: false }), 200);
  await status(await write('alice', 'alice', 'valid', { isDone: { booleanValue: true } }, { update: true, createdAt: false }), 200);
  await status(await write('alice', 'alice', 'valid', { isDone: { booleanValue: false } }, { update: true, createdAt: false }), 200);
  await status(await write('alice', 'alice', 'valid', { createdAt: { timestampValue: '2000-01-01T00:00:00Z' } }, { update: true, createdAt: false }), 403);
  await status(await write('bob', 'alice', 'valid', { title: { stringValue: 'Stolen' } }, { update: true, createdAt: false }), 403);
  await status(await fetch(`${base}/${path('alice', 'valid')}`, { method: 'DELETE', headers: headers('bob') }), 403);
  await status(await fetch(`${base}/${path('alice', 'valid')}`, { method: 'DELETE', headers: headers('alice') }), 200);
  await status(await write('bob', 'bob', 'own', fields()), 200);
});
