#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)

"$SCRIPT_DIR/arrancar.sh" --headless \
  "+lua require('nvim-treesitter').install({ 'bash', 'python', 'javascript', 'typescript', 'tsx', 'json', 'html', 'css' }):wait(300000)" \
  "+qa"
