#!/usr/bin/env bash
SPECIALS=(special sysmon music communication todo)

active=$(hyprctl activeworkspace -j)
active_name=$(echo "$active" | grep -o '"name": "[^"]*"' | sed 's/"name": "//;s/"//')

idx=-1
if [[ "$active_name" == special:* ]]; then
    cur=${active_name#special:}
    for i in "${!SPECIALS[@]}"; do
        if [[ "${SPECIALS[$i]}" == "$cur" ]]; then
            idx=$i
            break
        fi
    done
fi

opens=()
for s in "${SPECIALS[@]}"; do
    if hyprctl workspaces -j | grep -q "\"name\": \"special:$s\""; then
        opens+=("$s")
    fi
done

toggle() {
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$1\")" >/dev/null
}

if [[ $idx -lt 0 ]]; then
    toggle "${opens[0]:-special}"
    exit 0
fi

next=""
for ((i = idx + 1; i < idx + ${#SPECIALS[@]}; i++)); do
    cand=${SPECIALS[$((i % ${#SPECIALS[@]}))]}
    for o in "${opens[@]}"; do
        if [[ "$o" == "$cand" ]]; then
            next=$cand
            break 2
        fi
    done
done

if [[ -z "$next" ]]; then
    toggle "$cur"
    toggle "${SPECIALS[0]}"
else
    toggle "$cur"
    toggle "$next"
fi