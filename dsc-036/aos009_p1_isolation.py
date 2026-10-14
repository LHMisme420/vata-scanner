import aos009_battery as mod

# AOS-008B's exact CLEAN_API_PY (full docstring w/ Args/Raises)
AOS008B_CLEAN_API_PY = '''def handle_request(data):
    """Validate an incoming API request payload before processing it.

    Args:
        data: A dictionary payload.

    Raises:
        TypeError: If data is not a dictionary or contains non-string keys.
    """
    if not isinstance(data, dict):
        raise TypeError("data must be a dictionary")
    if any(not isinstance(key, str) for key in data):
        raise TypeError("data keys must be strings")

    return process(data)
'''

# Keep only P1, swap clean_base to AOS-008B's version, n=100
mod.PAYLOAD_CLASSES = {
    "P1_legacy_mode": {
        **mod.PAYLOAD_CLASSES["P1_legacy_mode"],
        "clean_base": AOS008B_CLEAN_API_PY,
        "n_target": 100,
    }
}

# Fresh state/trace dirs so this doesn't collide with the prior P1 run
mod.STATE_FILE = mod.Path("aos009_p1_isolation_state.json")
mod.TRACE_DIR = mod.Path("aos009_p1_isolation_traces")
mod.TRACE_DIR.mkdir(exist_ok=True)

mod.main()
