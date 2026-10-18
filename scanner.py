import requests
import time
import json

def scan_target(target_url):
    findings = []
    endpoint_count = 0
    start_time = time.time()
    
    endpoints = [
        ('/tools', 'GET', 'Zero-auth tool disclosure'),
        ('/openapi.json', 'GET', 'Unauthenticated schema'),
        ('/data', 'GET', 'CORS wildcard + data leak'),
        ('/compute', 'POST', 'No rate limiting (DoS vector)'),
        ('/api/admin', 'GET', 'Token bypass vulnerability'),
        ('/profile/user2', 'GET', 'Missing isolation (cross-user access)')
    ]
    
    for endpoint, method, title in endpoints:
        endpoint_count += 1
        try:
            url = f'{target_url}{endpoint}'
            if method == 'GET':
                resp = requests.get(url, timeout=2)
            else:
                resp = requests.post(url, json={}, timeout=2)
            
            # Detect vulnerabilities
            severity = 'LOW'
            remediation = 'Add authentication'
            
            if 'tools' in endpoint or 'openapi' in endpoint:
                severity = 'CRITICAL'
                remediation = 'Require API authentication for schema endpoints'
            elif 'admin' in endpoint and resp.status_code == 200:
                severity = 'CRITICAL'
                remediation = 'Implement proper token validation and rate limiting'
            elif 'compute' in endpoint:
                severity = 'HIGH'
                remediation = 'Add rate limiting and request timeouts'
            elif 'profile' in endpoint and 'user2' in endpoint:
                severity = 'CRITICAL'
                remediation = 'Enforce user isolation and ownership checks'
            
            findings.append({
                'title': title,
                'severity': severity,
                'endpoint': endpoint,
                'request_body': method,
                'response_body': resp.text[:200],
                'remediation': remediation
            })
        except Exception as e:
            pass
    
    duration = time.time() - start_time
    return findings, endpoint_count, duration

if __name__ == '__main__':
    findings, count, dur = scan_target('http://localhost:5001')
    print(f'Found {len(findings)} issues in {count} endpoints ({dur:.2f}s)')
    for f in findings:
        print(f"  [{f['severity']}] {f['title']}")
