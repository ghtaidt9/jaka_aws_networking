#!/usr/bin/env bash
# Build the service/s multi-stage Dockerfile and push it to ECR under an immutable-by-convention tag.
source "$(dirname "${0}")/lib.sh"

SERVICE=${1:-}
TAG=${2:?usage: build-and-push.sh <order|payment> <tag>}
require_service "${SERVICE}"

REPO_URL=$(tf_out "${SERVICE}_ecr_repository_url")
REGISTRY=${REPO_URL%%/*}
REPO_NAME=${REPO_URL#*/}
SRC_DIR="$TF_ROOT/../${SERVICE}-service/${SERVICE}-service"

# Repo is MUTABLE - refuse to overwrite a tag that may already be running somewhere
if aws ecr describe-images --repository-name "$REPO_NAME" --image-ids imageTag="$TAG" >/dev/null 2>&1;
then
    echo "Tag $TAG already exists in $REPO_NAME - pick a new version" >&2
    exit 1
fi

aws ecr get-login-password | docker login --username AWS --password-stdin "$REGISTRY"
docker build -t "$REPO_URL:$TAG" "$SRC_DIR"
docker push "$REPO_URL:$TAG"
echo "Pushed $REPO_URL:$TAG"