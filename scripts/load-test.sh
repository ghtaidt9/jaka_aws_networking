#!/usr/bin/env bash
# Steady traffic against both services; run it in parallel with deploy.sh - 0 failures = zero downtime.
source "$(dirname "$0")/lib.sh"

DURATION=${1:-600}
ALB="http://$(tf_out alb_dns_name)"
END=$((SECONDS + DURATION))
TOTAL=0
FAIL=0

while [ $SECONDS -lt $END ]; do
    for url in "$ALB/api/orders/" "$ALB/api/payments/"; do
        code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" || echo 000)
        TOTAL=$((TOTAL + 1))
        if [ "${code:0:1}" != "2" ]; then
            FAIL=$((FAIL + 1))
            echo "$(date +%T) $code $url"
        fi
    done
    sleep 0.2
done

echo "requests=$TOTAL failed=$FAIL"
[ "$FAIL" -eq 0 ]