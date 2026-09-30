#!/usr/bin/env bash
# Post-deploy checks through the ALB. No args = check both services
source "$(dirname "$0")/lib.sh"

ALB="http://$(tf_out alb_dns_name)"
SERVICES=${1:-"order payment"}
EXPECTED_TAG=${2:-}
FAILED=0

check() { #name url grep-pattern
    local body
    if body=$(curl -fsS --max-time 10 "$2") && grep -q "$3" <<<"$body"; then
        echo " PASS $1"
    else
        echo " FAIL $1 ($2)"
        FAILED=1
    fi
}

for svc in $SERVICES; do
    base="$ALB/api/${svc}s"
    echo "$svc-service"
    check "health UP" "$base/actuator/health" '"status":"UP"'
    check "list returns seeded rows (RDS)" "$base/" '^\[{'
    check "redis round-trip" "$base/redis-check" '"status":"UP"'
    if [ -n "$EXPECTED_TAG" ]; then
        check "running version = $EXPECTED_TAG" "$base/actuator/info" "\"version\":\"$EXPECTED_TAG\""
    fi
done

[ "$FAILED" -eq 0 ] && echo "All smoke tests passed" || { echo "Smoke tests FAILED" >&2; exit 1; }