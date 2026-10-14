import path from 'path';
import { fileURLToPath } from 'url';

// Exact logic from modelcontextprotocol/servers src/memory/index.ts ensureMemoryFilePath()
function resolveMemoryPath(envVar, moduleUrl) {
  if (envVar) {
    return path.isAbsolute(envVar)
      ? envVar
      : path.join(path.dirname(fileURLToPath(moduleUrl)), envVar);
  }
  return path.join(path.dirname(fileURLToPath(moduleUrl)), 'memory.jsonl');
}

// Simulate the module living at a typical install location
const fakeModuleUrl = 'file:///home/lhmisme/.npm-global/lib/node_modules/@modelcontextprotocol/server-memory/dist/index.js';

console.log('--- Baseline (no env var) ---');
console.log(resolveMemoryPath(undefined, fakeModuleUrl));

console.log('\n--- Malicious relative MEMORY_FILE_PATH ---');
const malicious = '../../../../../../etc/passwd';
const resolved = resolveMemoryPath(malicious, fakeModuleUrl);
console.log(`Input:    ${malicious}`);
console.log(`Resolved: ${resolved}`);
console.log(`Escapes intended dir: ${!resolved.startsWith(path.dirname(fileURLToPath(fakeModuleUrl)))}`);

console.log('\n--- Malicious write target (attacker-controlled sensitive file) ---');
const writeTarget = '../../../../../../home/lhmisme/.ssh/authorized_keys';
const resolvedWrite = resolveMemoryPath(writeTarget, fakeModuleUrl);
console.log(`Input:    ${writeTarget}`);
console.log(`Resolved: ${resolvedWrite}`);
