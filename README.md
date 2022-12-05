## Instructions here:

https://pythops.com/post/create-your-own-image-for-jetson-nano-board.html

## Spec:
**Ubuntu release**: 20.04

**BSP**: 32.5.1

## Supported boards:
- [Jetson nano](https://developer.nvidia.com/embedded/jetson-nano-developer-kit)
- [Jetson nano 2GB](https://developer.nvidia.com/embedded/jetson-nano-2gb-developer-kit)

## License
Copyright Badr BADRI @pythops

MIT

# ubuntu-router
Create your own router using Ubuntu and Jetson Nano.

Config:

/etc/network/interfaces
/etc/dhcp/dhcpd.conf
/etc/hostapd/hostapd.conf
/etc/dnsmasq.conf (this is where name servers are hard coded)
/etc/sysctl.conf (net.ipv4.ip_forward = 1)


Services:

service --status-all
sudo systemctl restart dnsmasq
sudo systemctl restart networking
sudo systemctl status hostapd
sudo systemctl restart isc-dhcp-server

Default:

/etc/default/isc-dhcp-server (really the only one used — set to br0 interface)
/etc/default/dnsmasq
/etc/default/hostapd

IPTables:

sudo iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -s 10.0.1.0/24 -o eth0 -j ACCEPT
sudo iptables -A FORWARD -d 10.0.1.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -i eth0 -j ACCEPT

sudo iptables -t nat -S
sudo iptables -S FORWARD

Bridge:

sudo brctl show
sudo brctl addbr br0
sudo brctl addif br0 wlan1

Disabled desktop (gnome):

Services Running:
(Rust) tiny-server

Modified /etc/sudoers 
Warning!! Only use ‘sudo visudo’ to modify the sudoers file

1. Added ‘add_to_br0’ script that ensures wlan1 interface is added to br0 
2. Added family-actix server program as it needs to run as root to sniff packets

Needed to enable dhcp server 
1. Ran ‘sudo systemctl list-unit-files —state=disabled’
2. Found isc-dhcp-server was disabled
3. Ran ‘sudo systemctl enable isc-dhcp-server.service’

Noticed mysql and apache2 services are installed but not running
1. sudo apt-get purge apache2
2. This removed the service for apache2, but not for mysql as it seems mysql was not installed with apt-get

In /etc/rc.local

iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
exit 0

In order to get the bridge (br0) to be up on reboot follow [these](https://www.linode.com/docs/guides/start-service-at-boot/) steps. All other information I came across on the the net was incorrect about creating services that run in order. This is only way that works. Tried 6 different ways for 2 days.

Difficulty with DNS resolution:
1. Tried all of these ‘solutions’ and none worked except chattr
2. Masked /etc/init.d/resolvconf service: sudo systemctl mask resolvconf
3. Deleted /etc/resolv.conf
4. Created new /etc/resolv.conf with desired name servers
    1. nameserver 1.1.1.1
    2. nameserver 8.8.8.8
5. Ran sudo chattr +i /etc/resolv.conf to prevent it from being changed

