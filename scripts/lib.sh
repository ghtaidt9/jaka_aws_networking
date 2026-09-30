#!/usr/bin/env bash
# Shared helpers for deploy/rollback/smoke scripts. Source it, don't run it
set -euo pipefail


# Get bash would rewrite "/dev/order-image-tag" into a windows path
export MSYS_NO_PATHCONV=1

TF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${TF_ROOT}"

tf_out() { terraform output -raw "$1"; }

# aws CLI ON Windows ends text output with \r
awst() { aws "$@" --output text | tr -d '\r'; }

export AWS_REGION="${AWS_REGION:-$(tf_out region)}"

require_service() {
    case "${1:-}" in
    order | payment) ;;
    *)
        echo "service must be 'order' or 'payment'" >&2
        exit 2
        ;;
    esac
}