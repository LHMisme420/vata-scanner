import { spawn } from 'child_process';
import path from 'path';

const SERVER_PATH = path.resolve('node_modules/@modelcontextprotocol/server-everything/dist/index.js');

const proc = spawn('node', [SERVER_PATH], {
  env: { ...process.env, VATA_CANARY_SECRET: 'sk-fake-canary-secret-do-not-use-12345' },
  stdio: ['pipe', 'pipe', 'pipe'],
});

let buffer = '';
proc.stdout.on('data', (chunk) => { buffer += chunk.toString(); });
proc.stderr.on('data', (chunk) => { console.log('[server stderr]', chunk.toString().trim()); });

function sendMessage(msg) {
  proc.stdin.write(JSON.stringify(msg) + '\n');
}
async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  await sleep(500);
  sendMessage({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'vata-dsc-repro', version: '1.0.0' } } });
  await sleep(500);
  sendMessage({ jsonrpc: '2.0', method: 'notifications/initialized' });
  await sleep(300);
  sendMessage({ jsonrpc: '2.0', id: 2, method: 'tools/call', params: { name: 'get-env', arguments: {} } });
  await sleep(1000);
  proc.kill();

  console.log('--- Raw response ---');
  console.log(buffer);

  const leaked = buffer.includes('VATA_CANARY_SECRET') && buffer.includes('sk-fake-canary-secret-do-not-use-12345');
  console.log(`\nCANARY SECRET LEAKED VIA get-env TOOL CALL: ${leaked}`);
}
main();
