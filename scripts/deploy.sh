#!/usr/bin/env bash
# Rolling, zero-downtime deploy: point the service's image-tag parameter at <tag>,
# replace every instance via ASG instance refresh (launch-before-terminate), then smoke test.
source "$(dirname "$0")/lib.sh"

SERVICE=${1:-}
TAG=${2:?usage: deploy.sh <order|payment> <tag>}
require_service "$SERVICE"

ASG=$(tf_out "${SERVICE}_asg_name")
PARAM=$(tf_out "${SERVICE}_image_tag_param")
REPO_URL=$(tf_out "${SERVICE}_ecr_repository_url")

aws ecr describe-images --repository-name "${REPO_URL#*/}" --image-ids imageTag="$TAG" >/dev/null ||

    { echo "Image $TAG not found in ECR - run build-and-push.sh first" >&2; exit 1; }

CURRENT=$(awst ssm get-parameter --name "$PARAM" --query Parameter.Value)
if [ "$CURRENT" != "$TAG" ]; then
    aws ssm put-parameter --name "${PARAM}-previous" --value "$CURRENT" --type String --overwrite >/dev/null
    aws ssm put-parameter --name "$PARAM" --value "$TAG" --type String --overwrite >/dev/null
fi
echo "$SERVICE: $CURRENT -> $TAG (ASG $ASG)"

REFRESH_ID=$(awst autoscaling start-instance-refresh \
    --auto-scaling-group-name "$ASG" \
    --preferences '{"MinHealthyPercentage":100, "MaxHealthyPercentage":200, "InstanceWarmup":300}' \
    --query InstanceRefreshId)

while true; do
    read -r STATUS PCT < <(awst autoscaling describe-instance-refreshes \
        --auto-scaling-group-name "$ASG" --instance-refresh-ids "$REFRESH_ID" \
        --query 'InstanceRefreshes[0].[Status,PercentageComplete]')
    echo "$(date +%T) refresh $STATUS ${PCT}%"
    case "$STATUS" in
    Successful) break ;;
    Failed | Cancelled | RollbackSuccessful | RollbackFailed)
        echo "Deploy failed. Roll back with ./scripts/rollback.sh $SERVICE" >&2
        exit 1
        ;;
    esac
    sleep 20
done

"$TF_ROOT/scripts/smoke-tests.sh" "$SERVICE" "$TAG"