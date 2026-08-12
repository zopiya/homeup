#!/usr/bin/env bash
# Deprecated compatibility path; v1 host implementation lives in scripts/host.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT_DIR/scripts/host/timezone.sh" "$@"
