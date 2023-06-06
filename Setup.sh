#!/bin/bash

# Configuration file name
config_file="wg0.conf"

# Remote server details
remote_user="username"     # Replace with the actual username
remote_host="remote_host"  # Replace with the actual hostname or IP address

# Function to check if a file exists on a remote machine
remote_file_exists() {
    local file_path=$1
    local ssh_command="if [ -f $file_path ]; then echo 'true'; fi"

    ssh "$remote_user@$remote_host" "$ssh_command"
}

# Check if server configuration file exists on the remote machine
if [[ $(remote_file_exists "/etc/wireguard/$config_file") == "true" ]]; then
    ssh "$remote_user@$remote_host" "rm -rf /etc/wireguard/$config_file"
fi

# Check if client configuration file exists locally
if [ -f "/etc/wireguard/$config_file" ]; then
    sudo rm -rf "/etc/wireguard/$config_file"
fi

# Generate server keys on the remote machine
ssh "$remote_user@$remote_host" "wg genkey | tee /etc/wireguard/server.private | wg pubkey > /etc/wireguard/server.public"

# Generate client keys locally
wg genkey | tee /etc/wireguard/client.private | wg pubkey > /etc/wireguard/client.public

# Generate server configuration file on the remote machine
ssh "$remote_user@$remote_host" "cat << EOF > /etc/wireguard/$config_file
[Interface]
PrivateKey = \$(cat /etc/wireguard/server.private)
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = \$(cat /etc/wireguard/client.public)
AllowedIPs = 10.0.0.2/32
EOF"

# Generate client configuration file locally
cat << EOF > "/etc/wireguard/$config_file"
[Interface]
PrivateKey = $(cat /etc/wireguard/client.private)
Address = 10.0.0.2/24

[Peer]
PublicKey = $(ssh "$remote_user@$remote_host" "cat /etc/wireguard/server.public")
AllowedIPs = 0.0.0.0/0
Endpoint = $remote_host:51820
PersistentKeepalive = 15
EOF

echo "Server configuration file created on the remote machine: /etc/wireguard/$config_file"
echo "Client configuration file saved locally: /etc/wireguard/$config_file"
