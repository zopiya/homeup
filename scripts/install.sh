#!/usr/bin/env bash
# Deprecated compatibility entry point. The v1 curl endpoint owns checkout
# handling and delegates to the locked `just bootstrap auto` implementation.
set -euo pipefail

echo 'scripts/install.sh is deprecated; forwarding to the v1 development bootstrap.' >&2
curl --fail --location --proto '=https' --tlsv1.2 https://get.zopiya.dev/dev | bash
