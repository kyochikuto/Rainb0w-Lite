#!/usr/bin/env bash
source $PWD/src/shell/base/colors.sh
set -euo pipefail

echo -e "${B_GREEN}>> Disabling ZRam swap ${RESET}"
systemctl disable --now zramswap.service
