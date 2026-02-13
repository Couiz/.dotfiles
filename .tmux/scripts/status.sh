#!/bin/sh
# All-in-one status bar script — atomic update, no desync
cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{printf "%3.0f%%", $2+$4}')
ram=$(free | awk '/Mem/{printf "%3.0f%%", $3/$2*100}')
disk=$(df -h / | awk 'NR==2{gsub(/%/,"",$5); printf "%3d%%", $5}')

printf "CPU:%s RAM:%s disk:%s" "$cpu" "$ram" "$disk"
