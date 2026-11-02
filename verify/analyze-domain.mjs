#!/usr/bin/env node
/**
 * Analyses the Dart domain layer that ships in this adaptation.
 *
 * These files deliberately import no Flutter and no plugin packages, so they can
 * be checked with a plain Dart SDK — no Flutter install and no package download
 * required. That keeps the "did the port break the pure logic?" question
 * answerable on any machine.
 *
 * Usage:
 *   node verify/analyze-domain.mjs            # PATH上需要有 dart 3.13+
 */
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');

const targets = [
  'lib/features/ads/domain/ad_segment.dart',
  'lib/features/ads/domain/airstrike_detector.dart',
  'lib/features/ads/domain/ad_policy.dart',
  'lib/features/ads/domain/ad_signal_source.dart',
  'lib/domain/ad_card_classifier.dart',
  'lib/domain/recommendation_settings.dart',
  'lib/features/create/domain/create_entry.dart',
  'lib/features/create/domain/create_draft.dart',
  'lib/features/create/domain/create_repository.dart',
  'lib/features/create/domain/create_media_picker.dart',
];

let output;
try {
  output = execFileSync('dart', ['analyze', ...targets], {
    cwd: repoRoot,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
} catch (error) {
  output = (error.stdout ?? '') + (error.stderr ?? '');
}
console.log(output.trim());
const clean = output.includes('No issues found!');
console.log(clean ? 'domain layer: clean' : 'domain layer: issues reported above');
process.exit(clean ? 0 : 1);
