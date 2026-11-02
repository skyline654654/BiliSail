#!/usr/bin/env node
/**
 * Runs the same advertisement-boundary fixture through the Dart detector and the
 * Cangjie port, then diffs the two outputs byte for byte.
 *
 * Requirements:
 * - `dart` on PATH (Dart SDK 3.13+; no Flutter needed, the detector imports
 *   no Flutter code).
 * - `cjpm` on PATH (Cangjie 1.2.0).
 *
 * Usage:
 *   node verify/compare.mjs
 * Exit code 0 only when both sides produce identical output for every case.
 */
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');
const casesPath = resolve(here, 'cases.dart');

function run(command, args, cwd) {
  return execFileSync(command, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function lines(text) {
  return text.split(/\r?\n/).filter((line) => line.trim().length > 0 && line.includes(' | '));
}

const dartOut = lines(run('dart', ['run', casesPath], repoRoot));
const cangjieOut = lines(
  run('cjpm', ['run'], resolve(repoRoot, 'cangjie', 'verify')),
);

let failures = 0;
const total = Math.max(dartOut.length, cangjieOut.length);
for (let index = 0; index < total; index++) {
  const dartLine = dartOut[index] ?? '<missing>';
  const cangjieLine = cangjieOut[index] ?? '<missing>';
  if (dartLine !== cangjieLine) {
    failures++;
    console.error('MISMATCH', index);
    console.error('  dart   :', dartLine);
    console.error('  cangjie:', cangjieLine);
  }
}
if (dartOut.length === 0) {
  console.error('no Dart output; is the Dart SDK on PATH?');
  process.exit(2);
}
console.log(`${total} cases, ${failures} mismatches`);
process.exit(failures === 0 ? 0 : 1);
