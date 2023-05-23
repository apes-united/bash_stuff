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

  # Convert IP address to decimal
  IFS='.' read -r -a octets <<< "$ip"
  ip_dec=$(( (octets[0] << 24) + (octets[1] << 16) + (octets[2] << 8) + octets[3] ))

  # Calculate IP range and iterate through IP addresses
  ip_range=$(( 2**(32-range) - 1 ))
  for i in $(seq 1 "$ip_range"); do
    curr_ip_dec=$(( ip_dec + i ))
    curr_ip="$(printf '%d.%d.%d.%d\n' "$(( (curr_ip_dec & 0xFF000000) >> 24 ))" "$(( (curr_ip_dec & 0x00FF0000) >> 16 ))" "$(( (curr_ip_dec & 0x0000FF00) >> 8 ))" "$(( curr_ip_dec & 0x000000FF ))")"
    echo "$curr_ip"
  done
}

generate_ips "$subnet" | xargs -P0 -I{} nmap -T4 -p- -oG - {} | awk '/^Host:/{ip=$2} /^open/{print ip, $3}'
