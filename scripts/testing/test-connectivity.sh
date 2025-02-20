#!/bin/bash

# Script to test WireGuard VPN connectivity between all sites
# Usage: ./test-connectivity.sh

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Site configurations
declare -A SITES=(
    ["HQ"]="10.83.40.254"
    ["Site1"]="10.83.10.254"
    ["Site2"]="10.83.20.254"
    ["Site3"]="10.83.30.254"
)

declare -A NETWORKS=(
    ["HQ"]="10.83.40.0/24"
    ["Site1"]="10.83.10.0/24"
    ["Site2"]="10.83.20.0/24"
    ["Site3"]="10.83.30.0/24"
)

# Function to check if WireGuard is running
check_wireguard() {
    echo -e "${YELLOW}Checking WireGuard Status...${NC}"
    if ! command -v wg &> /dev/null; then
        echo -e "${RED}WireGuard is not installed!${NC}"
        exit 1
    fi

    if ! ip a show wg0 &> /dev/null; then
        echo -e "${RED}WireGuard interface wg0 is not available!${NC}"
        exit 1
    fi

    echo -e "${GREEN}WireGuard is running.${NC}"
    echo "--------------------"
    wg show
    echo "--------------------"
}

# Function to test ping
test_ping() {
    local target=$1
    local count=4
    local success=0
    
    echo -n "Pinging $target... "
    if ping -c $count -W 2 $target &> /dev/null; then
        echo -e "${GREEN}Success${NC}"
        return 0
    else
        echo -e "${RED}Failed${NC}"
        return 1
    fi
}

# Function to test bandwidth using iperf3
test_bandwidth() {
    local target=$1
    local duration=10
    
    echo -n "Testing bandwidth to $target... "
    if iperf3 -c $target -t $duration -J &> /dev/null; then
        echo -e "${GREEN}Success${NC}"
        return 0
    else
        echo -e "${RED}Failed${NC}"
        return 1
    fi
}

# Function to check routing
check_routing() {
    local target=$1
    echo -n "Checking route to $target... "
    if ip route get $target &> /dev/null; then
        echo -e "${GREEN}Route exists${NC}"
        ip route get $target
        return 0
    else
        echo -e "${RED}No route found${NC}"
        return 1
    fi
}

# Main testing sequence
echo "=== WireGuard VPN Connectivity Test ==="
echo "Starting tests at $(date)"
echo

# Check WireGuard status
check_wireguard

# Test connectivity to each site
echo -e "\n${YELLOW}Testing Site Connectivity:${NC}"
for site in "${!SITES[@]}"; do
    echo -e "\nTesting connectivity to $site (${SITES[$site]}):"
    check_routing "${SITES[$site]}"
    test_ping "${SITES[$site]}"
done

# Test network reachability
echo -e "\n${YELLOW}Testing Network Reachability:${NC}"
for site in "${!NETWORKS[@]}"; do
    echo -e "\nTesting route to $site network (${NETWORKS[$site]}):"
    check_routing "${NETWORKS[$site]}"
done

# Test bandwidth if iperf3 is available
if command -v iperf3 &> /dev/null; then
    echo -e "\n${YELLOW}Testing Bandwidth:${NC}"
    for site in "${!SITES[@]}"; do
        echo -e "\nTesting bandwidth to $site (${SITES[$site]}):"
        test_bandwidth "${SITES[$site]}"
    done
else
    echo -e "\n${YELLOW}iperf3 not installed - skipping bandwidth tests${NC}"
fi

# Check WireGuard interface statistics
echo -e "\n${YELLOW}WireGuard Interface Statistics:${NC}"
wg show all

# Final summary
echo -e "\n${YELLOW}Test Summary:${NC}"
echo "Tests completed at $(date)"
echo "Check the output above for any failed tests marked in red."

# Additional Diagnostics
echo -e "\n${YELLOW}Additional Diagnostics:${NC}"
echo "1. Interface Status:"
ip addr show wg0

echo -e "\n2. Routing Table:"
ip route show

echo -e "\n3. Connection Tracking:"
if command -v conntrack &> /dev/null; then
    conntrack -L -p udp --dport 51820
else
    echo "conntrack not installed"
fi

echo -e "\n4. System Logs (last 10 WireGuard entries):"
journalctl -u wg-quick@wg0 -n 10 --no-pager

echo -e "\n${GREEN}Testing completed.${NC}"
