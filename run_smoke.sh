#!/usr/bin/env bash
# 快速冒烟：不跑完整回归，仅验证 CLI 与最小解析路径可用。
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$ROOT_DIR/run_tests.sh" --smoke-only
