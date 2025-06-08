# Multi-VLAN Network Configuration with Open vSwitch and Mininet

This repository contains the implementation of a university-level networking project focused on VLAN segmentation, trunking, and inter-VLAN routing using two approaches:

1. Manual configuration using Linux Network Namespaces and Open vSwitch (OVS) CLI tools.
2. An automated, scalable setup using the Mininet network emulator and Python scripting.

## Features

* **VLAN Segmentation:** Logical separation of hosts into isolated broadcast domains.
* **Inter-VLAN Routing:** Configuration of a virtual router to enable communication between VLANs.
* **Open vSwitch Integration:** Use of `ovs-vsctl` to configure access and trunk ports.
* **Dynamic Topology Generation:** A parameterized Python script to generate Mininet topologies based on user-defined VLANs and switch counts.
* **Network Namespaces:** Isolation of hosts and routers using Linux network namespaces to simulate real-world devices.

## Repository Structure

```
.
├── openvswitch-setup/
│   ├── start.sh          # Script to build the manual network topology
│   └── remove_config.sh  # Script to clean up and reset the environment
│
└── mininet-topology/
    └── arbitrary_vlan_topology.py  # Python script for automated Mininet topology
```

## Manual Setup Using Open vSwitch and Namespaces

This setup manually configures a network topology that includes:

* Three OVS bridges: `br-access1`, `br-access2`, and `br-core`
* Four hosts in different VLANs:

  * h1 and h2 in VLAN 10
  * h3 and h4 in VLAN 20
* One router namespace configured with sub-interfaces for inter-VLAN routing

### IP Configuration

| Host | VLAN | IP Address     |
| ---- | ---- | -------------- |
| h1   | 10   | 10.0.10.250/24 |
| h2   | 10   | 10.0.10.251/24 |
| h3   | 20   | 10.0.20.250/24 |
| h4   | 20   | 10.0.20.251/24 |

Router interfaces:

* `10.0.10.1` (gateway for VLAN 10)
* `10.0.20.1` (gateway for VLAN 20)

### Usage

```bash
cd openvswitch-setup
sudo ./start.sh        # Set up the network
sudo ip netns exec h1 ping 10.0.20.250   # Example connectivity test
sudo ./remove_config.sh   # Clean up configuration
```

## Mininet-Based Dynamic VLAN Topology

This approach uses a Python script to programmatically create a VLAN-enabled network topology using Mininet and OVS.

### Prerequisites

* Python 3
* Mininet

### Script Features

* Customizable VLAN list
* Adjustable number of access switches
* Automatic assignment of VLAN-tagged ports and trunk ports
* Realistic emulation environment for testing

### Usage

```bash
cd mininet-topology
sudo python arbitrary_vlan_topology.py
```

You will be presented with the Mininet CLI for interaction. Examples:

```bash
mininet> h10_1 ping h20_1      # Inter-VLAN communication
mininet> h10_1 ping h10_2      # Intra-VLAN communication
mininet> sh s0 ovs-vsctl show # Inspect switch configuration
mininet> exit                  # Exit and clean up
```

### Customization

To modify the VLANs and number of switches:

```python
def run():
    vlans = [10, 20, 50, 60]
    num_access_switches = 2
    ...
```

## Concepts Covered

* Layer 2 Switching
* VLAN Tagging (802.1Q)
* Trunk and Access Ports
* Inter-VLAN Routing
* Linux Network Namespaces
* Software-Defined Networking with Open vSwitch
* Network Emulation with Mininet


