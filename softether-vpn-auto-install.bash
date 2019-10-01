#!/bin/bash

# variables

hubName='hubName1'

## credentials

hubAdmin='admin.user1'

## define console colors

RED='\033[0;31m'
NC='\033[1;37m' # No Color

## define formatting

UNDERLINE='\033[4m'
RESETUNDERLINE='\033[24m'

# execute as sudo

(( EUID != 0 )) && exec sudo -- "$0" "$@"
clear

# remove previous versions
## remove hub and bridge
## password command omitted so manually entered

  echo "Hub Name: $hubName1"

if [ -d "/opt/vpnserver" ]; then
  cd /opt/vpnserver/
  ./vpncmd /server localhost:443 /cmd HubDelete $hubName1
  ./vpncmd /server localhost:443 /cmd bridgeDelete $hubName1 /Device:soft1
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

##apt update -y
##apt upgrade -y

## install build-essential

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' build-essential|grep "installed ok")
echo  "Checking for build-essential: $PKG_OK"
if [ "" == "$PKG_OK" ]; then
  echo "build-essential not installed. Installing now."
  sudo apt install -y build-essential
fi

## download SoftEther VPN

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
printf "\nSystem daemon created. Registering changes...\n\n"
update-rc.d vpnserver defaults > /dev/null 2>&1
printf "\nSoftEther VPN Server should now start as a system service from now on.\n\n"
systemctl start vpnserver
systemctl restart dnsmasq
printf "\nCleaning up...\n\n"
cd && rm -rf /tmp/softether-autoinstall > /dev/null 2>&1
systemctl is-active --quiet vpnserver && echo "Service vpnserver is running."

# confifgure SE

## generate credentials + randoms
hubPassword=$(cat /dev/urandom | base64 -w 0 | fold -w 8 | head -1)
adminPassword=$(cat /dev/urandom | base64 -w 0 | fold -w 8 | head -1)
ddnsHostname=$(cat /dev/urandom | base64 -w 0 | tr -d '[A-Z/+]' | fold -w 8 | head -1)
preSharedKey=$(cat /dev/urandom | base64 -w 0 | tr -d '[/+]' | fold -w 9 | head -1)

## create bridge and hub

cd /opt/vpnserver/
./vpncmd /server localhost:443 /cmd bridgecreate $hubName1 /Device:soft1 /TAP:yes
##./vpncmd /server localhost:443 /cmd HubCreate $hubName1 /PASSWORD:${hubPassword}
./vpncmd /server localhost:443 /cmd HubCreate $hubName1 /PASSWORD:1234


## create default username

##./vpncmd /server localhost:443 /hub:$hubName1 /PASSWORD:${hubPassword} /CMD UserCreate ${hubAdmin} /GROUP:none /REALNAME:none /NOTE:none
./vpncmd /server localhost:443 /hub:$hubName1 /PASSWORD:1234 /CMD UserCreate ${hubAdmin} /GROUP:none /REALNAME:none /NOTE:none
##./vpncmd /server localhost:443 /hub:$hubName1 /PASSWORD:${hubPassword} /CMD UserPasswordSet ${hubAdmin} /PASSWORD:${adminPassword}
./vpncmd /server localhost:443 /hub:$hubName1 /PASSWORD:1234 /CMD UserPasswordSet ${hubAdmin} /PASSWORD:123456789


## create vpn

./vpncmd /server localhost:443 /cmd IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:${preSharedKey} /DEFAULTHUB:$hubName1
./vpncmd /server localhost:443 /cmd DynamicDnsSetHostname ${ddnsHostname}
./vpncmd /server localhost:443 /cmd VpnAzureSetEnable yes

printf "\n${RED}${UNDERLINE}Hub Password:${NC}${RESETUNDERLINE}  ${hubPassword}\n\n"
printf "\n${RED}${UNDERLINE}Admin Username:${NC}${RESETUNDERLINE}  ${hubAdmin} ${RED}${UNDERLINE}Admin Password:${NC}${RESETUNDERLINE}  ${adminPassword}\n\n"
printf "\n${RED}${UNDERLINE}IPSec Pre-Shared Key:${NC}${RESETUNDERLINE}  ${preSharedKey}\n\n"
printf "\n${RED}${UNDERLINE}DDNS Hostname:${NC}${RESETUNDERLINE}  ${ddnsHostname}.vpnazure.net\n\n"
