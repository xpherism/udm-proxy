#!/bin/sh

## configuration variables: (must match your network create in UI, remember to disable dhcp)
VLAN=5
IPV4_IP_PROXY="10.0.5.4"
IPV4_GW="10.0.5.1"


SCRIPTPATH="$(realpath "$0")"
SCRIPTNAME="$(basename "${SCRIPTPATH%.*}")"
CONTAINER_CNI_PATH="${SCRIPTPATH%/*/*}/etc/cni/net.d/$SCRIPTNAME.conflist"
CONTAINER_NAME=proxy

## network configuration and startup:
CNI_PATH=/mnt/data/podman/cni
if [ ! -f "$CNI_PATH"/macvlan ]; then
  mkdir -p $CNI_PATH
  curl -L https://github.com/containernetworking/plugins/releases/download/v0.9.0/cni-plugins-linux-arm64-v0.9.0.tgz | tar -xz -C $CNI_PATH
fi

mkdir -p "$(dirname "$CONTAINER_CNI_PATH")"

echo "
{
  \"cniVersion\": \"0.4.0\",
  \"name\": \"proxy\",
  \"plugins\": [
    {
      \"type\": \"macvlan\",
      \"mode\": \"bridge\",
      \"master\": \"br$VLAN\",
      \"ipam\": {
        \"type\": \"static\",
        \"addresses\": [
          {
            \"address\": \"$IPV4_IP_PROXY/24\",
            \"gateway\": \"$IPV4_GW\"
          }
        ],
        \"routes\": [
          {\"dst\": \"0.0.0.0/0\"}
        ]
      }
    }
  ]
}
" > "$CONTAINER_CNI_PATH"

ln -fs "$CONTAINER_CNI_PATH" "/etc/cni/net.d/$(basename "$CONTAINER_CNI_PATH")"

# set VLAN bridge promiscuous
ip link set br${VLAN} promisc on

# create macvlan bridge and add IPv4 IP
ip link add br${VLAN}.mac link br${VLAN} type macvlan mode bridge
ip addr add ${IPV4_GW}/24 dev br${VLAN}.mac noprefixroute

# set macvlan bridge promiscuous and bring it up
ip link set br${VLAN}.mac promisc on
ip link set br${VLAN}.mac up

#######################################################################################
# add IPv4 route to container
ip route add ${IPV4_IP_PROXY}/32 dev br${VLAN}.mac
#######################################################################################


#######################################################################################
if podman container exists ${CONTAINER_NAME}; then
  podman start ${CONTAINER_NAME}
else
  logger -s -t podman-proxy -p ERROR Container $CONTAINER_NAME not found, make sure you set the proper name, you can ignore this error if it is your first time setting it up
fi
#######################################################################################