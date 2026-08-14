#!/bin/sh
set -eu

fixture_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
printf '%s\n' iniciado > "$fixture_dir/agent-started"
exec tee "$fixture_dir/agent-received"
