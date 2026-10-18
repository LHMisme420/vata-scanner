import subprocess
import time
import sys

print("Starting VATA MCP Scanner...")

procs = []

# Kill existing
subprocess.run("pkill -f 'python.*app.py'; pkill -f 'python.*vulnerable'; pkill -f 'http.server'", shell=True, stderr=subprocess.DEVNULL)
time.sleep(1)

# Start Flask API
p1 = subprocess.Popen([sys.executable, "app.py"], cwd="/home/lhmisme/vata")
procs.append(p1)
print("✓ API starting on localhost:5000")
time.sleep(2)

# Start vulnerable server
p2 = subprocess.Popen([sys.executable, "vulnerable-target/vulnerable_server.py"], cwd="/home/lhmisme/vata")
procs.append(p2)
print("✓ Vulnerable server on localhost:5001")
time.sleep(2)

# Start HTTP server for dashboard
p3 = subprocess.Popen([sys.executable, "-m", "http.server", "8000"], cwd="/home/lhmisme/vata")
procs.append(p3)
print("✓ Dashboard on http://localhost:8000/scan-dashboard.html")

print("\n" + "="*60)
print("VATA is ready!")
print("="*60)
print("\nClick 'Scan Vulnerable Reference Server' button")
print("\nPress Ctrl+C to stop all servers")

try:
    for p in procs:
        p.wait()
except KeyboardInterrupt:
    print("\nShutting down...")
    for p in procs:
        p.terminate()
    sys.exit(0)
