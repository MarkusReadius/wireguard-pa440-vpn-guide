#!/bin/bash

# Script to generate WireGuard keys and configurations for all sites
# Usage: ./generate-wireguard-config.sh [HQ_WAN_IP] [SITE1_WAN_IP] [SITE2_WAN_IP] [SITE3_WAN_IP]

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 [HQ_WAN_IP] [SITE1_WAN_IP] [SITE2_WAN_IP] [SITE3_WAN_IP]"
    exit 1
fi

HQ_WAN_IP=$1
SITE1_WAN_IP=$2
SITE2_WAN_IP=$3
SITE3_WAN_IP=$4

# Create keys directory
mkdir -p keys

# Generate keys for each site
for site in hq site1 site2 site3; do
    wg genkey | tee keys/${site}_private.key | wg pubkey > keys/${site}_public.key
    chmod 600 keys/${site}_private.key
done

# Read keys into variables
HQ_PRIVATE=$(cat keys/hq_private.key)
HQ_PUBLIC=$(cat keys/hq_public.key)
SITE1_PRIVATE=$(cat keys/site1_private.key)
SITE1_PUBLIC=$(cat keys/site1_public.key)
SITE2_PRIVATE=$(cat keys/site2_private.key)
SITE2_PUBLIC=$(cat keys/site2_public.key)
SITE3_PRIVATE=$(cat keys/site3_private.key)
SITE3_PUBLIC=$(cat keys/site3_public.key)

# Function to create WireGuard config
create_config() {
    local site=$1
    local private_key=$2
    local template_path="../config-templates/wireguard/wg0-${site}.conf"
    local output_path="wg0-${site}.conf"

    # Create config from template
    cp "$template_path" "$output_path"

    # Replace placeholders with actual values
    sed -i "s/\[${site^^}_PRIVATE_KEY\]/$private_key/" "$output_path"
    sed -i "s/\[HQ_PUBLIC_KEY\]/$HQ_PUBLIC/" "$output_path"
    sed -i "s/\[SITE1_PUBLIC_KEY\]/$SITE1_PUBLIC/" "$output_path"
    sed -i "s/\[SITE2_PUBLIC_KEY\]/$SITE2_PUBLIC/" "$output_path"
    sed -i "s/\[SITE3_PUBLIC_KEY\]/$SITE3_PUBLIC/" "$output_path"
    
    sed -i "s/\[HQ_PUBLIC_IP\]/$HQ_WAN_IP/" "$output_path"
    sed -i "s/\[SITE1_PUBLIC_IP\]/$SITE1_WAN_IP/" "$output_path"
    sed -i "s/\[SITE2_PUBLIC_IP\]/$SITE2_WAN_IP/" "$output_path"
    sed -i "s/\[SITE3_PUBLIC_IP\]/$SITE3_WAN_IP/" "$output_path"
}

# Create configs for each site
create_config "hq" "$HQ_PRIVATE"
create_config "site1" "$SITE1_PRIVATE"
create_config "site2" "$SITE2_PRIVATE"
create_config "site3" "$SITE3_PRIVATE"

echo "WireGuard configurations have been generated:"
echo "--------------------------------------------"
echo "Keys are stored in the 'keys' directory"
echo "Configuration files:"
echo "- wg0-hq.conf"
echo "- wg0-site1.conf"
echo "- wg0-site2.conf"
echo "- wg0-site3.conf"
echo ""
echo "Public Keys for PA-440 Configuration:"
echo "------------------------------------"
echo "HQ: $HQ_PUBLIC"
echo "Site 1: $SITE1_PUBLIC"
echo "Site 2: $SITE2_PUBLIC"
echo "Site 3: $SITE3_PUBLIC"
