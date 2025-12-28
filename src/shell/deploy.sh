#!/usr/bin/env bash
set -euo pipefail

source $PWD/src/shell/base/colors.sh
source $PWD/src/shell/base/config.sh
source $PWD/src/shell/text/text_utils.sh
source $PWD/src/shell/os/os_utils.sh
source $PWD/src/shell/docker/docker_utils.sh

# Setup REALITY proxy
source $PWD/src/shell/cryptography/gen_x25519_keys.sh

if [[ $EUID -ne 0 ]]; then
    echo -e "${B_GREEN} Requesting elevated permissions...${RESET}"
    exec sudo "$0" "$@"
fi

# Setup Hysteria proxy
hysteria_sni=$(python3 $PWD/src/shell/helper/get_cert_info.py HYSTERIA)
source $PWD/src/shell/cryptography/gen_x509_cert.sh ${hysteria_sni}

# Add cronjob to renew the cert once a year

add_job=false
if crontab -l >/dev/null 2>&1; then
    # A crontab already exists – just check whether the line is present
    if ! crontab -l | grep -q "0 0 \* \* \* root bash /usr/libexec/rainb0w/renew_selfsigned_cert.sh >/tmp/renew_certs.log"; then
        add_job=true
    fi
else
    # No crontab at all – we definitely need to add it
    add_job=true
fi

if [[ ${add_job:-false} == true ]]; then
    echo -e "${B_GREEN}>> Adding daily cronjob to check for renewal of self-signed certs ${RESET}"
    cp $PWD/src/shell/cryptography/gen_x509_cert.sh /usr/libexec/rainb0w/renew_selfsigned_cert.sh
    sed -i "s|^DOMAIN=.*|DOMAIN=\"${hysteria_sni}\"|" /usr/libexec/rainb0w/renew_selfsigned_cert.sh
    chmod +x /usr/libexec/rainb0w/renew_selfsigned_cert.sh

    {
        crontab -l 2>/dev/null || true
        echo "0 0 * * * root bash /usr/libexec/rainb0w/renew_selfsigned_cert.sh >/tmp/renew_certs.log"
    } | crontab -
fi

fn_restart_docker_container "sing-box"

echo -e "\n\nYour proxies are ready now!\n"

if [ ! $# -eq 0 ]; then
    if [ "$1" == 'Install' ]; then
        reality_uri=$(python3 $PWD/src/shell/helper/get_reality_uri.py)
        hysteria_uri=$(python3 $PWD/src/shell/helper/get_hysteria_uri.py)
        echo $(printf '=%.0s' {1..60})
        echo -e "\n*********************** REALITY ***********************"
        echo -e "\n$reality_uri\n"
        echo "$reality_uri" | qrencode -t ansiutf8
        echo -e "\n*********************** HYSTERIA ***********************"
        echo -e "\n$hysteria_uri\n"
        echo "$hysteria_uri" | qrencode -t ansiutf8
        echo -e "\n"
        echo $(printf '=%.0s' {1..60})
        echo -e "\n
${B_YELLOW}NOTE: DO NOT SHARE THESE LINKS AND INFORMATION OVER SMS OR DOMESTIC MESSENGERS,
USE EMAILS OR OTHER SECURE WAYS OF COMMUNICATION INSTEAD!${RESET}
        "
    elif [ "$1" == 'Restore' ]; then
        echo -e "User share urls are the same as in your configuration, you can view them in the dashboard"
    else
        echo -e "Invalid mode supplied!"
    fi
fi

echo -e "\nYou can add/remove users or find more options in the dashboard,
in order to display the dashboard run the 'run.sh' script again.${RESET}"

echo -e "\n"
fn_typewriter "Women " $B_GREEN
fn_typewriter "Life " $B_WHITE
fn_typewriter "Freedom..." $B_RED
echo ""
fn_typewriter "#MahsaAmini " $B_WHITE
echo -e "\n"
