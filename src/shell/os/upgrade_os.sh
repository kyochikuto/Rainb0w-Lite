#!/usr/bin/env bash
source $PWD/src/shell/base/colors.sh

set -euo pipefail

trap - INT
# Update OS
echo -e "${B_GREEN}>> Updating the operating system ${RESET}"
apt update
apt upgrade -y
