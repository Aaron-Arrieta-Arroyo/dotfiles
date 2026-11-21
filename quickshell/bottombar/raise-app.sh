#!/bin/sh
# Bring an app's window to the current workspace and focus it (never switch workspace).
exec python3 - "$1" <<'PY'
import json, subprocess, sys

cls = sys.argv[1].lower()
def hc(*a):
    return subprocess.check_output(["hyprctl", *a])
clients = json.loads(hc("clients", "-j"))
ws = json.loads(hc("activeworkspace", "-j"))["id"]
active = json.loads(hc("activewindow", "-j") or "{}").get("address")
mine = [c for c in clients if c["mapped"] and c["class"].lower() == cls]
if not mine:
    sys.exit(0)
here = [c for c in mine if c["workspace"]["id"] == ws]
if here:
    # cycle between this app's windows that are already here
    addrs = [c["address"] for c in here]
    i = addrs.index(active) if active in addrs else -1
    target = here[(i + 1) % len(here)]
else:
    target = mine[0]
    subprocess.run(["hyprctl", "dispatch",
        'hl.dsp.window.move({ workspace = "e+0", window = "address:%s", follow = false })' % target["address"]])
subprocess.run(["hyprctl", "dispatch", 'hl.dsp.focus({ window = "address:%s" })' % target["address"]])
PY
