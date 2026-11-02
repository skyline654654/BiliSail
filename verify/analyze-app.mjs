#!/usr/bin/env node
/**
 * Type-checks the Flutter-dependent adaptation files.
 *
 * The app pubspec pins media-kit to git forks, so `flutter pub get` at the repo
 * root needs git-over-https to github.com. The adaptation files never touch
 * media-kit, so this script builds a *minimal* dependency set in
 * verify/analysis-env/, then points the repo analyzer at that package config.
 *
 * Usage (flutter must be on PATH):
 *   node verify/analyze-app.mjs
 */
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '..');

execFileSync('flutter pub get', { cwd: resolve(here, 'analysis-env'), stdio: 'inherit', shell: true });
execFileSync('node ' + resolve(here, '..', '..', 'scripts', 'make-analysis-config.mjs') + ' ' + repoRoot, { stdio: 'inherit', shell: true });

const targets = [
  'lib/features/create',
  'lib/features/ads',
  'lib/domain/ad_card_classifier.dart',
  'lib/domain/recommendation_settings.dart',
  'lib/core/platform/harmony_system.dart',
  'lib/core/presentation',
  'lib/app/workspace_bottom_bar.dart',
  'lib/app/theme.dart',
  'lib/app/shell.dart',
  'lib/app/bili_app.dart',
  'lib/app/dependencies.dart',
  'lib/main.dart',
];
execFileSync('flutter analyze ' + targets.join(' '), { cwd: repoRoot, stdio: 'inherit', shell: true });
