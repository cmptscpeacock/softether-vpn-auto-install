#!/bin/bash

# define console colors

RED='\033[0;31m'
NC='\033[0m' # No Color

# execute as sudo

(( EUID != 0 )) && exec sudo -- "$0" "$@"
clear

# remove previous versions
## check for SE install folder

if [ -d "/opt/vpnserver" ]; then
  rm -rf /opt/vpnserver > /dev/null 2>&1
fi

if [ -d "/tmp/softether-autoinstall" ]; then
  rm -rf /tmp/softether-autoinstall > /dev/null 2>&1
fi

## check for init script

if
  [ -f "/etc/init.d/vpnserver" ]; then rm /etc/init.d/vpnserver;
fi

## remove vpnserver from systemd

update-rc.d -f vpnserver remove

# install SE
## create working directory

mkdir -p /tmp/softether-autoinstall
cd /tmp/softether-autoinstall

## Perform apt update

##apt update -y
##apt upgrade -y

## install build-essential

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' build-essential|grep "install ok installed")
echo  "Checking for build-essential: $PKG_OK"
if [ "" == "$PKG_OK" ]; then
  echo "build-essential not installed. Installing now."
  sudo apt install -y build-essential
fi

## download SoftEther

printf "\nDownloading SoftEther"
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.29-9680-rtm/softether-vpnserver-v4.29-9680-rtm-2019.02.28-linux-arm_eabi-32bit.tar.gz
tar xzf softether-vpnserver-v4.29-9680-rtm-2019.02.28-linux-arm_eabi-32bit.tar.gz
cd vpnserver
echo $'1\n1\n1' | make &&
cd /tmp/softether-autoinstall && mv vpnserver/ /opt
chmod 600 /opt/vpnserver/* && chmod 700 /opt/vpnserver/vpncmd && chmod 700 /opt/vpnserver/vpnserver
cd /tmp/softether-autoinstall

## configure dhcp service

apt install -y dnsmasq
wget -O dnsmasq.conf https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/dnsmasq.conf
rm /etc/dnsmasq.conf && mv dnsmasq.conf /etc/dnsmasq.conf
##chmod 644 /etc/dnsmasq.conf
wget -O dnsmasq.service https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/dnsmasq.service
mv dnsmasq.service /lib/systemd/system/dnsmasq.service
##chmod 644 /lib/systemd/system/dnsmasq.service
wget -O resolved.conf https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/resolved.conf
mv resolved.conf /etc/systemd/resolved.conf
##chmod 644 /etc/systemd/resolved.conf
sudo service systemd-resolved restart

## configure SE as a local bridge

wget -O vpnserver-init-bridge https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/vpnserver-init-bridge > /dev/null 2>&1
mv vpnserver-init-bridge /etc/init.d/vpnserver
chmod 755 /etc/init.d/vpnserver
printf "\nSystem daemon created. Registering changes...\n\n"
update-rc.d vpnserver defaults > /dev/null 2>&1
printf "\nSoftEther VPN Server should now start as a system service from now on.\n\n"
systemctl start vpnserver
systemctl restart dnsmasq
printf "\nCleaning up...\n\n"
cd && rm -rf /tmp/softether-autoinstall > /dev/null 2>&1
systemctl is-active --quiet vpnserver && echo "Service vpnserver is running."
##printf "\n${RED}!!! IMPORTANT !!!${NC}\n\nTo configure the server, use the SoftEther VPN Server Manager located here: http://bit.ly/2D30Wj8 or use ${RED}sudo /opt/vpnserver/vpncmd${NC}\n\n${RED}!!! UFW is not enabled with this script !!!${NC}\n\nTo see how to open ports for SoftEther VPN, please go here: http://bit.ly/2JdZPx6\n\nNeed help? Feel free to join the Discord server: https://icoexist.io/discord\n\n"
##printf "\n${RED}!!! IMPORTANT !!!${NC}\n\nYou still need to add the local bridge using the SoftEther VPN Server Manager. It is important that after you add the local bridge, you restart both dnsmasq and the vpnserver!\nSee the tutorial here: http://bit.ly/2HoxlQO\n\n"