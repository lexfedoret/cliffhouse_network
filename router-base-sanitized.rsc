# MikroTik Router Configuration Script
# RouterOS Configuration File - Base Version
# Date: [DATE]
# 
# CONFIGURATION SEQUENCE - Apply in this exact order:
# 1. router-base-sanitized.rsc         (this file - core router & CAPsMAN setup)
# 2. router-base-mtu-sanitized.rsc     (MTU optimization for performance)
# 3. router-base-steering-sanitized.rsc (WiFi band steering for provisioned CAP AX devices)
# 4. router-failover-sanitized.rsc     (advanced WAN failover & monitoring)
# 5. router-firewall-sanitized.rsc     (comprehensive security rules)
#
# This base configuration provides:
# - Core router functionality with VLAN support
# - CAPsMAN controller for CAP AX device management
# - Basic connectivity and DHCP services
# - Foundation for additional feature modules

# =====================================
# system configuration
# =====================================

# set admin password (works with normal reset, for no-defaults reset create user manually first)
/user set admin password="CHANGE_THIS_PASSWORD"
/system identity set name="router-main"
/system clock set time-zone-name=America/New_York

# configure dns servers (public DNS servers) and enable DNS relay
/ip dns set servers=8.8.8.8,8.8.4.4,1.1.1.1

# =====================================
# interface configuration
# =====================================

# create main bridge with vlan filtering and spanning tree
/interface bridge add name=br1 vlan-filtering=yes protocol-mode=rstp

# =====================================
# vlan interface creation
# =====================================

/interface vlan
add name=vlan1 interface=br1 vlan-id=1 comment="vlan_mgmt"
add name=vlan2 interface=br1 vlan-id=2 comment="vlan_infra"
add name=vlan3 interface=br1 vlan-id=3 comment="vlan_data"
add name=vlan4 interface=br1 vlan-id=4 comment="vlan_guest"

# =====================================
# ip address configuration
# =====================================

/ip address
add address=192.168.254.254/24 interface=vlan1 comment="ip_vlan_mgmt"
add address=192.168.255.1/24 interface=vlan2 comment="ip_vlan_infra"
add address=172.16.250.1/23 interface=vlan3 comment="ip_vlan_data"
add address=172.16.252.1/23 interface=vlan4 comment="ip_vlan_guest"

# =====================================
# dhcp pools and servers
# =====================================

/ip pool
add name=dhcp_pool1 ranges=192.168.254.10-192.168.254.240
add name=dhcp_pool2 ranges=192.168.255.10-192.168.255.240
add name=dhcp_pool3 ranges=172.16.250.10-172.16.251.240
add name=dhcp_pool4 ranges=172.16.252.10-172.16.253.240

/ip dhcp-server
add name=dhcp1 interface=vlan1 address-pool=dhcp_pool1 lease-time=365d
add name=dhcp2 interface=vlan2 address-pool=dhcp_pool2 lease-time=365d
add name=dhcp3 interface=vlan3 address-pool=dhcp_pool3 lease-time=7d
add name=dhcp4 interface=vlan4 address-pool=dhcp_pool4 lease-time=7d

/ip dhcp-server network
add address=192.168.254.0/24 gateway=192.168.254.254 dns-server=8.8.8.8,8.8.4.4,1.1.1.1
add address=192.168.255.0/24 gateway=192.168.255.1 dns-server=8.8.8.8,8.8.4.4,1.1.1.1
add address=172.16.250.0/23 gateway=172.16.250.1 dns-server=8.8.8.8,8.8.4.4,1.1.1.1
add address=172.16.252.0/23 gateway=172.16.252.1 dns-server=8.8.8.8,8.8.4.4,1.1.1.1

# configure 2.5g interface as primary wan
/interface ethernet set ether5 comment="->wan"

# configure dhcp client for primary wan
/ip dhcp-client add interface=ether5 disabled=no comment="wan_dhcp_client"

# =====================================
# bridge port configuration 
# =====================================

# add ethernet ports to bridge with actual device assignments
/interface bridge port
add bridge=br1 interface=ether1 comment="->device1" pvid=2
add bridge=br1 interface=ether2 comment="->device2" pvid=2  
add bridge=br1 interface=ether3 comment="->device3" pvid=2
add bridge=br1 interface=ether4 comment="->backhaul->caps" frame-types=admit-only-vlan-tagged

# =====================================
# bridge vlan configuration
# =====================================

/interface bridge vlan
add bridge=br1 vlan-ids=1 tagged=br1,ether4 untagged="" 
add bridge=br1 vlan-ids=2 tagged=br1,ether4 untagged=ether1,ether2,ether3 
add bridge=br1 vlan-ids=3 tagged=br1,ether4 untagged="" 
add bridge=br1 vlan-ids=4 tagged=br1,ether4 untagged="" 

# =====================================
# capsman wi-fi 6 configuration (routeros 7.x)
# =====================================

# enable capsman manager
/interface wifi capsman set ca-certificate=auto certificate=auto enabled=yes interfaces=vlan1  package-path="" require-peer-certificate=no upgrade-policy=require-same-version

# create capsman security configurations
/interface wifi security
add name=sec-mgmt authentication-types=wpa3-psk passphrase="MGMT_WIFI_PASSWORD"
add name=sec-infra authentication-types=wpa2-psk,wpa3-psk passphrase="INFRA_WIFI_PASSWORD"
add name=sec-data authentication-types=wpa2-psk,wpa3-psk passphrase="DATA_WIFI_PASSWORD"
add name=sec-alterdata authentication-types=wpa3-psk passphrase="ALTERDATA_WIFI_PASSWORD"
add name=sec-guest authentication-types=wpa2-psk,wpa3-psk passphrase="GUEST_WIFI_PASSWORD"

# create capsman channel configurations
/interface wifi channel
add name=2ghz-channels band=2ghz-ax width=20/40mhz 
add name=5ghz-channels band=5ghz-ax width=20/40/80mhz skip-dfs-channels=10min-cac 

# create capsman datapath configurations (for VLAN assignment and local forwarding)
/interface wifi datapath
add name=mgmt-datapath vlan-id=1 bridge=br1
add name=infra-datapath vlan-id=2 bridge=br1
add name=data-datapath vlan-id=3 bridge=br1
add name=guest-datapath vlan-id=4 bridge=br1

# create capsman configurations for all networks
/interface wifi configuration
# 2.4GHz networks
add name=infra-2ghz ssid="network-infra" security=sec-infra datapath=infra-datapath channel=2ghz-channels hide-ssid=yes country="YOUR_COUNTRY"
add name=data-2ghz ssid="network-data" security=sec-data datapath=data-datapath channel=2ghz-channels hide-ssid=no country="YOUR_COUNTRY"
add name=guest-2ghz ssid="network-guest" security=sec-guest datapath=guest-datapath channel=2ghz-channels hide-ssid=no country="YOUR_COUNTRY"

# 5GHz networks  
add name=mgmt-5ghz ssid="network-mgmt" security=sec-mgmt datapath=mgmt-datapath channel=5ghz-channels hide-ssid=yes country="YOUR_COUNTRY"
add name=alterdata-5ghz ssid="network-alterdata" security=sec-alterdata datapath=data-datapath channel=5ghz-channels hide-ssid=no country="YOUR_COUNTRY"

# create capsman provisioning rules (for CAP ax devices to auto-discover)
/interface wifi provisioning
# provision 2.4GHz radios with multiple SSIDs
add action=create-dynamic-enabled supported-bands=2ghz-ax master-configuration=infra-2ghz slave-configurations=data-2ghz,guest-2ghz comment="auto-provision 2.4ghz radios"

# provision 5GHz radios with multiple SSIDs
add action=create-dynamic-enabled supported-bands=5ghz-ax master-configuration=mgmt-5ghz slave-configurations=alterdata-5ghz comment="auto-provision 5ghz radios"

#make router radios CAPs managed
/interface wifi
set wifi1 configuration.manager=capsman disabled=no
set wifi2 configuration.manager=capsman disabled=no

# enable CAPsMAN management for controller's own radios
/interface wifi cap set enabled=yes

# =====================================
# interface lists for wan
# =====================================

/interface list
add name=wan-interfaces comment="all wan interfaces"
add name=lan-interfaces comment="all lan interfaces"

/interface list member
add interface=ether5 list=wan-interfaces comment="primary wan"
add interface=br1 list=lan-interfaces comment="lan bridge"

# =====================================
# nat configuration
# =====================================

/ip firewall nat
add chain=srcnat out-interface-list=wan-interfaces action=masquerade comment="nat for all wan interfaces"

# =====================================
# basic firewall (for advanced rules, use advanced-failover-config.rsc)
# =====================================

/ip firewall filter
add action=accept comment="allow everything" chain=input

# =====================================
# service security
# =====================================

/ip service set www disabled=yes
/ip service set www-ssl address=192.168.254.0/24 disabled=no
/ip service set winbox address=192.168.254.0/24
/ip service set ssh address=192.168.254.0/24
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes

# =====================================
# system services
# =====================================

/system ntp client set enabled=yes servers=pool.ntp.org

# CAP mode enabled above to allow CAPsMAN to manage local radios

# =====================================
# configuration complete
# =====================================

:log info "router-main base configuration applied successfully"
:log info "CAPsMAN controller enabled with auto-provisioning for local and remote radios"
:log info "ether4 configured as backhaul trunk for CAP backhaul"
:log info "bridge and VLAN configuration completed before CAPsMAN"
:log info "network architecture:"
:log info "- VLAN 1 (mgmt): 192.168.254.0/24 - CAPsMAN management"
:log info "- VLAN 2 (infra): 192.168.255.0/24 - infrastructure devices"
:log info "- VLAN 3 (data): 172.16.250.0/23 - user data network"
:log info "- VLAN 4 (guest): 172.16.252.0/23 - guest network"
:log info "CAPsMAN WiFi networks (5 SSIDs):"
:log info "- network-mgmt (5GHz hidden) → VLAN 1"
:log info "- network-infra (2.4GHz hidden) → VLAN 2"
:log info "- network-data (2.4GHz visible) → VLAN 3"
:log info "- network-alterdata (5GHz visible) → VLAN 3"
:log info "- network-guest (2.4GHz visible) → VLAN 4"
:log info "next steps: apply mtu, steering, failover, and firewall configs"
:log info "CAP AX devices will auto-discover via backhaul and extend all networks"