#!/usr/bin/env bash
# Deprecated compatibility entry point. Version-sensitive CLI installation now
# comes exclusively from toolchain/lock.sh through the v1 core CLI layer.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT_DIR/scripts/bootstrap/core-cli.sh"
