import http from 'http';

// Simulates a sensitive internal-only endpoint (stand-in for cloud metadata /
// internal admin panel / localhost-only service). Never touches real infra.
const CANARY_CONTENT = 'VATA_SSRF_CANARY: this represents data that should only be reachable from localhost/internal network, e.g. cloud metadata credentials';

const server = http.createServer((req, res) => {
  console.error(`[stub] received request: ${req.method} ${req.url} from ${req.socket.remoteAddress}`);
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(CANARY_CONTENT);
});

server.listen(18081, '127.0.0.1', () => {
  console.log('Local internal-endpoint stub listening on http://127.0.0.1:18081');
});
