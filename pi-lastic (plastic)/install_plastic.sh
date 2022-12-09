#!/bin/bash
###--- Tested on Ubuntu Server 22.10 64bit (ARM) ---###

### --- References & Sources ---###
# https://github.com/watsoninfosec/ElasticXDR/blob/main/Deployment-Guide/Security-Module/Security-Module.md
# https://www.elastic.co/guide/en/fleet/master/secure-connections.html
# https://medium.com/@D00MFist/how-to-quickly-setup-an-elk-stack-and-elastic-agent-to-monitor-macos-event-data-da2469e6bb7

function spacer(){
    for i in {1..5}
    do
        echo
    done
}

# Pre-Flight Checks
if [[ $(whoami) != "root" ]]
then
  echo "ERROR: This script must be run as root!"
  exit 1
fi

echo -e "\033[5m<------WARNING: YOU MUST SET A STATIC IP ADDRESS PRIOR TO SETUP------>\033[0m"
sleep 5
for i in range {1..3}
do
    echo "."
    sleep 0.2
done

echo "<------Configuration of the Elastic stack requires specifying a static IP, things will break if the IP changes with DHCP!------>"
sleep 10
for i in range {1..3}
do
    echo "."
    sleep 0.2
done

echo "<------Quit now if you still need to do this, otherwise script will continue in 10 seconds...------>"
sleep 5
num=10
for i in range {1..10}
do
    echo "$num"
    sleep 1
    ((num=num-1))
done

echo "------------------------------------------Current Network Configuration------------------------------------------"
ip a
echo "-----------------------------------------------------------------------------------------------------------------"
for i in range {1..3}
do
    echo "."
    sleep 0.2
done

echo -n "Enter the static IP for your Elastic instance (x.x.x.x format, no quotes or subnet mask): "
read static_ip

while [[ $static_ip == "" ]]
do
    echo "ERROR: You must provide a static IP for configuration..."
    echo -n "Enter the static IP for your Elastic instance (x.x.x.x format, no quotes or subnet mask): "
    read static_ip
done

# Useless ASCII Art to Brighten Your Day
for i in {1..10}
do
    echo
    sleep 0.2
done

echo '.______   .__   __.  ____      __    ____      __      .______   .______       _______     _______. _______ .__   __. .___________.    _______.'
echo '|   _  \  |  \ |  | |___ \    / /   |___ \    / /      |   _  \  |   _  \     |   ____|   /       ||   ____||  \ |  | |           |   /       |'
echo '|  |_)  | |   \|  |   __) |  / /_     __) |  / /_      |  |_)  | |  |_)  |    |  |__     |   (----`|  |__   |   \|  | `---|  |----`  |   (----`'
echo '|   _  <  |  . `  |  |__ <  |  _ \   |__ \< |  _ \     |   ___/  |      /     |   __|     \   \    |   __|  |  . `  |     |  |        \   \    '
echo '|  |_)  | |  |\   |  ___) | | (_) |  ___) | | (_) |    |  |      |  |\  \----.|  |____.----)   |   |  |____ |  |\   |     |  |    .----)   |   '
echo '|______/  |__| \__| |____/   \___/  |____/   \___/     | _|      | _| `._____||_______|_______/    |_______||__| \__|     |__|    |_______/    '
sleep 3

for i in {1..5}
do
    sleep 0.2
    echo
done

echo -e '\033[5m                         .______    __          __          ___           _______.___________. __    ______                                    \033[0m'
echo -e '\033[5m                         |   _  \  |  |        |  |        /   \         /       |           ||  |  /      |                                   \033[0m'
echo -e '\033[5m ______ ______ ______    |  |_)  | |  |  ______|  |       /  ^  \       |   (----`---|  |----`|  | |  ,----`    ______ ______ ______           \033[0m'
echo -e '\033[5m|______|______|______|   |   ___/  |  | |______|  |      /  /_\  \       \   \       |  |     |  | |  |        |______|______|______|          \033[0m'
echo -e '\033[5m                         |  |      |  |        |  `----./  _____  \  .----)   |      |  |     |  | |  `----.                                   \033[0m'
echo -e '\033[5m                         | _|      |__|        |_______/__/     \__\ |_______/       |__|     |__|  \______|                                   \033[0m'
sleep 5
echo '       _________'
sleep 0.2
echo '      (=========)'
sleep 0.2
echo '      |=========|'
sleep 0.2
echo '      |====_====|'
sleep 0.2
echo '      |== / \ ==|'
sleep 0.2
echo '      |= / _ \ =|'
sleep 0.2
echo '   _  |=| ( ) |=|'
sleep 0.2
echo '  /=\ |=| RPI |=| /=\'
sleep 0.2
echo '  |=| |=|     |=| |=|'
sleep 0.2
echo '  |=| |=|  _  |=| |=|'
sleep 0.2
echo '  |=| |=| | | |=| |=|'
sleep 0.2
echo '  |=| |=| | | |=| |=|'
sleep 0.2
echo '  |=| |=| | | |=| |=|'
sleep 0.2
echo '  |=| |/  | |  \| |=|'
sleep 0.2
echo '  |=|/    | |    \|=|'
sleep 0.2
echo '  |=/     |_|     \=|'
sleep 0.2
echo '  |(_______________)|'
sleep 0.2
echo '  |=| |_|__|__|_| |=|'
sleep 0.2
echo '  |=|   ( ) ( )   |=|'
sleep 0.2
echo ' /===\           /===\'
sleep 0.2
echo '|||||||         |||||||'
sleep 0.2
echo '-------         -------'
sleep 0.2
echo ' (~~~)           (~~~)'
sleep 2
echo '  |||             |||'
sleep 3
echo '  /|\             /|\'
sleep 1
for i in {1..100}
do
    echo
    sleep 0.05
done

# Basic Setup & Package Install
echo "------------------------------------------------------------------------------------------------Installing Components------------------------------------------------------------------------------------------------" 
echo
echo "<---------------------------------Setting Timezone--------------------------------->"
timedatectl set-timezone EST
echo "Status: Complete"

echo
echo "<---------------------------------Adding Elastic Repository--------------------------------->"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt-get update
echo "Status: Complete"

echo
echo "<---------------------------------Installing Elasticsearch & Kibana--------------------------------->"
apt-get -y install elasticsearch kibana
systemctl enable elasticsearch
systemctl enable kibana
echo "Status: Complete"

# Elasticsearch Configuration
spacer
echo "------------------------------------------------------------------------------------------------Configuring Elasticsearch------------------------------------------------------------------------------------------------" 
echo
echo "<---------------------------------Modding Elasticsearch Config File--------------------------------->"
echo 'cluster.name: pi-lastic' >> /etc/elasticsearch/elasticsearch.yml
echo 'network.host: 0.0.0.0' >> /etc/elasticsearch/elasticsearch.yml
echo 'http.port: 9200' >> /etc/elasticsearch/elasticsearch.yml
echo 'discovery.type: single-node' >> /etc/elasticsearch/elasticsearch.yml
echo "Status: Complete"

#echo "---------------------------------Restarting Elasticsearch (you may need to press 'q' when the service status is displayed to continue)---------------------------------"
#service elasticsearch restart
#service elasticsearch status

# Kibana Configuration
spacer
echo "------------------------------------------------------------------------------------------------Configuring Kibana------------------------------------------------------------------------------------------------" 
echo
echo "<---------------------------------Modding Kibana Config File--------------------------------->"
echo 'server.port: 5601' >> /etc/kibana/kibana.yml
echo "server.host: \"$static_ip\"" >> /etc/kibana/kibana.yml
echo "elasticsearch.hosts: [\"https://$static_ip:9200\"]" >> /etc/kibana/kibana.yml
echo "Status: Complete"

# Security Configuration
spacer
echo "------------------------------------------------------------------------------------------------Configuring Security Modules------------------------------------------------------------------------------------------------" 
echo
echo "<---------------------------------Creating Instances Manifest--------------------------------->"
echo
echo
echo -e "\033[5m<------Paste the Contents of 'instances.yml' with your static IP in place of 'X.X.X.X' (See Included Template File in Repo)...------>\033[0m"
sleep 15
echo
echo -n "Enter 'Y' when you're ready: "
read ready

while [[ $ready != "Y" ]]
do
    echo -n "Enter 'Y' when you're ready: "
    read ready
done
nano instances.yml
mv instances.yml /usr/share/elasticsearch/
echo "Status: Complete"

echo
echo "<---------------------------------Generating Self-Signed Certs--------------------------------->"
echo
echo -e "\033[5m<------Hit Enter for the Default Values During Cert Generation------>\033[0m"
sleep 5
/usr/share/elasticsearch/bin/elasticsearch-certutil ca --pem
echo "Status: Complete"

echo
echo "<---------------------------------Installing New Certs--------------------------------->"
apt install zip unzip -y
cd /usr/share/elasticsearch
unzip /usr/share/elasticsearch/elastic-stack-ca.zip
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca-cert ca/ca.crt --ca-key ca/ca.key --pem --in instances.yml --out certs.zip
unzip /usr/share/elasticsearch/certs.zip
mkdir certs
mv /usr/share/elasticsearch/elasticsearch/* certs/
mv /usr/share/elasticsearch/kibana/* certs/
mkdir /etc/kibana/certs
mkdir /etc/kibana/certs/ca
mkdir /etc/elasticsearch/certs
mkdir /etc/elasticsearch/certs/ca
cp ca/ca.* /etc/kibana/certs/ca
cp ca/ca.* /etc/elasticsearch/certs/ca
cp certs/elasticsearch.* /etc/elasticsearch/certs/
cp certs/kibana.* /etc/kibana/certs/
cp ca/ca.crt /
rm -r elasticsearch/ kibana/
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/
chown -R elasticsearch:elasticsearch /etc/elasticsearch/
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/certs/
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/ca/
echo "Status: Complete"

echo
echo "<---------------------------------Applying Certs to Kibana Config File--------------------------------->"
echo 'server.ssl.enabled: true' >> /etc/kibana/kibana.yml
echo 'server.ssl.certificate: "/etc/kibana/certs/kibana.crt"' >> /etc/kibana/kibana.yml
echo 'server.ssl.key: "/etc/kibana/certs/kibana.key"' >> /etc/kibana/kibana.yml
echo 'elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/certs/ca/ca.crt"]' >> /etc/kibana/kibana.yml
echo 'elasticsearch.ssl.certificate: "/etc/kibana/certs/kibana.crt"' >> /etc/kibana/kibana.yml
echo 'elasticsearch.ssl.key: "/etc/kibana/certs/kibana.key"' >> /etc/kibana/kibana.yml
echo "server.publicBaseUrl: \"https://$static_ip:5601\"" >> /etc/kibana/kibana.yml
echo "Status: Complete"

echo
echo "<---------------------------------Applying Certs to Elasticsearch Config File--------------------------------->"
echo 'xpack.security.enabled: true' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.authc.api_key.enabled: true' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.transport.ssl.enabled: true' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.transport.ssl.verification_mode: certificate' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.transport.ssl.key: /etc/elasticsearch/certs/elasticsearch.key' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.transport.ssl.certificate: /etc/elasticsearch/certs/elasticsearch.crt' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.transport.ssl.certificate_authorities: [ "/etc/elasticsearch/certs/ca/ca.crt" ]' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.http.ssl.enabled: true' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.http.ssl.verification_mode: certificate' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.http.ssl.key: /etc/elasticsearch/certs/elasticsearch.key' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.http.ssl.certificate: /etc/elasticsearch/certs/elasticsearch.crt' >> /etc/elasticsearch/elasticsearch.yml
echo 'xpack.security.http.ssl.certificate_authorities: [ "/etc/elasticsearch/certs/ca/ca.crt" ]' >> /etc/elasticsearch/elasticsearch.yml
echo "Status: Complete"

echo
echo "<---------------------------------Restarting Elasticsearch (you may need to press 'q' when the service status is displayed to continue)--------------------------------->"
service elasticsearch restart
service elasticsearch status
echo "Status: Complete"

echo
echo "<---------------------------------Configuring Credential Authentication--------------------------------->"
echo 'xpack.security.enabled: true' >> /etc/kibana/kibana.yml
echo 'xpack.security.session.idleTimeout: "30m"' >> /etc/kibana/kibana.yml
echo 'xpack.encryptedSavedObjects.encryptionKey: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"' >> /etc/kibana/kibana.yml
echo
echo
echo -e "\033[5m<------SAVE THE PASSWORDS THAT ARE ABOUT TO BE GENERATED!------>\033[0m"
sleep 15
echo "<-----------------------------------------PASSWORDS----------------------------------------->"
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto
echo "<------------------------------------------------------------------------------------------->"
echo
echo -n "Enter 'Y' when you've saved the passwords: "
read ready

while [[ $ready != "Y" ]]
do
    echo -n "Enter 'Y' when you've saved the passwords: "
    read ready
done
echo 'elasticsearch.username: "kibana_system"' >> /etc/kibana/kibana.yml
echo 'elasticsearch.password: "XXXXXXXXXXXXXXX"' >> /etc/kibana/kibana.yml
echo
echo
echo -e "\033[5m<------Change the Kibana_System User's Password to What Was Auto Generated...------>\033[0m"
sleep 15
echo
echo -n "Enter 'Y' when you're ready to update the 'kibana_system' user's password (copy it now from above if you need to): "
read ready

while [[ $ready != "Y" ]]
do
    echo -n "Enter 'Y' when you're ready to update the 'kibana_system' user's password (copy it now from above if you need to): "
    read ready
done
nano /etc/kibana/kibana.yml
/usr/share/kibana/bin/kibana-encryption-keys generate --force
echo
echo
echo -e "\033[5m<------Copy the "xpack.encryptedSavedObjects.encryptionKey" Key Above and Update in Kibana's Config...------>\033[0m"
sleep 15
echo
echo -n "Enter 'Y' when you're ready to update the saved object encryption key (copy it now from above if you need to): "
read ready

while [[ $ready != "Y" ]]
do
    echo -n "Enter 'Y' when you're ready to update the saved object encryption key (copy it now from above if you need to): "
    read ready
done
nano /etc/kibana/kibana.yml
echo "Status: Complete"

echo
echo "<---------------------------------Restarting Elasticsearch (you may need to press 'q' when the service status is displayed to continue)--------------------------------->"
service elasticsearch restart
service elasticsearch status
echo "Status: Complete"

echo
echo "<---------------------------------Restarting Kibana (you may need to press 'q' when the service status is displayed to continue)--------------------------------->"
service kibana restart
service kibana status
cp /ca.crt /usr/local/share/ca-certificates/
update-ca-certificates
echo
echo -e "\033[5mInstallation Complete!\033[0m"
sleep 0.5
echo "Please wait about 60 seconds for Kibana to be accessible at https://STATIC_IP:5601 before you login with the 'elastic' user and auto-generated password"

### ------------ Elastic Agent Installation & Setup (Fleet Server & All Other Hosts) ------------ ###
# Use quick start in Kibana Fleet page

# 1. Choose 'Quick Start' in Deployment Mode/Step 3 of Guide

# 2. Change 'Fleet Server Host' address to static IP with TLS on 8220 'https://STATIC_IP:8220' - Step 4 in Guide (Make sure you actually hit submit)

# 3. Generate Service Token

# 4. Copy Command in Step 6 of Guide & Make Changes Shown Below:
#   a. Change '--fleet-server-es' to static IP with TLS/HTTPS
#   b. Replace the '-fleet-server-insecure-http' argument with '--insecure' to acknowledge self-signed cert
#   c. Hold onto this modded command for now, we need to prep the Fleet Server machine before running the install

# 5. Run the following commands on the machine that will be the Fleet Server
#   wget https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-7.17.7-linux-arm64.tar.gz
#   tar -xvf elastic-agent-7.17.7-linux-arm64.tar.gz
#   cd elastic-agent-7.17.7-linux-arm64/

# 6. Run the install command you made above (Step 4)

# 7. Check status of Fleet Server in Kibana

# 8. Add system integration to fleet server policy

# 9. If you don't see data flowing in at this point your Fleet settings may be off:
#   a. Check Fleet Settings to ensure 'Fleet Server Hosts' is set to 'https://YOUR_STATIC_IP:8220' & 'Elasticsearch Hosts' is set to 'https://YOUR_STATIC_IP:9200'
#   b. Save that and wait for the changes to deploy to the agent hosting Fleet Server
#   c. If data still isn't flowing, check out /opt/Elastic/Agent/data/elastic-agent-*/logs for debug info

# 10. For Agents outside of Fleet Server (that has locally trusted the Self-Signed Cert for the Elastic CA) you will need to add the template below to the Fleet Settings with the contents of /ca.crt to allow the other Agents to trust/verify the lower certs signed by it.
#   a. This will present itself as Agents showing "healthy" but not bringing in any data, this is caused by filebeat failing to validate the self-signed cert for Elasticsearch without the ca.crt file to check against
#   b. Be sure to copy the template below with proper indentation and remove the "#" comment characters

#ssl:
#  certificate_authorities:
#  - |
#    -----BEGIN CERTIFICATE-----
#    CONTENTS OF '/ca.crt'
#    -----END CERTIFICATE-----


# NOTE: UFW protected devices will need access to 8220/9200 TCP on the Elastic-Pi. This may need to be allowed in at the Pi hosting Elastic AND outbound on the Pi with the Agent. It has also been observed that Pi's running Ubuntu Server with UFW will need 6789/tcp allowed from lo to lo in order for the Elastic Agent to function. If the Agent is not submitting data, check the UFW logs and adjust rules accordingly.
