#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <subnet>"
  exit 1
fi

subnet="$1"

# Generate IP addresses within the subnet and perform Nmap scan
generate_ips() {
  subnet="$1"
  IFS='/' read -r ip range <<< "$subnet"
  ip_range=$(ipcalc -n "$subnet" | awk -F'=' '{print $2}')
  ipcalc -s "$subnet" | awk -v ip_range="$ip_range" '{if ($2 != ip_range) print $2}'
}

generate_ips "$subnet" | xargs -P0 -I{} nmap -T4 -p- -oG - {} | awk '/^Host:/{ip=$2} /^open/{print ip, $3}'
