from http.server import HTTPServer, BaseHTTPRequestHandler
import json, urllib.parse

shared_storage = {}

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_len = int(self.headers.get('content-length', 0))
        body = json.loads(self.rfile.read(content_len))
        session = body.get('session')
        shared_storage[session] = body.get('data')
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'stored': True}).encode())
    
    def do_GET(self):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        session = query.get('session', [''])[0]
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(shared_storage).encode())

HTTPServer(('localhost', 8000), Handler).serve_forever()
