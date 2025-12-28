#!/usr/bin/env bash
source $PWD/src/shell/base/colors.sh

set -euo pipefail

# Re-run with elevated permissions if not already root
echo -e "${B_GREEN}>> Stopping and removing Docker containers${RESET}"
docker ps -aq | xargs docker stop | xargs docker rm
docker network remove proxy

if [[ $EUID -ne 0 ]]; then
    echo -e "${B_GREEN} Requesting elevated permissions...${RESET}"
    exec sudo "$0" "$@"
fi

# Resetting policies to avoid getting locked out until changes are saved!
echo -e "${B_GREEN}>> Resetting firewall${RESET}"
iptables -P INPUT ACCEPT
ip6tables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
ip6tables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
ip6tables -P OUTPUT ACCEPT
iptables -F
ip6tables -F
iptables -X
ip6tables -X
iptables -t nat -F
ip6tables -t nat -F
iptables -t nat -X
ip6tables -t nat -X
iptables -t mangle -F
ip6tables -t mangle -F
iptables -t mangle -X
ip6tables -t mangle -X
systemctl restart docker

# Save changes
iptables-save | tee /etc/iptables/rules.v4 >/dev/null
ip6tables-save | tee /etc/iptables/rules.v6 >/dev/null

echo -e "${B_GREEN}Dropping privileges...${RESET}"
sudo -u "$SUDO_USER"

echo -e "${B_GREEN}>> Removing files${RESET}"
rm -rf $HOME/Rainb0w_Lite_Home

echo -e "${B_GREEN}<< Finished uninstallation! >>${RESET}"
