#!/usr/bin/python
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Node
from mininet.log import setLogLevel, info
from mininet.cli import CLI

class LinuxRouter(Node):
    def config(self, vlans=None, **params):
        super(LinuxRouter, self).config(**params)
        self.cmd('sysctl net.ipv4.ip_forward=1')
        self.cmd('ip link set r1-eth1 up')
        if vlans is None:
            vlans = []
        for vlan in vlans:
            self.cmd(f'ip link add link r1-eth1 name r1-eth1.{vlan} type vlan id {vlan}')
            self.cmd(f'ip addr add 10.0.{vlan}.1/24 dev r1-eth1.{vlan}')
            self.cmd(f'ip link set r1-eth1.{vlan} up')

    def terminate(self):
        self.cmd('sysctl net.ipv4.ip_forward=0')
        self.cmd('ip -d link show type vlan | grep vlan | cut -d: -f2 | awk "{print \\"ip link delete \\" $1}" | bash')
        super(LinuxRouter, self).terminate()

class NetworkTopo(Topo):
    def build(self, vlan_list=None, num_switches=4, **_opts):
        if vlan_list is None:
            vlan_list = [10, 20, 30,40]

        r1 = self.addHost('r1', cls=LinuxRouter, vlans=vlan_list)
        s0 = self.addSwitch('s0', failMode='standalone')
        self.addLink(s0, r1, intfName2='r1-eth1')

        access_switches = []
        for i in range(num_switches):
            sw = self.addSwitch(f's{i+1}', failMode='standalone')
            access_switches.append(sw)
            self.addLink(s0, sw)

        self.host_links = []  # to store (host_name, switch_name, vlan)
        for vlan in vlan_list:
            for j in range(2):  # Two hosts per VLAN
                host_name = f'h{vlan}_{j+1}'
                ip = f'10.0.{vlan}.{100 + j}/24'
                default_route = f'via 10.0.{vlan}.1'

                sw_index = (vlan + j) % num_switches
                switch = access_switches[sw_index]

                host = self.addHost(host_name, ip=ip, defaultRoute=default_route)
                self.addLink(host, switch)
                self.host_links.append((host_name, f's{sw_index + 1}', vlan))

def run():
    vlans = [10, 20, 30, 40]
    num_access_switches = 4

    topo = NetworkTopo(vlan_list=vlans, num_switches=num_access_switches)
    net = Mininet(topo=topo, controller=None)
    net.start()

    s0 = net.get('s0')

    # Set trunking on central switch s0
    for i in range(num_access_switches):
        sw = net.get(f's{i+1}')
        link = s0.connectionsTo(sw)
        if link:
            trunk_port = link[0][0].name  # s0's interface
            s0.cmd(f'ovs-vsctl set Port {trunk_port} trunks={",".join(map(str, vlans))}')

    # Set access port tags on edge switches
    for host_name, switch_name, vlan in topo.host_links:
        host = net.get(host_name)
        sw = net.get(switch_name)
        link = host.connectionsTo(sw)
        if link:
            sw_port = link[0][1].name  # switch-side interface
            sw.cmd(f'ovs-vsctl set Port {sw_port} tag={vlan}')

    r1 = net.get('r1')
    info('*** Router interfaces:\n')
    info(r1.cmd('ip addr show'))

    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel('info')
    run()

