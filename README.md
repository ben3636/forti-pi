# Forti-Pi
* Who?
   * Anyone! That's the entire idea here. Pi's are inexpensive and great for beginners or those of us on a tight budget.
* What?
   * Forti-Pi is a proof-of-concept for deploying a basic SIEM/XDR setup at home on dirt cheap hardware for personal security or security research
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
 
 Pi-rewall is the firewall installation. It is recommended for the Pi 4 due to the Gigabit support for USB-to-Ethernet adapters but will work on a Pi 3 as well. This install handles basic firewall, NAT, Zeek network auditing, & Suricata IDS alerts. This install can be paired with Pi-lastic to ingest Zeek/Suricata logs for network forensics.
