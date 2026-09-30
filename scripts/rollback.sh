#!/usr/bin/env bash
# Redeploy the previous (or a given) tag. Cancels a refresh that is still running first.
source "$(dirname "$0")/lib.sh"

SERVICE=${1:-}
require_service "$SERVICE"

ASG=$(tf_out "${SERVICE}_asg_name")
PARAM=$(tf_out "${SERVICE}_image_tag_param")
TAG=${2:-$(awst ssm get-parameter --name "${PARAM}-previous" --query Parameter.Value)}

aws autoscaling cancel-instance-refresh --auto-scaling-group-name "$ASG" >/dev/null 2>&1 || true
while awst autoscaling describe-instance-refreshes --auto-scaling-group-name "$ASG" --max-records 1 \
	--query 'InstanceRefreshes[0].Status' | grep -qE 'InProgress|Cancelling|Pending'; do
	echo "Waitting for running refresh to stop..."
	sleep 10
done

echo "Rolling $SERVICE back to $TAG"
exec "$TF_ROOT/scripts/deploy.sh" "$SERVICE" "$TAG"
