# Forti-Pi

## Background
I graduated undergrad in 2021 and had been using an old Dell PowerEdge R620 I had bought refurbished for my home network/SIEM. The server wasn't new when I bought it as it was originally meant for a capstone project but I enjoyed the PFSense + Elastic Stack setup so much I kept it up as my main driver until it met its untimely demise. While I loved having a full network analysis suite on ESXI, the server was huge, loud, and wasn't cheap to build. 

This led to the idea of re-creating a full Firewall/Zeek/Suricata/Elastic setup using only Raspberry Pi's. It was a reach project that I honestly didn't think would be able to hold up as my main driver but I was pleasantly surprised (thanks to the power of the RPI 4 8GB).

After building this entire setup and using it for tons of personal projects and research, I figured I would package it into a free product others could use on their Pi's so they didn't have to endure the suffering of trying to setup security on the Elastic stack and various firewall/NAT routing rules like I did.

This is by no means a "highly secure" setup, please do not expose this setup to the internet without proper auditing first. The setup includes TLS transport security and username/password logins wherever possible but this is not built to stand up to various poking that would come from the less-than-friendly actors out there on the world wide web. Disclaimer aside, let's make some cool shit on a credit card sized-computer.

## Overview
* Who?
   * Anyone! That's the entire idea here. Pi's are inexpensive and great for beginners or those of us on a tight budget.
* What?
   * Forti-Pi is a proof-of-concept for deploying a basic SIEM/XDR & Firewall setup at home on dirt cheap hardware for personal security or security research
* When?
   * Initial release of the suite is slated for late December 2022!
* Where?
   * Installs on any Raspberry Pi 4 system (8GB RAM is ideal)
   * Can also work on non-ARM Linux distros (may require a bit of modding)
* Why?
   * Lowering the hardware/financial requirements for learning/labbing infosec benefits all of us and helps inspire the next generation of security researchers to push past what is considered "possible"
   * Small businesses may be unable to afford traditional SIEM/XDR products and related hardware, this helps close the gap
 
 ## Components
 ### Pi-lastic (AKA "plastic")
 
 Pi-lastic is the Elastic Stack (Elasticsearch & Kibana) that is installed on your Pi to serve as the SIEM & XDR server. This can ingest all kinds of data and provide detailed dashboards to gleam deep insight on data such as network traffic.
 
 ### Pi-rewall
 
 Pi-rewall is the firewall installation. It is recommended for the Pi 4 due to the Gigabit support for USB-to-Ethernet adapters but will work on a Pi 3 as well. This install handles basic firewall, NAT, Zeek network auditing, & Suricata IDS alerts. This install can be paired with Pi-lastic to ingest Zeek/Suricata logs for network forensics. It is not recommended to install both Pi-lastic and Pi-rewall on the same Pi as a) 8GB RAM likely won't be enough for all that and b) you don't want your SIEM/XDR instance installed on a border system that may have direct internet access.
