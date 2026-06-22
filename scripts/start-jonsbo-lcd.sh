#!/usr/bin/env bash
# Start the Jonsbo / TURZX LCD via turing-smart-screen-python.
#
# Path resolution order (first match wins):
#   1. $TURING_DIR environment variable, if set
#   2. ~/Downloads/turing-smart-screen-python
#   3. ~/turing-smart-screen-python
#
# Override without editing this file:
#   TURING_DIR=/opt/turing-smart-screen-python ~/.local/bin/start-jonsbo-lcd.sh

set -euo pipefail

# Resolve the project directory.
if [[ -n "${TURING_DIR:-}" ]]; then
    PROJECT_DIR="$TURING_DIR"
else
    for candidate in \
        "$HOME/Downloads/turing-smart-screen-python" \
        "$HOME/turing-smart-screen-python"; do
        if [[ -f "$candidate/main.py" ]]; then
            PROJECT_DIR="$candidate"
            break
        fi
    done
fi

if [[ -z "${PROJECT_DIR:-}" || ! -f "$PROJECT_DIR/main.py" ]]; then
    echo "start-jonsbo-lcd: could not find turing-smart-screen-python." >&2
    echo "Set TURING_DIR to the project path, e.g.:" >&2
    echo "  TURING_DIR=/path/to/turing-smart-screen-python $0" >&2
    exit 1
fi

# Prefer the project's virtualenv python; fall back to system python3.
if [[ -x "$PROJECT_DIR/.venv/bin/python" ]]; then
    PYTHON="$PROJECT_DIR/.venv/bin/python"
else
    PYTHON="$(command -v python3 || command -v python)"
    echo "start-jonsbo-lcd: .venv not found in $PROJECT_DIR, using $PYTHON" >&2
fi

cd "$PROJECT_DIR" || exit 1
exec "$PYTHON" "$PROJECT_DIR/main.py"
