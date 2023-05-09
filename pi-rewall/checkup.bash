#!/bin/bash

echo "----------------SURICATA---------------------"
service suricata status
echo
echo "----------------DHCP--------------------"
service isc-dhcp-server status
echo
echo "----------------Knockd---------------------"
service knockd status
echo
echo "----------------Zeek---------------------"
zeekctl status
echo
echo "----------------Temp---------------------"
sensors -f
echo
echo "----------------Avahi---------------------"
service avahi-daemon status
echo
echo "-------------------------------------"
