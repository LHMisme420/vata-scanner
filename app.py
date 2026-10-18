from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import sqlite3, uuid, secrets, string
from datetime import datetime, timezone

app = Flask(__name__)
CORS(app, origins="*")
DB_FILE = 'vata.db'

def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS scans (
        id TEXT PRIMARY KEY, 
        slug TEXT UNIQUE,
        target_url TEXT, 
        findings_count INTEGER, 
        critical_count INTEGER, 
        high_count INTEGER, 
        medium_count INTEGER, 
        low_count INTEGER, 
        exposed INTEGER, 
        endpoint_count INTEGER,
        scan_duration_seconds FLOAT,
        created_at TEXT
    )''')
    c.execute('''CREATE TABLE IF NOT EXISTS findings (
        id INTEGER PRIMARY KEY, 
        scan_id TEXT,
        server_url TEXT, 
        title TEXT, 
        severity TEXT, 
        endpoint TEXT,
        request_body TEXT,
        response_body TEXT,
        remediation TEXT,
        created_at TEXT,
        FOREIGN KEY(scan_id) REFERENCES scans(id)
    )''')
    conn.commit()
    conn.close()

init_db()

def generate_slug(length=16):
    chars = string.ascii_lowercase + string.digits
    return ''.join(secrets.choice(chars) for _ in range(length))

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'}), 200

@app.route('/api/scan-demo', methods=['POST'])
def submit_scan_demo():
    data = request.get_json()
    scan_id = str(uuid.uuid4())
    slug = generate_slug()
    target_url = data.get('target_url', 'unknown')
    findings = data.get('findings', [])
    endpoint_count = data.get('endpoint_count', 0)
    scan_duration = data.get('scan_duration_seconds', 0)
    
    counts = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
    exposed = 0
    for f in findings:
        sev = f.get('severity', 'LOW').upper()
        if sev in counts:
            counts[sev] += 1
        if sev == 'CRITICAL':
            exposed = 1
    
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''INSERT INTO scans 
        (id, slug, target_url, findings_count, critical_count, high_count, medium_count, low_count, exposed, endpoint_count, scan_duration_seconds, created_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''', 
        (scan_id, slug, target_url, len(findings), counts['CRITICAL'], counts['HIGH'], counts['MEDIUM'], counts['LOW'], exposed, endpoint_count, scan_duration, datetime.now(timezone.utc).isoformat()))
    
    for f in findings:
        c.execute('''INSERT INTO findings 
            (scan_id, server_url, title, severity, endpoint, request_body, response_body, remediation, created_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''', 
            (scan_id, target_url, f.get('title'), f.get('severity'), f.get('endpoint', ''), 
             f.get('request_body', ''), f.get('response_body', ''), f.get('remediation', ''),
             datetime.now(timezone.utc).isoformat()))
    
    conn.commit()
    conn.close()
    
    return jsonify({
        'scan_id': scan_id, 
        'slug': slug,
        'permalink': f'/report/{slug}', 
        'findings_count': len(findings), 
        'exposed': exposed
    }), 201

@app.route('/report/<slug>')
def view_report(slug):
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('SELECT * FROM scans WHERE slug = ?', (slug,))
    scan = c.fetchone()
    if not scan:
        return '<h1>Report not found</h1>', 404
    
    c.execute('SELECT title, severity, endpoint, request_body, response_body, remediation FROM findings WHERE scan_id = ?', (scan[0],))
    findings = c.fetchall()
    conn.close()
    
    colors = {'CRITICAL': '#e74c3c', 'HIGH': '#e67e22', 'MEDIUM': '#f39c12', 'LOW': '#3498db'}
    status_emoji = "🔴 EXPOSED" if scan[8] else "🟢 SECURE"
    duration_str = f"{round(float(scan[10]), 2)}"
    
    html = f'''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>VATA Scan Report</title>
</head>
<body style="font-family:sans-serif;max-width:1000px;margin:40px auto">
<h1>VATA Scan Report</h1>
<p><strong>Target:</strong> {scan[2]}</p>
<p><strong>Scan ID:</strong> {scan[0]}</p>
<p><strong>Endpoints scanned:</strong> {scan[9]} | <strong>Duration:</strong> {duration_str}s</p>
<h2>{status_emoji}</h2>
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:15px">
<div style="background:#ecf0f1;padding:15px;text-align:center"><div style="font-size:28px;font-weight:bold">{scan[4]}</div>Critical</div>
<div style="background:#ecf0f1;padding:15px;text-align:center"><div style="font-size:28px;font-weight:bold">{scan[5]}</div>High</div>
<div style="background:#ecf0f1;padding:15px;text-align:center"><div style="font-size:28px;font-weight:bold">{scan[6]}</div>Medium</div>
<div style="background:#ecf0f1;padding:15px;text-align:center"><div style="font-size:28px;font-weight:bold">{scan[7]}</div>Low</div>
</div>
<h2>Findings</h2>
'''
    
    for title, severity, endpoint, req, resp, remediation in findings:
        html += f'''<div style="border-left:4px solid {colors.get(severity, '#999')};padding:15px;margin:10px 0">
<strong>{title}</strong> [{severity}]
<p style="margin:5px 0;font-size:12px;color:#666"><strong>Endpoint:</strong> {endpoint}</p>
<p style="margin:5px 0;font-size:12px;color:#666"><strong>Request:</strong> {req[:100]}</p>
<p style="margin:5px 0;font-size:12px;color:#666"><strong>Response:</strong> {resp[:100]}</p>
<p style="margin:5px 0;font-size:12px;color:#2ecc71"><strong>Fix:</strong> {remediation}</p>
</div>'''
    
    html += '</body></html>'
    return Response(html, mimetype='text/html; charset=utf-8')

if __name__ == '__main__':
    import os; port = int(os.environ.get('PORT', 5000)); app.run(debug=False, host='0.0.0.0', port=port)
