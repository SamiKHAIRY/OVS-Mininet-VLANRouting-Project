## 1. Overview

This project uses Mininet to create a flexible network topology featuring a configurable number of VLANs, with two hosts per VLAN. The topology includes a central router, a core Open vSwitch (OVS), and multiple access OVS switches. Inter-VLAN routing is enabled, allowing full communication between all hosts.

The script `arbitrary_vlan_topology.py` dynamically builds this network and configures OVS switches for VLAN tagging and trunking.

## 2. File

* `arbitrary_vlan_topology.py`: A Python script that defines and runs the Mininet simulation.

## 3. Prerequisites

* Mininet installed (which includes Python support).
* Open vSwitch installed (as the script uses `ovs-vsctl` for switch configuration).
* Python 3.
* `sudo` privileges to run Mininet.

## 4. Topology Created

The script `arbitrary_vlan_topology.py` creates the following components:

* **Router (`r1`):** A Mininet host configured as a Linux router with IP forwarding enabled. It has a VLAN sub-interface for each configured VLAN, acting as the default gateway for hosts in that VLAN.
    * Router parent interface: `r1-eth1`
    * VLAN sub-interface IPs: `10.0.{VLAN_ID}.1/24`
* **Core Switch (`s0`):** An Open vSwitch acting as the central switch. It connects to the router and all access switches via trunk ports.
* **Access Switches (`s1`, `s2`, ...):** A configurable number of Open vSwitches (default is 4). Each access switch connects to the core switch `s0` via a trunk port and to its assigned hosts via access ports.
* **Hosts:** Two hosts are created per configured VLAN (e.g., `h{VLAN_ID}_1`, `h{VLAN_ID}_2`).
    * Host IPs: `10.0.{VLAN_ID}.{100 + host_index}/24` (e.g., `10.0.10.100/24`, `10.0.10.101/24`).
    * Default gateway: `10.0.{VLAN_ID}.1`.
* **VLANs:**
    * By default, VLANs `10, 20, 30, 40` are created. This is configurable in the script.
    * Host-facing switch ports are configured as access ports (tagged with the specific VLAN ID).
    * Inter-switch ports and the switch-router port are configured as trunk ports, carrying all defined VLANs.

## 5. Usage

### 5.1. Running the Script

To start the Mininet simulation, run the Python script with sudo privileges:
```bash
sudo python arbitrary_vlan_topology.py