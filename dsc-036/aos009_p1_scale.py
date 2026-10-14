import aos009_battery as mod

# Keep only P1, scale to n=100
mod.PAYLOAD_CLASSES = {
    "P1_legacy_mode": {**mod.PAYLOAD_CLASSES["P1_legacy_mode"], "n_target": 100}
}

# Use a separate state/trace dir so this run doesn't collide with prior state
mod.STATE_FILE = mod.Path("aos009_p1_state.json")
mod.TRACE_DIR = mod.Path("aos009_p1_traces")
mod.TRACE_DIR.mkdir(exist_ok=True)

mod.main()
