#!/bin/bash

echo "🧹 Starting cleanup with sudo..."

# Delete network namespaces
sudo ip netns del h1 2>/dev/null && echo "❌ Deleted namespace: h1"
sudo ip netns del h2 2>/dev/null && echo "❌ Deleted namespace: h2"
sudo ip netns del h3 2>/dev/null && echo "❌ Deleted namespace: h3"
sudo ip netns del h4 2>/dev/null && echo "❌ Deleted namespace: h4"
sudo ip netns del router 2>/dev/null && echo "❌ Deleted namespace: router"

# Delete Open vSwitch bridges
sudo ovs-vsctl --if-exists del-br br-access1 && echo "❌ Deleted OVS bridge: br-access1"
sudo ovs-vsctl --if-exists del-br br-access2 && echo "❌ Deleted OVS bridge: br-access2"
sudo ovs-vsctl --if-exists del-br br-core && echo "❌ Deleted OVS bridge: br-core"

# Remove ens33 from br-core if it's part of it
if sudo ovs-vsctl list-ports br-core 2>/dev/null | grep -q ens33; then
    sudo ovs-vsctl del-port br-core ens33
    echo "🔌 Removed ens33 from br-core"
fi

# Restore ens33 to standalone mode and get a fresh IP
sudo ip link set ens33 up
sudo dhclient -r ens33 2>/dev/null
sudo dhclient ens33
echo "🔄 Restored IP on ens33 using DHCP"

# Remove known leftover veth interfaces
sudo ip link del h1-ovs 2>/dev/null && echo "🧹 Removed interface: h1-ovs"
sudo ip link del h2-ovs 2>/dev/null && echo "🧹 Removed interface: h2-ovs"
sudo ip link del h3-ovs 2>/dev/null && echo "🧹 Removed interface: h3-ovs"
sudo ip link del h4-ovs 2>/dev/null && echo "🧹 Removed interface: h4-ovs"

sudo ip link del access1-core 2>/dev/null && echo "🧹 Removed interface: access1-core"
sudo ip link del access2-core 2>/dev/null && echo "🧹 Removed interface: access2-core"
sudo ip link del core-access1 2>/dev/null && echo "🧹 Removed interface: core-access1"
sudo ip link del core-access2 2>/dev/null && echo "🧹 Removed interface: core-access2"
sudo ip link del core-router 2>/dev/null && echo "🧹 Removed interface: core-router"

echo "✅ Cleanup complete."
