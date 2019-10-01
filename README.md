# SoftEther VPN Server Auto Installer (Local Bridge version)

This script will uninstall and reinstall SoftEther VPN Server. If you are upgrading, BACKUP the config using the GUI or copy it from /opt/vpnserver/.

It is recommended to backup various system files as detailed below as this script is designed to install SoftEther VPN Server completely unattended, create a bridge, create a hub, create an admin account for VPN connectivity, create a hub password, create a server password, create a random DDNS hostname, and enable Azure VPN.

Ideally, this script should be run on a completely blank server to avoid any issues with connectivity or system files being altered whilst in production use.

1. First the script asks if you have rebooted, and if not it will immediately reboot (be careful!). The reason for the reboot is to avoid any caching, which has been seen during testing. Once rebooted, re-run the script and continue.

2. If this is uninstalling a previous version of SoftEther VPN Server you will need the previous Server password. This is because the script removes the current Bridge and Hub, and then removes any files/folders associated with the VPN Server. During testing, traces of the server existed causing issues so this process clears the necessary files to avoid an issue with the reinstallation.

3. The script will then go ahead and install the necessary files/folders. Using the variable you can define the version of SoftEther VPN Server to use.

4. Be warned that the process will replace the following files with files stored in github so backups of the files should be taken if you need the content within post-installation:
- /etc/dnsmasq.conf
- /lib/systemd/system/dnsmasq.service
- /etc/systemd/resolved.conf
- /etc/sysctl.d/ipv4_forwarding.conf
- /etc/network/interfaces
- /etc/init.d/vpnserver

5. The script then configures SoftEther VPN Server, generating random passwords for the Server password, Hub password, Admin user VPN account password, IPSec Pre-Shared Key and DDNS hostname for the Azure VPN service.

6. Once completed, the various passwords are displayed at the end for your benefit to configure the server quickly. It is recommended to change these immediately due to being shown in clear text.

7. Once everything has been installed and configured you will be able to immediately connect to the SoftEther VPN Server via your SSTP VPN client using the DDNS hostname and admin user VPN account credentials as shown.

8. No support is provided and no liability is accepted in the event of adverse outcome with the use of the script. If you choose to use it, it is your responsibility to test it before using.

9. The script can be invoked using:

#### Ubuntu 16.04 LTS +
```bash
cd /root/
wget --no-cache -O se-install https://raw.githubusercontent.com/cmptscpeacock/softether-vpn-auto-install/master/softether-vpn-auto-install.bash && chmod +x se-install && ./se-install
```

## Copyright & Credit

### icoexist

This project is based on the auto install project created by icoexist (awesome job!) located at: https://github.com/icoexist/softether-autoinstall.

### SoftEther VPN Project

The SoftEther VPN Project is managed by Daiyuu Nobori, the creator and owner of the SoftEther VPN Project. You can find the stable GitHub repo here: https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/   

The SoftEther VPN Developer branch is located here: https://github.com/SoftEtherVPN/SoftEtherVPN

The SoftEther VPN Project code has not been modified.

SoftEther Project copyright statement:

```
Copyright (c) SoftEther Project at University of Tsukuba, Japan.

The development of SoftEther VPN was supported by the MITOH Project,
a research and development project by Japanese Government,
subsidized by METI (Ministry of Economy, Trade and Industry of Japan),
administrated by IPA (Information Promotion Agency, Japan).
https://www.ipa.go.jp/english/humandev/

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2
as published by the Free Software Foundation.
```