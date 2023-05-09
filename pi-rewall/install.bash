# <---------------------------------Pi Firewall Installer--------------------------------->
# This script has been successfully tested on Ubuntu Server 20.04 on Arm64 architechure (RPI4)
# <--------------------------------------------------------------------------------------->

##------Run Pre-Flight Checks------##
if [[ $(whoami) != "root" ]]
then
  echo "ERROR: This script must be run as root!"
  exit 1
fi
clear

if [ -d "/root/Pi-rewall" ]
then
        cd /root/Pi-rewall
else
        echo "ERROR: Install Directory Not Found - Ensure Repo is Cloned to /root/Pi-rewall/"
	exit 1
fi

if [ -d "config-files" ]
then
	echo
else
	echo "ERROR: Config-Files Directory not found - Run Installer In Its Native Directory!"
	exit 1
fi

##------Set Timezone------##
timedatectl set-timezone America/New_York

##------Prep/Apply Netplan Conf Migration------##
echo "-----------------------------------Applying Netplan Configuration-----------------------------------"
cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bak
cat config-files/50-cloud-init.yaml > /etc/netplan/50-cloud-init.yaml
echo "10 Seconds until netplan conf is applied...quit now if needed!"
sleep 10
netplan apply

##------Install Zeek------##
apt update
apt upgrade -y
echo "-----------------------------------Installing Zeek-----------------------------------"
echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_20.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_20.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
echo "<--------------------------Updating Packages-------------------------->"
apt update
apt upgrade -y
echo "<--------------------------Starting Zeek Installation-------------------------->"
apt install zeek lm-sensors -y
cp /opt/zeek/etc/networks.cfg /opt/zeek/etc/networks.cfg.bak
cp /opt/zeek/etc/node.cfg /opt/zeek/etc/node.cfg.bak
cat config-files/networks.cfg > /opt/zeek/etc/networks.cfg
cat config-files/node.cfg > /opt/zeek/etc/node.cfg
echo "export PATH=$PATH:/opt/zeek/bin" >> ~/.bashrc
source ~/.bashrc
echo "@load policy/tuning/json-logs.zeek" >> /opt/zeek/share/zeek/site/local.zeek
zeekctl check
zeekctl deploy
zeekctl status
ls -1 /opt/zeek/logs/current/
source ~/.bashrc
zeekctl restart

##------Setup Basic FW Forwarding------##
echo "-----------------------------------Configuring UFW Firewall-----------------------------------"
ufw --force reset
echo "net/ipv4/ip_forward=1" >> /etc/ufw/sysctl.conf # Allow IPv4 FWD
cp /etc/ufw/before.rules /etc/ufw/before.rules.bak #https://linuxize.com/post/how-to-setup-a-firewall-with-ufw-on-ubuntu-20-04/ 
cat config-files/before.rules > /etc/ufw/before.rules

##------Setup FW Rules------##
### Temp Fallback SSH (To Avoid Lockout, delete this later manually once access is confirmed)
ufw allow 22/tcp
### Allow LAN->DNS
ufw allow in on eth1 from X.X.X.0/24 to X.X.X.1 port 53 proto udp
## Allow LAN->SSH
ufw allow in on eth1 from X.X.X.0/24 to X.X.X.1 port 22 proto tcp
## Protect Upper Private Networks (Duplicate rule and add additional internal CIDR ranges if needed)
ufw route deny from X.X.X.X/X to 192.168.0.0/16
## Allow LAN->NAT Routing
ufw route allow in on eth1 from X.X.X.X/24 out on eth0

## Allow Zeek (Needs to be granted port access on loopback to function, if not logging see Zeekctl config port or check UFW logs for blocked on loopback)
ufw allow in on lo from 127.0.0.1 to 127.0.0.1 port <ZEEKCTL_PORT> proto tcp

## Set Logging Level & Activate FW
ufw logging high
ufw enable
ufw reload

##------Install & Configure DHCP Server------##
echo "-----------------------------------Installing DHCP Server-----------------------------------"
apt install isc-dhcp-server -y
echo
echo "<---Please set the interfaces for DHCP to listen on in the file that opens next (Ex. Add both eth1 and eth2 separated by a space)--->"
sleep 10
nano /etc/default/isc-dhcp-server #(Add both eth1 and eth2 separated by a space)
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.bak
cat config-files/dhcpd.conf > /etc/dhcp/dhcpd.conf
systemctl enable isc-dhcp-server
service isc-dhcp-server restart

##------Install & Configure Suricata------##
cd /root
git clone https://github.com/ben3636/suricata-pi
echo "-----------------------------------Installing Suricata-----------------------------------"
add-apt-repository ppa:oisf/suricata-stable
apt update
apt-get install suricata -y
suricata-update
cp /etc/suricata/suricata.yaml /etc/suricata/suricata.yaml.bak
cat config-files/suricata.yaml > /etc/suricata/suricata.yaml
echo "<---Please set/verify the interfaces for Suricata in the service file...(You can add multiple separated by commas)--->"
sleep 10
nano /root/suricata-pi/suricata #Add IFACE= statements for ETH0/1/2
mkdir /root/suricata-pi/snort-rules
tar -xvf /root/suricata-pi/snortrules-snapshot-2983.tar.gz -C /root/suricata-pi/snort-rules/
cd /root/suricata-pi
tar -xvf /root/suricata-pi/community-rules.tar.gz
mv /root/suricata-pi/community-rules/community.rules /var/lib/suricata/rules/
mv /root/suricata-pi/snort-rules/rules/*.rules /var/lib/suricata/rules/
suricata-update
suricata-update update-sources
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source ptresearch/attackdetection
suricata-update enable-source sslbl/ssl-fp-blacklist
suricata-update enable-source sslbl/ja3-fingerprints
suricata-update enable-source etnetera/aggressive
suricata-update enable-source tgreen/hunting
suricata-update
mv /root/suricata-pi/suricata /etc/default/
service suricata start
systemctl enable suricata
chmod +x suricata-auto-update
mv suricata-auto-update /etc/cron.daily
cd /root/Pi-rewall

##------Install & Configure Pi Hole------##
echo "-----------------------------------Installing Pihole-----------------------------------"
curl -sSL https://install.pi-hole.net | bash

##------Install & Configure WireGuard VPN------##
echo "-----------------------------------Installing Wireguard-----------------------------------"
apt install wireguard -y
#cd /etc/wireguard
#wg genkey | tee privatekey | wg pubkey > publickey
cat wireguard/wg0.conf > /etc/wireguard/wg0.conf
cp wireguard/privatekey /etc/wireguard/
cp wireguard/publickey /etc/wireguard/
cp wireguard/wg0.conf /etc/wireguard/
wg-quick down wg0 && wg-quick up wg0

##------Install & Configure Knockd Service for Port Knocking (Protects WireGuard)------##
echo "-----------------------------------Installing Knockd-----------------------------------"
apt install knockd -y
systemctl enable knockd.service
cp /etc/knockd.conf /etc/knockd.conf.bak
cat config-files/knockd.conf > /etc/knockd.conf
service knockd restart

##------Install & Configure Auditd for Command Auditing------##
echo "-----------------------------------Configuring Auditd-----------------------------------"
apt install auditd -y
echo "-a exit,always -F arch=b64 -S execve -k allcmds" >> /etc/audit/rules.d/audit.rules
service auditd restart

##------Establish UFW Baseline for Change Alerts (see Doorbell.bash)------#
echo "-----------------------------------Setting UFW Baseline-----------------------------------"
ufw status verbose > /etc/wireguard/ufw-baseline

##------Install Required Cron Jobs------##
echo "-----------------------------------Adding Cron Jobs-----------------------------------"
echo
echo "---Please copy the text below and paste into the cron file that opens next...---"
echo
echo "*/1 * * * * bash /etc/wireguard/doorbell.bash"
echo "0 */11 * * * bash /etc/wireguard/pulse.bash"
echo "0 */11 * * * modprobe wireguard && echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control"
modprobe wireguard && echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control
sleep 10
crontab -e
cp wireguard/doorbell.bash /etc/wireguard
cp wireguard/pulse.bash /etc/wireguard
cp other-scripts/egress-notif.bash /etc/cron.weekly/

#Extra/Final push in case things didn't start yet
zeekctl deploy
service knockd restart
service avahi-daemon restart
service isc-dhcp-server restart
echo
echo "-----------------------------------Install Complete-----------------------------------"
echo
echo "What you should do now:"
echo
echo "   1. Remove the blanket allow SSH ufw rule (both ipv4 and ipv6) once you have confirmed the other LAN->SSH rule works"
echo "   2. Make any additional firewall modifications and update the baseline file located in /etc/wireguard"
echo "   3. Enjoy having a fast network with enterprise-grade network insights!"
echo "      a. Check out the Pi-lastic portion of the Forti-Pi project to build a Pi-based SIEM for all this data to be used ;)"
