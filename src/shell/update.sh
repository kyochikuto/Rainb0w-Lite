#!/usr/bin/env bash
source $PWD/src/shell/base/colors.sh
source $PWD/src/shell/docker/docker_utils.sh

set -euo pipefail

echo -e "${B_GREEN}>> Pulling the latest Docker images${RESET}"

docker pull ghcr.io/sagernet/sing-box:latest

source $PWD/src/shell/docker/restart_all_containers.sh

echo -e "${B_GREEN}<< Finished updating! >>${RESET}"
