#!/usr/bin/env bash
source $PWD/src/shell/base/colors.sh
source $PWD/src/shell/os/os_utils.sh

set -euo pipefail


IS_PKG_INSTALLED=$(fn_check_for_pkg xtables-addons-dkms)
if [ "$IS_PKG_INSTALLED" = false ] || [ ! -d "/usr/libexec/rainb0w" ]; then
    echo -e "${B_GREEN}>> Installing xt_geoip module${RESET}"
    fn_check_and_install_pkg xtables-addons-dkms
    fn_check_and_install_pkg xtables-addons-common
    fn_check_and_install_pkg libtext-csv-xs-perl
    fn_check_and_install_pkg libmoosex-types-netaddr-ip-perl
    fn_check_and_install_pkg iptables-persistent
    fn_check_and_install_pkg cron

    # Rotate kernel logs and limit them to max 100MB
    source $PWD/src/shell/os/enable_kernel_logrotate.sh

    # Add cronjob to keep the database updated
    systemctl enable --now cron
    if [ ! -f "/etc/crontab" ]; then
        touch /etc/crontab
    fi

    if [ ! -d "/usr/libexec/rainb0w/" ]; then
        mkdir -p /usr/libexec/rainb0w
    fi
    if [ ! -d "/usr/share/xt_geoip" ]; then
        mkdir -p /usr/share/xt_geoip
    fi

    add_job=false
    if crontab -l >/dev/null 2>&1; then
        # A crontab already exists – just check whether the line is present
        if ! crontab -l | grep -q "0 0 \* \* \* root bash /usr/libexec/rainb0w/xt_geoip_update.sh >/tmp/xt_geoip_update.log"; then
            add_job=true
        fi
    else
        # No crontab at all – we definitely need to add it
        add_job=true
    fi

    if [[ ${add_job:-false} == true ]]; then
        echo -e "${B_GREEN}>> Adding daily cronjob to update xt_geoip database${RESET}"
        cp "$PWD/src/shell/cronjobs/xt_geoip_update.sh" /usr/libexec/rainb0w/xt_geoip_update.sh
        chmod +x /usr/libexec/rainb0w/xt_geoip_update.sh

        {
            crontab -l 2>/dev/null || true
            echo "0 0 * * * root bash /usr/libexec/rainb0w/xt_geoip_update.sh >/tmp/xt_geoip_update.log"
        } | crontab -
    fi

    service netfilter-persistent restart
fi
