#!/usr/bin/env node
/**
 * Prepares a Flutter environment for the adaptation layer.
 *
 * The repository pins media-kit to git forks (see pubspec.yaml overrides). Those
 * fetches need git-over-https to github.com, which is unavailable on some
 * networks, and none of the adaptation code touches media-kit. This script
 * therefore:
 *   1. backs up pubspec.yaml,
 *   2. strips the `dependency_overrides` block,
 *   3. runs `flutter pub get`,
 *   4. leaves the backup next to it so `--restore` can put it back.
 *
 * Usage:
 *   node verify/prepare-flutter.mjs           # strip overrides + pub get
 *   node verify/prepare-flutter.mjs --restore # restore the original pubspec
 */
import { execFileSync } from 'node:child_process';
import { copyFileSync, existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const pubspec = resolve(repoRoot, 'pubspec.yaml');
const backup = resolve(repoRoot, 'pubspec.yaml.adaptation-backup');

if (process.argv.includes('--restore')) {
  if (!existsSync(backup)) {
    console.error('no backup to restore');
    process.exit(1);
  }
  copyFileSync(backup, pubspec);
  console.log('pubspec.yaml restored');
  process.exit(0);
}

if (!existsSync(backup)) copyFileSync(pubspec, backup);
const source = readFileSync(backup, 'utf8');
const lines = source.split(/\r?\n/);
const start = lines.findIndex((line) => line.startsWith('dependency_overrides:'));
const end = lines.findIndex(
  (line, index) => index > start && line.startsWith('dev_dependencies:'),
);
if (start < 0 || end < 0) {
  console.error('cannot find dependency_overrides block');
  process.exit(1);
}
const stripped = [
  ...lines.slice(0, start),
  '# dependency_overrides removed for adaptation analysis; restore with --restore',
  ...lines.slice(end),
].join('\n');
writeFileSync(pubspec, stripped, 'utf8');
console.log('stripped', end - start, 'override lines');

execFileSync('flutter', ['pub', 'get'], { cwd: repoRoot, stdio: 'inherit' });
