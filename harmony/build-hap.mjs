#!/usr/bin/env node
/**
 * Builds the HarmonyOS entry HAP without DevEco Studio.
 *
 * Requires:
 *   1. HarmonyOS Command Line Tools (sdkmgr / ohpm / hvigor / codelinter),
 *      downloaded from developer.huawei.com → 下载中心 → Command Line Tools.
 *   2. A JDK 17 on PATH or via JAVA_HOME (the HAP packer shells out to java).
 *
 * Usage:
 *   node harmony/build-hap.mjs --cli "C:/path/to/command-line-tools" --jdk "C:/path/to/jdk"
 *
 * The script is deliberately thin: it only sets the two environment variables the
 * tools need and runs ohpm install + hvigorw assembleHap, so the exact same commands
 * stay copy-pasteable into CI.
 */
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
function arg(name) {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
}
const cli = arg('--cli') ?? process.env.HARMONY_CLI_TOOLS;
const jdk = arg('--jdk') ?? process.env.JAVA_HOME;
if (!cli) {
  console.error('missing --cli (HarmonyOS command-line-tools directory)');
  process.exit(2);
}
const env = { ...process.env };
if (jdk) {
  env.JAVA_HOME = jdk;
  env.PATH = [`${jdk}\\bin`, env.PATH].join(';');
}

function run(label, command, commandArgs) {
  console.log(`\n== ${label} ==`);
  execFileSync(command, commandArgs, { cwd: here, env, stdio: 'inherit' });
}

run('ohpm install', resolve(cli, 'bin', 'ohpm.bat'), ['install']);
run('hvigor assembleHap', resolve(cli, 'bin', 'hvigorw.bat'), ['assembleHap', '--no-daemon']);
console.log('\nHAP: entry/build/default/outputs/default/entry-default-unsigned.hap');
