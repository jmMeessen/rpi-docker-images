#!/bin/bash

: <<'DISCLAIMER'

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

This script is licensed under the terms of the MIT license.
Unless otherwise noted, code reproduced herein
was written for this script.

- The Pimoroni Crew -

DISCLAIMER

productname="na" # the name of the product to install
scriptname="i2c" # the name of this script
spacereq=1 # minimum size required on root partition in MB
debugmode="no" # whether the script should use debug routines
debuguser="none" # optional test git user to use in debug mode
debugpoint="none" # optional git repo branch or tag to checkout
forcesudo="yes" # whether the script requires to be ran with root privileges
promptreboot="no" # whether the script should always prompt user to reboot
customcmd="yes" # whether to execute commands specified before exit
armhfonly="yes" # whether the script is allowed to run on other arch
armv6="yes" # whether armv6 processors are supported
armv7="yes" # whether armv7 processors are supported
armv8="yes" # whether armv8 processors are supported
raspbianonly="no" # whether the script is allowed to run on other OSes
macosxsupport="no" # whether Mac OS X is supported by the script
osreleases=( "Raspbian" ) # list os-releases supported
oswarning=( "Debian" "Ubuntu" "Mate" ) # list experimental os-releases
squeezesupport="no" # whether Squeeze is supported
wheezysupport="yes" # whether Wheezy is supported
jessiesupport="yes" # whether Jessie is supported

FORCE=$1
DEVICE_TREE=true
ASK_TO_REBOOT=false
CURRENT_SETTING=false
UPDATE_DB=false

BOOTCMD=/boot/cmdline.txt
CONFIG=/boot/config.txt
APTSRC=/etc/apt/sources.list
INITABCONF=/etc/inittab
BLACKLIST=/etc/modprobe.d/raspi-blacklist.conf
LOADMOD=/etc/modules
DTBODIR=/boot/overlays

confirm() {
    if [ "$FORCE" == '-y' ]; then
        true
    else
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
    fi
}

prompt() {
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
}

success() {
    echo "$(tput setaf 2)$1$(tput sgr0)"
}

warning() {
    echo "$(tput setaf 1)$1$(tput sgr0)"
}

newline() {
    echo ""
}

sudocheck() {
    if [ $(id -u) -ne 0 ]; then
        echo -e "Install must be run as root. Try 'sudo ./$scriptname'\n"
        exit 1
    fi
}

sysclean() {
    sudo apt-get clean && sudo apt-get autoclean
    sudo apt-get -y autoremove &> /dev/null
}

sysupdate() {
    if ! $UPDATE_DB; then
        sudo apt-get update
        UPDATE_DB=true
    fi
}

sysupgrade() {
    sudo apt-get update && sudo apt-get upgrade
    sudo apt-get clean && sudo apt-get autoclean
    sudo apt-get -y autoremove &> /dev/null
}

sysreboot() {
    warning "Some changes made to your system require"
    warning "your computer to reboot to take effect."
    newline
    if prompt "Would you like to reboot now?"; then
        sync && sudo reboot
    fi
}

arch_check() {
    IS_ARMHF=false
    IS_ARMv6=false

    if uname -m | grep "armv.l" > /dev/null; then
        IS_ARMHF=true
        if uname -m | grep "armv6l" > /dev/null; then
            IS_ARMv6=true
        fi
    fi
}

os_check() {
    IS_RASPBIAN=false
    IS_MACOSX=false
    IS_SUPPORTED=false
    IS_EXPERIMENTAL=false
    
    if [ -f /etc/os-release ]; then
        if cat /etc/os-release | grep "Raspbian" > /dev/null; then
            IS_RASPBIAN=true && IS_SUPPORTED=true
        fi
        if command -v apt-get > /dev/null; then
            for os in ${osreleases[@]}; do
                if cat /etc/os-release | grep "$os" > /dev/null; then
                    IS_SUPPORTED=true
                fi
            done
            for os in ${oswarning[@]}; do
                if cat /etc/os-release | grep "$os" > /dev/null; then
                    IS_EXPERIMENTAL=true
                fi
            done
        fi
    elif uname -s | grep "Darwin" > /dev/null; then
        IS_MACOSX=true
        if [ $macosxsupport == "yes" ]; then
            IS_SUPPORTED=true
        fi
    fi
}

raspbian_check() {
    IS_SQUEEZE=false
    IS_WHEEZY=false
    IS_JESSIE=false

    if [ -f /etc/os-release ]; then
        if cat /etc/os-release | grep "jessie" > /dev/null; then
            IS_JESSIE=true
        elif cat /etc/os-release | grep "wheezy" > /dev/null; then
            IS_WHEEZY=true
        elif cat /etc/os-release | grep "squeeze" > /dev/null; then
            IS_SQUEEZE=true
        else
            echo "Unsupported distribution"
            exit 1
        fi
    fi
}

raspbian_old() {
    if $IS_SQUEEZE || $IS_WHEEZY ;then
        true
    else
        false
    fi
}

dt_check() {
    if [ -e $CONFIG ] && grep -q "^device_tree=$" $CONFIG; then
        DEVICE_TREE=false
    fi
}

i2c_check() {
    if [ -e $CONFIG ] && grep -q -E "^(device_tree_param|dtparam)=([^,]*,)*i2c(_arm)?(=(on|true|yes|1))?(,.*)?$" $CONFIG; then
        CURRENT_SETTING=true
    else
        CURRENT_SETTING=false
    fi
}

spi_check() {
    if [ -e $CONFIG ] && grep -q -E "^(device_tree_param|dtparam)=([^,]*,)*spi(=(on|true|yes|1))?(,.*)?$" $CONFIG; then
        CURRENT_SETTING=true
    else
        CURRENT_SETTING=false
    fi
}

get_init_sys() {
    if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
        SYSTEMD=1
    elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
        SYSTEMD=0
    else
        echo "Unrecognised init system" && exit 1
    fi
}

get_hw_rev() {
    hwrid=$(grep "^Revision" /proc/cpuinfo | rev | cut -c 2-3 | rev)
    if [ "$hwrid" == "00" ] || [ "$hwrid" == "01" ];then # Pi 1
        hwver="$(grep "^Revision" /proc/cpuinfo | rev | cut -c 1-4 | rev)"
        if [ "$hwrid" == "00" ];then
            hwgen="126" # P1
        elif [ "$hwrid" == "01" ];then
            hwgen="140" # J8
        fi
    else
        hwver="$(grep "^Revision" /proc/cpuinfo | rev | cut -c 1-6 | rev)"
        if [ "$hwrid" == "04" ];then # Pi 2
            hwgen="240"
        elif [ "$hwrid" == "08" ];then # Pi 3
            hwgen="340"
        elif [ "$hwrid" == "09" ];then # Pi 0
            hwgen="040"
        else # Unknown
            hwgen="000"
        fi
    fi
}

: <<'MAINSTART'

Perform all global variables declarations as well as function definition
above this section for clarity, thanks!

MAINSTART

dt_check
arch_check
os_check

if ! $IS_ARMHF; then
    warning "This hardware is not supported, sorry!"
    warning "Config files have been left untouched"
    newline && exit 1
fi

if $IS_RASPBIAN; then
    raspbian_check
    if [ $wheezysupport == "no" ] && raspbian_old; then
        newline && warning "--- Warning ---" && newline
        echo "The $productname installer"
        echo "does not work on this version of Raspbian."
        echo "Check https://github.com/$gitusername/$gitreponame"
        echo "for additional information and support"
        newline && exit 1
    fi
elif [ $raspbianonly == "yes" ];then
        warning "This script is intended for Raspbian on a Raspberry Pi!"
        newline && exit 1
else
    if ! $IS_SUPPORTED && ! $IS_EXPERIMENTAL; then
        warning "Your operating system is not supported, sorry!"
        warning "Config files have been left untouched"
        newline && exit 1
    fi
fi

if [ $forcesudo == "yes" ]; then
    sudocheck
fi

newline
echo "This script will enable I2C on your Raspberry Pi"
newline
warning "--- Warning ---"
newline
echo "Always be careful when running scripts and commands"
echo "copied from the internet. Ensure they are from a"
echo "trusted source."
newline
echo "If you want to see what this script does before"
echo "running it, you should run:"
echo "    \curl -sS get.pimoroni.com/$scriptname"
newline

if confirm "Do you wish to continue?"; then

    i2c_check

    if $DEVICE_TREE && ! $CURRENT_SETTING; then
        newline
        echo "Device Tree Detected"
        echo "Enabling I2C..."
        newline
        if grep -q "^dtparam=i2c_arm=off" $CONFIG; then
            sudo sed -i "s|^dtparam=i2c_arm=off|dtparam=i2c_arm=on|" $CONFIG &> /dev/null
        elif grep -q "^#dtparam=i2c_arm=on" $CONFIG; then
            sudo sed -i "s|^#dtparam=i2c_arm=on|dtparam=i2c_arm=on|" $CONFIG &> /dev/null
        else
            echo "dtparam=i2c_arm=on" | sudo tee -a $CONFIG &> /dev/null
        fi
        echo "$BLACKLIST"
        if ! [ -e $BLACKLIST ]; then
            touch $BLACKLIST
        fi
        sudo sed -i "s|^\(blacklist[[:space:]]*i2c[-_]bcm2708\)|#\1|" $BLACKLIST &> /dev/null
        dtparam i2c_arm=on &> /dev/null
        newline
        success "I2C Enabled"
        warning "Reboot required!"
        newline
        ASK_TO_REBOOT=true
    elif  ! $DEVICE_TREE && [ -e $BLACKLIST ] && grep -q "^blacklist[[:space:]]*i2c-bcm2708" $BLACKLIST; then
        newline
        echo "No Device Tree Detected"
        echo "Enabling I2C..."
        newline
        echo "Commenting out Blacklist entry in "
        echo "$BLACKLIST"
        sudo sed -i "s|^blacklist[[:space:]]*i2c-bcm2708.*|#blacklist i2c-bcm2708|" $BLACKLIST &> /dev/null
        newline && success "I2C Enabled" && newline
    else
        success "I2C Already Enabled" && newline
    fi
    if ! [ -e $LOADMOD ]; then
        touch $LOADMOD
    fi
    if ! grep -q "^i2c[-_]dev" $LOADMOD; then
        echo "i2c-dev" | sudo tee -a $LOADMOD &> /dev/null
    fi
    if ! grep -qe "i2c[-_]bcm2708" $LOADMOD; then
        echo "i2c-bcm2708" | sudo tee -a $LOADMOD &> /dev/null
    fi
    sudo modprobe -a i2c-bcm2708 i2c-dev
else
    newline && echo "Aborting..." && newline
fi

exit 0
