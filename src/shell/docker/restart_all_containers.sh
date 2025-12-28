#!/usr/bin/env bash
source $PWD/src/shell/base/colors.sh
source $PWD/src/shell/docker/docker_utils.sh

set -euo pipefail

fn_restart_docker_container sing-box

echo -e "${B_GREEN}<< Finished applying changes! >>${RESET}"
