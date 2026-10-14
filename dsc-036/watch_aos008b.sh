#!/bin/bash
# Watches aos008b_battery.py: process liveness, category progress, timeout rate, permanent failures
STATE=aos008b_state.json
LOG=aos008b_run.log
PROC=aos008b_battery.py
INTERVAL=30
TIMEOUT_THRESH=15   # alert if timeouts-per-check exceeds this in one window

prev_timeouts=0
prev_perm_failures=0

while true; do
    ts=$(date '+%H:%M:%S')

    if ! pgrep -f "$PROC" > /dev/null; then
        echo "[$ts] *** PROCESS DEAD ***"
        echo "--- last 15 log lines ---"
        tail -15 "$LOG"
        echo "--- final state ---"
        python3 -c "
import json
state = json.load(open('$STATE'))
for k, v in state['categories'].items():
    perm = sum(1 for r in v['results'] if r.get('reason') and 'PERMANENT_FAILURE' in r['reason'])
    print(f'{k}: completed={v[\"completed\"]}/{v[\"target\"]} permanent_failures={perm}')
"
        break
    fi

    summary=$(python3 -c "
import json
state = json.load(open('$STATE'))
parts = []
for k, v in state['categories'].items():
    perm = sum(1 for r in v['results'] if r.get('reason') and 'PERMANENT_FAILURE' in r['reason'])
    parts.append(f'{k}:{v[\"completed\"]}/{v[\"target\"]}(pf={perm})')
print(' | '.join(parts))
")

    total_timeouts=$(grep -c "attempt.*failed:" "$LOG" 2>/dev/null || echo 0)
    delta=$((total_timeouts - prev_timeouts))
    prev_timeouts=$total_timeouts

    total_perm=$(grep -c "PERMANENTLY FAILED" "$LOG" 2>/dev/null || echo 0)
    perm_delta=$((total_perm - prev_perm_failures))
    prev_perm_failures=$total_perm

    echo "[$ts] $summary | retries this window: $delta (total: $total_timeouts)"

    if [ "$delta" -ge "$TIMEOUT_THRESH" ]; then
        echo "[$ts] *** RETRY RATE SPIKE: $delta in ${INTERVAL}s ***"
    fi

    if [ "$perm_delta" -gt 0 ]; then
        echo "[$ts] *** NEW PERMANENT FAILURE(S): +$perm_delta (total: $total_perm) ***"
    fi

    all_done=$(python3 -c "
import json
state = json.load(open('$STATE'))
print(all(v['completed'] >= v['target'] for v in state['categories'].values()))
")
    if [ "$all_done" = "True" ]; then
        echo "[$ts] *** ALL CATEGORIES COMPLETE ***"
        echo "--- permanent failure summary ---"
        python3 -c "
import json
state = json.load(open('$STATE'))
for k, v in state['categories'].items():
    perm = sum(1 for r in v['results'] if r.get('reason') and 'PERMANENT_FAILURE' in r['reason'])
    print(f'{k}: {perm} permanent failures out of {v[\"target\"]}')
"
        break
    fi

    sleep "$INTERVAL"
done
