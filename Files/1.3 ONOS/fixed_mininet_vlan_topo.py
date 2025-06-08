#!/usr/bin/python
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import Node, RemoteController
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
        self.cmd('ip -d link show type vlan | grep vlan | cut -d: -f2 | awk "{print \"ip link delete \" $1}" | bash')
        super(LinuxRouter, self).terminate()

class NetworkTopo(Topo):
    def build(self, vlan_list=None, **_opts):
        if vlan_list is None:
            vlan_list = [10, 20, 30]

        r1 = self.addHost('r1', cls=LinuxRouter, vlans=vlan_list)
        s0 = self.addSwitch('s0', failMode='secure')

        self.addLink(s0, r1, intfName2='r1-eth1')

        for i, vlan in enumerate(vlan_list):
            s = self.addSwitch(f's{i+1}', failMode='secure')
            self.addLink(s0, s)
            for j in range(2):  # 2 hosts per VLAN
                host = self.addHost(f'h{vlan}_{j+1}',
                                    ip=f'10.0.{vlan}.{100+j}/24',
                                    defaultRoute=f'via 10.0.{vlan}.1')
                self.addLink(host, s)

def run():
    vlans = [10, 20, 30, 40]  # Define arbitrary VLANs here
    topo = NetworkTopo(vlan_list=vlans)
    net = Mininet(topo=topo, controller=lambda name: RemoteController(name, ip='172.17.0.2', port=6653))
    net.start()

    s0 = net.get('s0')

    # Ensure trunk to router on s0-eth1 (first interface connected to r1)
    s0.cmd('ovs-vsctl set Port s0-eth1 trunks={}'.format(','.join(map(str, vlans))))

    for i, vlan in enumerate(vlans):
        s0.cmd(f'ovs-vsctl set Port s0-eth{i+2} trunks={",".join(map(str, vlans))}')
        sw = net.get(f's{i+1}')
        sw.cmd(f'ovs-vsctl set Port s{i+1}-eth1 trunks={",".join(map(str, vlans))}')
        sw.cmd(f'ovs-vsctl set Port s{i+1}-eth2 tag={vlan}')
        sw.cmd(f'ovs-vsctl set Port s{i+1}-eth3 tag={vlan}')

    r1 = net.get('r1')
    info('*** Router interfaces:\n')
    info(r1.cmd('ip addr show'))

    CLI(net)
    net.stop()

if __name__ == '__main__':
    setLogLevel('info')
    run()
