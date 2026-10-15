#!/usr/bin/env bash
# Starts the Dart and Flutter MCP server with the SDK this repository pins.
#
# The pin is phone/.fvmrc and fvm finds it only from inside phone/, while an
# agent starts MCP servers from the repository root. A bare `dart mcp-server`
# would analyse and format with whatever Dart is on PATH, which differs from
# the pinned one. Arguments are passed on, e.g. `--enable run_tests`.

set -euo pipefail
cd "$(dirname "$0")/../phone"
# The server speaks JSON-RPC on stdout, so nothing else may reach it there. The first
# run after an SDK change builds the server and fvm may offer to install the SDK; do
# that here, with its output and input kept away from the client.
fvm dart mcp-server --version </dev/null >/dev/null 2>&1 || {
  echo "dart-mcp-server: 'fvm dart mcp-server' does not start here; run 'fvm install' in phone/" >&2
  exit 1
}
exec fvm dart mcp-server "$@"
