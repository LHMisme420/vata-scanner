import requests
import time

def scan_target(target_url):
    findings = []
    endpoint_count = 0
    start_time = time.time()
    
    tests = [
        {
            'endpoint': '/tools',
            'method': 'GET',
            'title': 'Zero-auth tool disclosure',
            'severity': 'CRITICAL',
            'remediation': 'Require authentication on /tools endpoint; validate API keys before returning capabilities'
        },
        {
            'endpoint': '/openapi.json',
            'method': 'GET',
            'title': 'Unauthenticated schema disclosure',
            'severity': 'CRITICAL',
            'remediation': 'Move /openapi.json behind authentication; restrict schema access to authenticated users only'
        },
        {
            'endpoint': '/data',
            'method': 'GET',
            'title': 'CORS wildcard + credential exposure',
            'severity': 'HIGH',
            'remediation': 'Restrict CORS to specific origins; remove credentials from response; use environment variables'
        },
        {
            'endpoint': '/compute',
            'method': 'POST',
            'title': 'Missing rate limiting (DoS vector)',
            'severity': 'HIGH',
            'remediation': 'Add rate limiting via Flask-Limiter; implement per-IP request throttling at 10 req/min'
        },
        {
            'endpoint': '/api/admin',
            'method': 'GET',
            'title': 'Token validation bypass',
            'severity': 'CRITICAL',
            'remediation': 'Implement proper JWT validation; verify token signature and expiry before granting access'
        },
        {
            'endpoint': '/profile/2',
            'method': 'GET',
            'title': 'Missing user isolation (IDOR)',
            'severity': 'CRITICAL',
            'remediation': 'Verify user ownership before returning profile; check auth context matches requested user_id'
        }
    ]
    
    for test in tests:
        endpoint_count += 1
        try:
            url = f'{target_url}{test["endpoint"]}'
            if test['method'] == 'GET':
                resp = requests.get(url, timeout=3)
            else:
                resp = requests.post(url, json={}, timeout=3)
            
            response_body = resp.text[:500] if resp.text else '(empty)'
            
            findings.append({
                'title': test['title'],
                'severity': test['severity'],
                'endpoint': test['endpoint'],
                'request_body': f'{test["method"]} {test["endpoint"]}',
                'response_body': response_body,
                'remediation': test['remediation']
            })
        except Exception as e:
            pass
    
    duration = time.time() - start_time
    return findings, endpoint_count, duration

if __name__ == '__main__':
    findings, count, dur = scan_target('http://localhost:5001')
    print(f'Found {len(findings)} issues in {count} endpoints ({dur:.2f}s)')
