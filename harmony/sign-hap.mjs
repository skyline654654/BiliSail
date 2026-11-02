#!/usr/bin/env node
// 用官方 hap-sign-tool 给已构建的 unsigned HAP 签名并校验。
//
// 为什么不交给 hvigor 的 signingConfigs：hvigor 的 storePassword/keyPassword 需要
// DevEco Studio 加密后的字符串，命令行无法直接生成；官方 CLI 的 hap-sign-tool
// 支持明文密码（localSign 模式），是等价的官方签名路径。
//
// 用法：
//   HAP_PASSWORD=... OHOS_CLI=/path/to/command-line-tools JDK_HOME=/path/to/jdk node sign-hap.mjs
// 产物：entry/build/default/outputs/default/entry-default-signed.hap
import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, statSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, 'entry', 'build', 'default', 'outputs', 'default');
const unsigned = join(outDir, 'entry-default-unsigned.hap');
const signed = join(outDir, 'entry-default-signed.hap');

if (!existsSync(unsigned)) {
  console.error('missing ' + unsigned + '; run `hvigorw assembleHap` first');
  process.exit(1);
}

const cli = process.env.OHOS_CLI;
const jdk = process.env.JDK_HOME;
const password = process.env.HAP_PASSWORD;
if (!cli || !jdk || !password) {
  console.error('need OHOS_CLI, JDK_HOME and HAP_PASSWORD in the environment');
  process.exit(1);
}

const jar = resolve(cli, 'sdk', 'default', 'openharmony', 'toolchains', 'lib', 'hap-sign-tool.jar');
const java = resolve(jdk, 'bin', process.platform === 'win32' ? 'java.exe' : 'java');

const common = [
  '-jar', jar,
];

execFileSync(java, [...common,
  'sign-app',
  '-mode', 'localSign',
  '-keyAlias', process.env.HAP_KEY_ALIAS || 'bilisail',
  '-signAlg', 'SHA256withECDSA',
  '-appCertFile', join(here, 'signature', process.env.HAP_CERT || 'bilisail-release.cer'),
  '-profileFile', join(here, 'signature', process.env.HAP_PROFILE || 'bilisail-release.p7b'),
  '-inFile', unsigned,
  '-outFile', signed,
  '-keystoreFile', join(here, 'signature', process.env.HAP_KEYSTORE || 'debug.p12'),
  '-keyPwd', password,
  '-keystorePwd', password,
], { stdio: 'inherit' });

execFileSync(java, [...common,
  'verify-app',
  '-inFile', signed,
  '-outCertChain', join(here, 'signature', 'verify-chain.cer'),
  '-outProfile', join(here, 'signature', 'verify-profile.p7b'),
], { stdio: 'inherit' });

console.log('signed:', signed, statSync(signed).size, 'bytes');
void readdirSync;
