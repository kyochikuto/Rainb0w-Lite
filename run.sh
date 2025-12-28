#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Allow execution permission
find $PWD -name "*.sh" -exec chmod +x {} \;

source $PWD/src/shell/base/colors.sh
source $PWD/src/shell/base/config.sh
source $PWD/src/shell/os/os_utils.sh

trap '' INT

# OS check
if [[ "$DISTRO" =~ "Ubuntu" ]]; then
    case "$DISTRO_VERSION" in
        "22.04"|"24.04") ;;
        *) echo "Your version of Ubuntu is not supported Only 22.04, and 24.04 versions are supported."
            exit 0
            ;;
    esac
fi

# Check for root permissions
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo ./run.sh)"
    exit
fi

# Install packages
if [ ! -d "$HOME/Rainb0w_Lite_Home" ]; then
    # Install required packages
    fn_install_required_packages
    # Initialize and activate the Python virtual env
    fn_activate_python_venv
    # Install Zram if required
    fn_check_for_memory
    # Get WARP key
    source $PWD/src/shell/cryptography/gen_warp_key.sh
    # Install Docker
    source $PWD/src/shell/os/install_docker.sh
    # Apply Kernel's network stack optimizations
    source $PWD/src/shell/performance/tune_kernel_net.sh
    # Install xtables geoip
    source $PWD/src/shell/os/install_xt_geoip.sh
    # Build the GeoIP database
    source $PWD/src/shell/os/rebuild_xt_geoip_db.sh
    # Setup firewall with necessary protections
    source $PWD/src/shell/access_control/setup_firewall.sh
    # Reboot if needed
    source $PWD/src/shell/os/check_reboot_required.sh
fi

function clear_and_copy_files() {
    # Cleanup and copy all the template files to let the admin select among them
    rm -rf $HOME/Rainb0w_Lite_Home
    mkdir $HOME/Rainb0w_Lite_Home
    cp -r ./Docker/* $HOME/Rainb0w_Lite_Home/
}

function installer_menu() {
    echo -ne "
Rainb0w Lite Proxy Installer
[github.com/kyochikuto/Rainb0w-Lite]

* Install:    Deploys a new configuration of proxies (REALITY, Hysteria, MTProto)
* Restore:    Restore a previous installation's configuration and users

Select installation type:

${B_GREEN}1)${RESET} Install
${B_GREEN}2)${RESET} Restore
${B_RED}0)${RESET} Exit

Choose an option: "
    read -r ans
    case $ans in
    2)
        clear
        # Move the files in place
        clear_and_copy_files
        python3 $PWD/src/configurator.py "Restore"
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -ne 0 ]; then
            echo "Python configurator did not finish successfully!"
            rm -rf $HOME/Rainb0w_Lite_Home
            exit
        fi
        source $PWD/src/shell/deploy.sh "Restore"
        ;;
    1)
        clear
        # Move the files in place
        clear_and_copy_files
        python3 $PWD/src/configurator.py "Install"
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -ne 0 ]; then
            echo "Python configurator did not finish successfully!"
            rm -rf $HOME/Rainb0w_Lite_Home
            exit
        fi
        source $PWD/src/shell/deploy.sh "Install"
        ;;
    0)
        exit
        ;;
    *)
        fn_fail
        clear
        installer_menu
        ;;
    esac
}

function main() {
    if [ -d "$HOME/Rainb0w_Lite_Home" ]; then
        # We have an existing installation, so let's present the dashboard to change settings
        fn_activate_python_venv
        python3 $PWD/main.py
        PYTHON_EXIT_CODE=$?
        if [ $PYTHON_EXIT_CODE -eq 1 ]; then
            source $PWD/src/shell/docker/restart_all_containers.sh
            exit
        else
            exit
        fi
    else
        # This is a new installation
        installer_menu
    fi
}

clear
main
