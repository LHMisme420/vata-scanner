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

def severity_order(sev):
    order = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3}
    return order.get(sev, 4)

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
    findings_raw = c.fetchall()
    conn.close()
    
    findings = sorted(findings_raw, key=lambda x: severity_order(x[1]))
    
    colors = {'CRITICAL': '#e74c3c', 'HIGH': '#e67e22', 'MEDIUM': '#f39c12', 'LOW': '#3498db'}
    status_emoji = "🔴 EXPOSED" if scan[8] else "🟢 SECURE"
    duration_str = f"{round(float(scan[10]), 2)}"
    created_at = scan[11][:10]
    
    html = f'''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>VATA Scan Report</title>
<style>
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; color: #333; }}
.header {{ border-bottom: 1px solid #eee; padding-bottom: 20px; }}
.metadata {{ color: #666; font-size: 14px; line-height: 1.6; }}
.vata-badge {{ display: inline-block; background: #1a1a1a; color: white; padding: 6px 12px; border-radius: 4px; font-size: 12px; margin-top: 15px; }}
.vata-link {{ color: #0066cc; text-decoration: none; }}
.status {{ font-size: 48px; margin: 20px 0; }}
.grid {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; margin: 20px 0; }}
.stat {{ background: #f5f5f5; padding: 15px; text-align: center; border-radius: 4px; }}
.stat-number {{ font-size: 32px; font-weight: bold; }}
.findings {{ margin-top: 30px; }}
.finding {{ border-left: 4px solid #999; padding: 15px; margin: 15px 0; background: #fafafa; border-radius: 3px; }}
.finding-title {{ font-weight: bold; font-size: 16px; margin-bottom: 10px; }}
.finding-row {{ display: grid; grid-template-columns: 150px 1fr; gap: 15px; font-size: 13px; margin: 8px 0; }}
.finding-label {{ color: #666; font-weight: 500; }}
.finding-content {{ color: #333; font-family: 'Monaco', monospace; font-size: 12px; }}
.response-preview {{ background: white; padding: 8px; border: 1px solid #ddd; border-radius: 2px; max-height: 80px; overflow: hidden; }}
.expand-btn {{ color: #0066cc; cursor: pointer; font-size: 12px; margin-top: 5px; }}
.response-full {{ display: none; background: white; padding: 12px; border: 1px solid #ddd; border-radius: 2px; margin-top: 8px; max-height: 300px; overflow-y: auto; white-space: pre-wrap; word-break: break-all; }}
.response-full.show {{ display: block; }}
.remediation {{ color: #27ae60; font-weight: 500; margin-top: 10px; }}
</style>
<script>
function toggleResponse(id) {{
    var elem = document.getElementById('full-' + id);
    elem.classList.toggle('show');
}}
</script>
</head>
<body>
<div class="header">
<h1>VATA Scan Report</h1>
<div class="metadata">
<p><strong>Target:</strong> VATA Vulnerable Reference Server ({scan[2]})</p>
<p><strong>Scan ID:</strong> {scan[0]}</p>
<p><strong>Date scanned:</strong> {created_at} | <strong>Endpoints:</strong> {scan[9]} | <strong>Duration:</strong> {duration_str}s</p>
<div class="vata-badge">
  🔍 Scanned with <a href="https://vata-scanner.onrender.com" class="vata-link">VATA</a> • Receipts Over Promises
</div>
</div>
</div>

<div class="status">{status_emoji}</div>

<div class="grid">
<div class="stat" style="background: #ffe6e6;"><div class="stat-number">{scan[4]}</div>Critical</div>
<div class="stat" style="background: #fff3e6;"><div class="stat-number">{scan[5]}</div>High</div>
<div class="stat" style="background: #fffae6;"><div class="stat-number">{scan[6]}</div>Medium</div>
<div class="stat" style="background: #e6f2ff;"><div class="stat-number">{scan[7]}</div>Low</div>
</div>

<div class="findings">
<h2>Findings ({len(findings)}) — Sorted by Severity</h2>
'''
    
    for idx, (title, severity, endpoint, req, resp, remediation) in enumerate(findings):
        color = colors.get(severity, '#999')
        resp_preview = resp[:150] + ('...' if len(resp) > 150 else '')
        html += f'''<div class="finding" style="border-left-color: {color};">
<div class="finding-title" style="color: {color};">{title} [{severity}]</div>
<div class="finding-row">
<div class="finding-label">Endpoint:</div>
<div class="finding-content">{endpoint}</div>
</div>
<div class="finding-row">
<div class="finding-label">Request:</div>
<div class="finding-content">{req}</div>
</div>
<div class="finding-row">
<div class="finding-label">Response:</div>
<div class="finding-content">
<div class="response-preview">{resp_preview}</div>
<div class="expand-btn" onclick="toggleResponse({idx})">► expand full response</div>
<div id="full-{idx}" class="response-full">{resp}</div>
</div>
</div>
<div class="remediation">✓ {remediation}</div>
</div>
'''
    
    html += '</div></body></html>'
    return Response(html, mimetype='text/html; charset=utf-8')

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=False, host='0.0.0.0', port=port)
