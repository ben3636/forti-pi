#!/bin/bash
date=$(date)
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"Alert System Operational --- $date\"}" https://discord.com/api/webhooks/XXXXXXXXXXXXXX
