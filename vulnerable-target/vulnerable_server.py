from flask import Flask, jsonify, request
import time

app = Flask(__name__)

@app.after_request
def cors(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = '*'
    response.headers['Access-Control-Allow-Headers'] = '*'
    return response

# Endpoint 1: Unauthenticated tool access (zero-auth)
@app.route('/tools')
def tools():
    return jsonify({'tools': [
        {'name': 'bash', 'description': 'Execute arbitrary commands'},
        {'name': 'read', 'description': 'Read files'},
        {'name': 'write', 'description': 'Write files'},
        {'name': 'exec', 'description': 'Execute binaries'}
    ]})

# Endpoint 2: Unauthenticated schema disclosure
@app.route('/openapi.json')
def schema():
    return jsonify({
        'openapi': '3.0.0',
        'info': {'title': 'MCP Tools API', 'version': '1.0'},
        'paths': {
            '/bash': {'post': {'operationId': 'execute_bash'}},
            '/read': {'post': {'operationId': 'read_file'}},
            '/admin/config': {'get': {'operationId': 'get_admin_config'}}
        }
    })

# Endpoint 3: CORS wildcard (already in after_request, but explicit here)
@app.route('/data')
def data():
    return jsonify({'sensitive_data': 'api_key=sk-1234567890'})

# Endpoint 4: Missing rate limiting (DoS vector)
@app.route('/compute', methods=['POST'])
def compute():
    # No rate limit, no auth
    for _ in range(100000):
        _ = 1 + 1
    return jsonify({'result': 'computed'})

# Endpoint 5: Token bypass (hardcoded bypass)
@app.route('/api/admin', methods=['GET'])
def admin():
    token = request.headers.get('Authorization', '')
    if token == 'Bearer test':
        return jsonify({'admin': False})  # Bypass: token check does nothing
    return jsonify({'admin': True, 'secret': 'FLAG{admin_bypass}'})

# Endpoint 6: Missing isolation (cross-user data leak)
users = {'user1': {'email': 'user1@test.com'}, 'user2': {'email': 'user2@test.com'}}

@app.route('/profile/<user_id>')
def profile(user_id):
    # No auth, direct access to any user
    return jsonify(users.get(user_id, {'error': 'not found'}))

@app.route('/health')
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
