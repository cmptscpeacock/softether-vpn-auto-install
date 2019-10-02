#!/bin/bash

# variables

seInstallFileUrl='https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.29-9680-rtm/softether-vpnserver-v4.29-9680-rtm-2019.02.28-linux-arm_eabi-32bit.tar.gz'
hubName='hubName1'

## credentials

hubAdmin='admin.user1'

## define console colours

RED='\033[0;31m' # red
WHITE='\033[1;37m' # white

## define formatting

UNDERLINE='\033[4m'
RESETUNDERLINE='\033[24m'

# user confirmation

printf "\n${RED}${UNDERLINE}IMPORTANT${WHITE}${RESETUNDERLINE}\n\nSoftEther VPN is about to be uninstalled. Backup your config file via the GUI or copy it from /opt/vpnserver/ if you are upgrading. \n\n"

while true; do
    read -p "Reboot needed prior to uninstallation. Have you rebooted? (Y - will continue | N - will reboot now)?" answer
    case $answer in
        [yY][eE][sS]|[yY]* )
            break;;
        [Nn][Oo]|[Nn]* ) 
            echo "Rebooting...";
            sleep 3 
            reboot;;
        * ) 
            echo "Please answer y|yes or n|no.";;
    esac
done

# execute as sudo

(( EUID != 0 )) && exec sudo -- "$0" "$@"
clear

# remove previous versions
## remove hub and bridge
## password command omitted so manually entered

printf "\n${RED}${UNDERLINE}Previous Password${WHITE}${RESETUNDERLINE} If asked, enter the previous SoftEther VPN Server password \n\n"

if [ -d "/opt/vpnserver" ]; then
  cd /opt/vpnserver/
  ./vpncmd /server localhost:443 /cmd HubDelete ${hubName}
  ./vpncmd /server localhost:443 /cmd bridgeDelete ${hubName} /Device:soft1
fi

## stop vpnserver

systemctl stop vpnserver

## delete config file

if [ -f "/opt/vpnserver/vpn_server.config" ]; then
  rm -f /opt/vpnserver/vpn_server.config > /dev/null 2>&1
fi

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

# install SoftEther VPN
## create working directory

mkdir -p /tmp/softether-autoinstall
cd /tmp/softether-autoinstall

## Perform apt update

apt update -y
apt upgrade -y

## install build-essential

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' build-essential|grep "Installed OK")
echo  "Checking for build-essential: $PKG_OK"
if [ "" == "$PKG_OK" ]; then
  echo "build-essential is not installed. Installing now..."
  sudo apt install -y build-essential
fi

## download SoftEther VPN

printf "\nDownloading SoftEther VPN"
wget -O softethervpn.tar.gz ${seInstallFileUrl}
tar xzf softethervpn.tar.gz
cd vpnserver
echo $'1\n1\n1' | make &&
cd /tmp/softether-autoinstall && mv vpnserver/ /opt
chmod 600 /opt/vpnserver/* && chmod 700 /opt/vpnserver/vpncmd && chmod 700 /opt/vpnserver/vpnserver
cd /tmp/softether-autoinstall

## configure dhcp service

apt install -y dnsmasq
wget -O dnsmasq.conf https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/dnsmasq.conf
rm /etc/dnsmasq.conf && mv dnsmasq.conf /etc/dnsmasq.conf
wget -O dnsmasq.service https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/dnsmasq.service
mv dnsmasq.service /lib/systemd/system/dnsmasq.service
wget -O resolved.conf https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/resolved.conf
mv resolved.conf /etc/systemd/resolved.conf
sudo service systemd-resolved restart

## enable ipv4 forwarder

wget -O ipv4_forwarding.conf https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/ipv4_forwarding.conf
mv ipv4_forwarding.conf /etc/sysctl.d/ipv4_forwarding.conf

## set persistent tap interface

wget -O interfaces https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/interfaces
mv interfaces /etc/network/interfaces
sysctl --system

## install SE as local bridge

wget -O vpnserver-init-bridge https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/vpnserver-init-bridge > /dev/null 2>&1
mv vpnserver-init-bridge /etc/init.d/vpnserver
chmod 755 /etc/init.d/vpnserver
update-rc.d vpnserver defaults > /dev/null 2>&1
systemctl start vpnserver
systemctl restart dnsmasq
cd && rm -rf /tmp/softether-autoinstall > /dev/null 2>&1
systemctl is-active --quiet vpnserver
printf "\n\n vpnserver is now running"
sleep 10

# confifgure SE
## generate credentials + randoms

seServerPassword=$(cat /dev/urandom | base64 -w 0 | fold -w 8 | head -1)
hubPassword=$(cat /dev/urandom | base64 -w 0 | fold -w 8 | head -1)
adminPassword=$(cat /dev/urandom | base64 -w 0 | fold -w 8 | head -1)
ddnsHostname=$(cat /dev/urandom | base64 -w 0 | tr -d '[A-Z/+]' | fold -w 8 | head -1)
preSharedKey=$(cat /dev/urandom | base64 -w 0 | tr -d '[/+]' | fold -w 9 | head -1)

## set dir

cd /opt/vpnserver/

## create bridge and hub

./vpncmd /server localhost:443 /cmd bridgecreate ${hubName} /Device:soft1 /TAP:yes
./vpncmd /server localhost:443 /cmd HubCreate ${hubName} /PASSWORD:${hubPassword}

## create default username

./vpncmd /server localhost:443 /hub:${hubName} /PASSWORD:${hubPassword} /CMD UserCreate ${hubAdmin} /GROUP:none /REALNAME:none /NOTE:none
./vpncmd /server localhost:443 /hub:${hubName} /PASSWORD:${hubPassword} /CMD UserPasswordSet ${hubAdmin} /PASSWORD:${adminPassword}

## create vpn

./vpncmd /server localhost:443 /cmd IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:${preSharedKey} /DEFAULTHUB:${hubName}
./vpncmd /server localhost:443 /cmd DynamicDnsSetHostname ${ddnsHostname}
./vpncmd /server localhost:443 /cmd VpnAzureSetEnable yes

## set server password

./vpncmd /server localhost:443 /cmd ServerPasswordSet ${seServerPassword}

## output details

printf "\n${RED}${UNDERLINE}SE Server Password:${WHITE}${RESETUNDERLINE}  ${seServerPassword}\n\n"
printf "\n${RED}${UNDERLINE}Hub Password:${WHITE}${RESETUNDERLINE}  ${hubPassword}\n\n"
printf "\n${RED}${UNDERLINE}Admin Username:${WHITE}${RESETUNDERLINE}  ${hubAdmin} ${RED}${UNDERLINE}Admin Password:${WHITE}${RESETUNDERLINE}  ${adminPassword}\n\n"
printf "\n${RED}${UNDERLINE}IPSec Pre-Shared Key:${WHITE}${RESETUNDERLINE}  ${preSharedKey}\n\n"
printf "\n${RED}${UNDERLINE}DDNS Hostname:${WHITE}${RESETUNDERLINE}  ${ddnsHostname}.vpnazure.net\n\n"
