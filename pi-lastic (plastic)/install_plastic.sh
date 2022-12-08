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
echo 'elasticsearch.username: "kibana_system"' >> /etc/kibana/kibana.yml
echo 'elasticsearch.password: "XXXXXXXXXXXXXXX"' >> /etc/kibana/kibana.yml
echo
echo
echo -e "\033[5m<------Change the Kibana_System User's Password to What Was Auto Generated...------>\033[0m"
sleep 15
nano /etc/kibana/kibana.yml
/usr/share/kibana/bin/kibana-encryption-keys generate --force
echo
echo
echo -e "\033[5m<------Copy the "xpack.encryptedSavedObjects.encryptionKey" Key Above and Update in Kibana's Config...------>\033[0m"
sleep 15
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
