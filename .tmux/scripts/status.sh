#!/bin/sh
# All-in-one status bar script — atomic update, no desync
cpu=$(top -bn1 | grep 'Cpu(s)' | awk '{printf "%3.0f%%", $2+$4}')
ram=$(free | awk '/Mem/{printf "%3.0f%%", $3/$2*100}')
disk=$(df -h / | awk 'NR==2{gsub(/%/,"",$5); printf "%3d%%", $5}')

# Net speed (delta from last call)
NET_FILE="/tmp/tmux-net-speed-$$"
rx_now=$(cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null || echo 0)
tx_now=$(cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null || echo 0)
now=$(date +%s)

if [ -f /tmp/tmux-net-status ]; then
    read old_time old_rx old_tx < /tmp/tmux-net-status
    elapsed=$((now - old_time))
    if [ "$elapsed" -gt 0 ]; then
        rx_rate=$(( (rx_now - old_rx) / elapsed ))
        tx_rate=$(( (tx_now - old_tx) / elapsed ))
    else
        rx_rate=0
        tx_rate=0
    fi
else
    rx_rate=0
    tx_rate=0
fi
echo "$now $rx_now $tx_now" > /tmp/tmux-net-status

format_speed() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        echo "$((bytes / 1048576)) MB/s"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$((bytes / 1024)) KB/s"
    else
        echo "${bytes} B/s"
    fi
}

dl=$(format_speed $rx_rate)
ul=$(format_speed $tx_rate)

printf "CPU:%s RAM:%s D:%8s U:%8s disk:%s" "$cpu" "$ram" "$dl" "$ul" "$disk"
