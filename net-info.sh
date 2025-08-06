#!/bin/bash

# Define colors
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get active interface
ACTIVE_IF=$(ip route | grep '^default' | awk '{print $5}' | head -n1)

# Get private IP info
PRIVATE_IP=$(ip -4 addr show "$ACTIVE_IF" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
SUBNET_CIDR=$(ip -4 addr show "$ACTIVE_IF" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')

# Get public IP
PUBLIC_IP=$(curl -s https://ifconfig.me || curl -s https://icanhazip.com)

# Get network subnet info
NETWORK_BLOCK=$(ip -4 route show dev "$ACTIVE_IF" | grep -oP '(\d+\.){3}\d+/\d+')
IFS='/' read -r NET_ADDR PREFIX <<< "$NETWORK_BLOCK"
# Calculate range:
if command -v sipcalc >/dev/null; then
    RANGE=$(sipcalc "$NETWORK_BLOCK" | grep "Usable range" | awk -F'-' '{print $2}' | xargs)
elif command -v ipcalc >/dev/null; then
    RANGE=$(ipcalc "$NETWORK_BLOCK" | grep -E "HostMin|HostMax" | awk '{print $2}' | xargs | sed 's/ / - /')
else
    RANGE="(Install ipcalc or sipcalc to display range)"
fi

# Get DNS servers
DNS_SERVERS=$(resolvectl status | grep 'DNS Servers' | head -n1 | cut -d: -f2- | xargs)

# Get SSID if Wi-Fi
if [ "$(iw dev 2>/dev/null | grep Interface | awk '{print $2}')" == "$ACTIVE_IF" ]; then
    SSID=$(iw dev "$ACTIVE_IF" info | grep ssid | awk '{print $2}')
else
    SSID="(Not connected to Wi-Fi)"
fi

# What does the interface mean?
IF_DESC=$(if [[ "$ACTIVE_IF" =~ ^wl ]]; then echo "This is your Wi-Fi interface."; elif [[ "$ACTIVE_IF" =~ ^en ]]; then echo "This is your wired Ethernet interface."; else echo "Could not determine type."; fi)

# Display information
echo -e "${CYAN}==== Network Info Summary ====${NC}"
echo -e "${YELLOW}Active Network Interface:${NC} ${GREEN}${ACTIVE_IF}${NC}"
echo -e "${CYAN}$IF_DESC${NC}"
echo -e "${YELLOW}Private IP:${NC} ${GREEN}${PRIVATE_IP}${NC}"
echo -e "${YELLOW}Public IP:${NC} ${GREEN}${PUBLIC_IP}${NC}"
echo -e "${YELLOW}Network Range:${NC} ${GREEN}${NETWORK_BLOCK}${NC} ${CYAN}$RANGE${NC}"
echo -e "${YELLOW}Active DNS Servers:${NC} ${GREEN}${DNS_SERVERS}${NC}"
echo -e "${YELLOW}SSID (if Wi-Fi):${NC} ${GREEN}${SSID}${NC}"
echo -e "${CYAN}=============================${NC}"

