# Project: Open vSwitch VLAN Configuration

## 1. Overview

This project demonstrates the setup of a network topology using Linux network namespaces and Open vSwitch (OVS). It creates four hosts distributed across two VLANs, with a dedicated router to enable inter-VLAN communication. The scripts also attempt to bridge a physical interface (`ens33`) to the core OVS bridge for potential external network access.

## 2. Files

* `start.sh`: A bash script to create and configure the entire network topology, including namespaces, OVS bridges, VLANs, IP addressing, and routing.
* `remove_config.sh`: A bash script to clean up all components created by `start.sh`, restoring the system to its previous state.

## 3. Prerequisites

* Linux operating system.
* `sudo` privileges (scripts must be run with `sudo`).
* Open vSwitch installed and `ovs-vsctl` command available.
* `iproute2` package (for `ip netns`, `ip link`, `ip addr`, `ip route` commands).
* `dhclient` (for DHCP client functionality on `br-core` via `ens33`).

## 4. Topology Created by `start.sh`

* **Network Namespaces:**
    * `h1`, `h2`, `h3`, `h4` (for hosts)
    * `router` (for the router)
* **Open vSwitch Bridges:**
    * `br-access1`: Access switch for h1 and h3.
    * `br-access2`: Access switch for h2 and h4.
    * `br-core`: Core switch connecting `br-access1`, `br-access2`, and the router.
* **VLAN Configuration:**
    * **VLAN 10:**
        * `h1`: IP `10.0.10.250/24` (on `br-access1`)
        * `h2`: IP `10.0.10.251/24` (on `br-access2`)
        * Router interface `router-core.10`: IP `10.0.10.1/24`
    * **VLAN 20:**
        * `h3`: IP `10.0.20.250/24` (on `br-access1`)
        * `h4`: IP `10.0.20.251/24` (on `br-access2`)
        * Router interface `router-core.20`: IP `10.0.20.1/24`
* **Connections:**
    * Hosts connect to their respective access switches (ports are tagged with VLAN ID).
    * Access switches connect to `br-core` via trunk links (allowing VLANs 10 and 20).
    * The router connects to `br-core` via a trunk link.
* **Routing:**
    * IP forwarding is enabled on the `router` namespace.
    * Hosts have default gateways set to the router's corresponding VLAN interface.
* **External Connectivity (Attempted):**
    * The physical interface `ens33` is moved into `br-core`, and `dhclient` is run on `br-core` to obtain an IP address.

## 5. Usage

### 5.1. Setting up the Network

To create the network topology, run the `start.sh` script with sudo privileges:
```bash
sudo ./start.sh