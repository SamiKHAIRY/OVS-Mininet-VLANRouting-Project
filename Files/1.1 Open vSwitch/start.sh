\#!/bin/bash

# Clean up from any previous run

echo "🧹 Cleaning up previous run..."
ip netns del h1 2>/dev/null
ip netns del h2 2>/dev/null
ip netns del h3 2>/dev/null
ip netns del h4 2>/dev/null
ip netns del router 2>/dev/null

ovs-vsctl --if-exists del-br br-access1
ovs-vsctl --if-exists del-br br-access2
ovs-vsctl --if-exists del-br br-core

# Create namespaces

echo "📦 Creating network namespaces..."
ip netns add h1
ip netns add h2
ip netns add h3
ip netns add h4
ip netns add router

# Create OVS bridges

echo "🌉 Creating OVS Switches..."
ovs-vsctl add-br br-access1
ovs-vsctl add-br br-access2
ovs-vsctl add-br br-core

# --- Host h1 ---

echo "🔌 Connecting h1..."
ip link add h1-eth0 type veth peer name h1-ovs
ip link set h1-eth0 netns h1
ip netns exec h1 ip addr add 10.0.10.250/24 dev h1-eth0
ip netns exec h1 ip link set h1-eth0 up
ip netns exec h1 ip link set lo up
ovs-vsctl add-port br-access1 h1-ovs tag=10
ip link set h1-ovs up

# --- Host h2 ---

echo "🔌 Connecting h2..."
ip link add h2-eth0 type veth peer name h2-ovs
ip link set h2-eth0 netns h2
ip netns exec h2 ip addr add 10.0.10.251/24 dev h2-eth0
ip netns exec h2 ip link set h2-eth0 up
ip netns exec h2 ip link set lo up
ovs-vsctl add-port br-access2 h2-ovs tag=10
ip link set h2-ovs up

# --- Host h3 ---

echo "🔌 Connecting h3..."
ip link add h3-eth0 type veth peer name h3-ovs
ip link set h3-eth0 netns h3
ip netns exec h3 ip addr add 10.0.20.250/24 dev h3-eth0
ip netns exec h3 ip link set h3-eth0 up
ip netns exec h3 ip link set lo up
ovs-vsctl add-port br-access1 h3-ovs tag=20
ip link set h3-ovs up

# --- Host h4 ---

echo "🔌 Connecting h4..."
ip link add h4-eth0 type veth peer name h4-ovs
ip link set h4-eth0 netns h4
ip netns exec h4 ip addr add 10.0.20.251/24 dev h4-eth0
ip netns exec h4 ip link set h4-eth0 up
ip netns exec h4 ip link set lo up
ovs-vsctl add-port br-access2 h4-ovs tag=20
ip link set h4-ovs up

# --- Trunk Access1 <-> Core ---

echo "🔗 Connecting br-access1 to br-core..."
ip link add access1-core type veth peer name core-access1
ovs-vsctl add-port br-access1 access1-core
ovs-vsctl set port access1-core trunks=10,20
ovs-vsctl add-port br-core core-access1
ovs-vsctl set port core-access1 trunks=10,20
ip link set access1-core up
ip link set core-access1 up

# --- Trunk Access2 <-> Core ---

echo "🔗 Connecting br-access2 to br-core..."
ip link add access2-core type veth peer name core-access2
ovs-vsctl add-port br-access2 access2-core
ovs-vsctl set port access2-core trunks=10,20
ovs-vsctl add-port br-core core-access2
ovs-vsctl set port core-access2 trunks=10,20
ip link set access2-core up
ip link set core-access2 up

# --- Router to Core ---

echo "📡 Connecting router to br-core..."
ip link add router-core type veth peer name core-router
ip link set router-core netns router
ovs-vsctl add-port br-core core-router
ovs-vsctl set port core-router trunks=10,20
ip link set core-router up

# Inside router namespace

ip netns exec router ip link set lo up
ip netns exec router ip link set router-core up

# VLAN subinterfaces on router side

echo "🛠️  Configuring VLAN subinterfaces on router..."
ip netns exec router ip link add link router-core name router-core.10 type vlan id 10
ip netns exec router ip link add link router-core name router-core.20 type vlan id 20

ip netns exec router ip addr add 10.0.10.1/24 dev router-core.10
ip netns exec router ip addr add 10.0.20.1/24 dev router-core.20

ip netns exec router ip link set router-core.10 up
ip netns exec router ip link set router-core.20 up

# Enable IP forwarding on router

echo "🚀 Enabling IP forwarding on router..."
ip netns exec router sysctl -w net.ipv4.ip\_forward=1 >/dev/null

# Default gateways for hosts

echo "📬 Setting default gateways for hosts..."
ip netns exec h1 ip route add default via 10.0.10.1
ip netns exec h2 ip route add default via 10.0.10.1
ip netns exec h3 ip route add default via 10.0.20.1
ip netns exec h4 ip route add default via 10.0.20.1

echo "🌐 Moving ens33 IP to br-core and requesting DHCP..."

# Remove IP from ens33

ip addr flush dev ens33

# Add ens33 as a port to br-core

ovs-vsctl add-port br-core ens33
ip link set ens33 up

# Bring up br-core and request IP via DHCP

ip link set br-core up
dhclient br-core

echo "📡 br-core should now have internet via DHCP from ens33."

# Set up /etc/hosts for DNS inside namespaces

echo "🧾 Setting up /etc/hosts for namespace DNS resolution..."
mkdir -p /etc/netns/h1 /etc/netns/h2 /etc/netns/h3 /etc/netns/h4 /etc/netns/router

cat <<EOF > /etc/netns-template-hosts
10.0.10.250 h1
10.0.10.251 h2
10.0.20.250 h3
10.0.20.251 h4
EOF

cp /etc/netns-template-hosts /etc/netns/h1/hosts
cp /etc/netns-template-hosts /etc/netns/h2/hosts
cp /etc/netns-template-hosts /etc/netns/h3/hosts
cp /etc/netns-template-hosts /etc/netns/h4/hosts
cp /etc/netns-template-hosts /etc/netns/router/hosts
rm /etc/netns-template-hosts
echo "adding route to the hosts"

echo "✅ Setup complete. You can now ping across VLANs and use hostnames inside namespaces!"
