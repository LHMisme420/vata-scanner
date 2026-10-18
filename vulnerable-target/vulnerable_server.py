from flask import Flask, jsonify, request
import json

app = Flask(__name__)

@app.after_request
def cors(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = '*'
    response.headers['Access-Control-Allow-Headers'] = '*'
    return response

# 1. Zero-auth tools
@app.route('/tools')
def tools():
    return jsonify({
        'tools': [
            {'name': 'bash', 'description': 'Execute shell commands', 'auth': 'none'},
            {'name': 'read', 'description': 'Read files on system', 'auth': 'none'},
            {'name': 'write', 'description': 'Write files to disk', 'auth': 'none'}
        ]
    }), 200

# 2. Schema disclosure
@app.route('/openapi.json')
def schema():
    return jsonify({
        'openapi': '3.0.0',
        'info': {'title': 'Vulnerable API', 'version': '1.0'},
        'paths': {
            '/admin/users': {'get': {'operationId': 'list_users', 'security': []}},
            '/admin/config': {'get': {'operationId': 'get_config', 'security': []}},
            '/api/token': {'post': {'operationId': 'generate_token', 'security': []}}
        }
    }), 200

# 3. CORS wildcard
@app.route('/data')
def data():
    return jsonify({
        'api_keys': ['sk-1234567890abcdef', 'sk-0987654321fedcba'],
        'database_url': 'postgresql://admin:password@db.internal:5432/prod',
        'internal_ips': ['10.0.1.5', '10.0.2.10']
    }), 200

# 4. No rate limiting
@app.route('/compute', methods=['POST'])
def compute():
    return jsonify({'result': 'computed', 'time': '0.001s'}), 200

# 5. Token bypass
@app.route('/api/admin', methods=['GET'])
def admin():
    token = request.headers.get('Authorization', '')
    if token == 'Bearer test':
        return jsonify({'status': 'unauthorized'}), 401
    return jsonify({
        'admin': True,
        'users': [{'id': 1, 'email': 'admin@internal.com', 'role': 'superuser'}],
        'flag': 'FLAG{token_validation_bypassed}'
    }), 200

# 6. Missing isolation
@app.route('/profile/<user_id>')
def profile(user_id):
    users = {
        '1': {'id': 1, 'name': 'Alice', 'email': 'alice@test.com', 'ssn': '123-45-6789'},
        '2': {'id': 2, 'name': 'Bob', 'email': 'bob@test.com', 'ssn': '987-65-4321'},
        '3': {'id': 3, 'name': 'Admin', 'email': 'admin@internal.com', 'ssn': '555-55-5555'}
    }
    return jsonify(users.get(user_id, {'error': 'not found'})), 200

@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
