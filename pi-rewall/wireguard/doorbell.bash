#!/bin/bash
PATH=$PATH:/sbin

## Port Knock
cat /var/log/knockd.log | grep "OPEN SESAME" | while read line
do
        src=$(echo $line | grep "OPEN SESAME" | awk ' { print $3 } ' | sed -e "s/://g")
	dns=$(nslookup $src | grep -o "name = .*" | awk ' { print $3 } '|sed -e "s/\.$//g")
        if [[ $dns != '' ]]
        then
                src="$src ($dns)"
        fi
        eventtime_raw=$(echo $line | grep "OPEN SESAME" | awk ' { print $1$2 } ' | sed -e "s/\[//g" -e "s/\]//g" -e 's/./&T/10')
        eventtime=$(date +"%B %d %Y %I:%M %p" -d $eventtime_raw)
        message="Secret Knock Accepted: $src --- $eventtime"
        check=$(grep -F "$message" /etc/wireguard/doorbell.log)
        if [[ $check == '' ]]
        then
                curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"$message\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
                echo $message
                echo $message >> /etc/wireguard/doorbell.log
                sleep 5
        else
                echo "Already Sent!"
        fi
done

## SSH/TTY Logins
cat /var/log/auth.log | grep -v "CRON\[" | grep "session opened" | while read line
do
        raw_time=$(echo $line | awk ' { print $1, $2, $3 } ')
        ctime=$(date +"%B %d %Y %I:%M %p" -d "$raw_time")
        msg=$(echo $line |  awk ' { print $5,$6,$7,$8,$9,$10,$11,$12,$13 } ')
        message="AUTH EVENT: $msg --- $ctime"
        if [[ $msg != '' ]]
        then
                check=$(grep -F "$message" /etc/wireguard/doorbell.log)
                if [[ $check == '' ]]
                then
                        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"$message\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
                        echo "$message" >> /etc/wireguard/doorbell.log
                        echo $message
                        sleep 5
                else
                        echo "Already Sent!"
                fi
	fi
done

## SVC Health Check
zeek_check=$(/opt/zeek/bin/zeekctl status | grep "crashed")
echo "DEBUG Zeek: --$zeek_check--" >> /etc/wireguard/doorbell-debug.log
if [[ $zeek_check != '' ]]
then
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"Zeek has crashed! Attempting recovery sequence...\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
        echo 'Zeek has crashed...attempting restart'
	/opt/zeek/bin/zeekctl deploy
fi

suri_check=$(/usr/sbin/service suricata status|grep "active ("|sed -e "s/ //g")
echo "DEBUG Suri: --$suri_check--" >> /etc/wireguard/doorbell-debug.log
if [[ $suri_check == '' ]]
then
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"Suricata has crashed! Attempting recovery sequence...\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
        echo 'Suricata has crashed...attempting restart'
        /usr/sbin/service suricata restart
fi

dhcp_check=$(/usr/sbin/service isc-dhcp-server status|grep "active (running)"|sed -e "s/ //g")
echo "DEBUG DHCP: --$dhcp_check--" >> /etc/wireguard/doorbell-debug.log
if [[ $dhcp_check == '' ]]
then
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"DHCP has crashed! Attempting recovery sequence...\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
        echo 'DHCP has crashed...attempting restart'
        /usr/sbin/service isc-dhcp-server restart
fi


## Temp
temp=$(sensors -f|grep temp1| awk ' { print $2 } ' | sed -e "s/+//g" -e "s/°F//g" | awk -F "." ' { print $1 } ')
if [[ $temp -ge 115 ]]
then
	curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"FW is running a little warm...($temp °F)\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
        echo "FW is running a little warm...($temp °F)"
fi

## Disk Space
used=$(df -h / | sed -n 2p | awk ' { print $5 } ' | sed -e "s/%//g")
if [[ $used -ge 80 ]]
then
        curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"FW Disk Usage -- $used \%\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
        echo "FW Disk Usage -- $used %"
fi

## UFW Audit
/usr/sbin/ufw status verbose > /etc/wireguard/ufw-compare
/usr/bin/diff /etc/wireguard/ufw-compare /etc/wireguard/ufw-baseline --suppress-common-line | grep -e "<" -e ">" | while read line
do
        if [[ $line == "<"* ]]
        then
                echo "Found new UFW rule: ($line), please verify and whitelist as needed..."
                curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"Found new UFW rule: ($line), please verify and whitelist as needed...\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
		sleep 5
        else
                echo "Missing previously whitelisted UFW rule ($line), please verify and adjust baseline as needed..."
                curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"Missing previously whitelisted UFW rule ($line), please verify and adjust baseline as needed...\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
		sleep 5
        fi
done
