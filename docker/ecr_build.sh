#!/bin/bash

# Script for building docker container and pushing to AWS ECR repository, specified in variable ECR_REPO_URL
# Uses current AWS CLI configured profile

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION="us-west-1"
REPO_NAME="simplyblock"
IMAGE_TAG="v1.0.8-admin"
ECR_REPO_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
ECR_IMAGE_URL="$ECR_REPO_URL/$REPO_NAME:$IMAGE_TAG"

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URL

docker build -t $ECR_IMAGE_URL .
docker push $ECR_IMAGE_URL

# # Load necessary kernel module
# sudo modprobe vfio-pci
# # Run container
# docker run -d --privileged -v /lib/modules:/lib/modules $ECR_IMAGE_URL
