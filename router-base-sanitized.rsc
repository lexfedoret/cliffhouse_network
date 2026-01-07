# MikroTik Router Configuration Script
# RouterOS Configuration File - Base Version
# Date: [DATE]
# 
# CONFIGURATION SEQUENCE - Apply in this exact order:
# 1. router-base-sanitized.rsc         (this file - core router & CAPsMAN setup)
# 2. router-base-mtu-sanitized.rsc     (MTU optimization for performance)
# 3. router-base-steering-sanitized.rsc (WiFi band steering for provisioned CAP AX devices)
# 4. router-firewall-sanitized.rsc     (comprehensive security rules)
# 5. router-logging-sanitized.rsc      (logging optimization)
#
# NOTE: WAN failover config planned for future implementation
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
add bridge=br1 interface=ether1 comment="->backhaul->caps" frame-types=admit-only-vlan-tagged
add bridge=br1 interface=ether2 comment="->device1" pvid=2 
add bridge=br1 interface=ether3 comment="->device2" pvid=2
add bridge=br1 interface=ether4 comment="->device3" pvid=2
 

# =====================================
# bridge vlan configuration
# =====================================

/interface bridge vlan
add bridge=br1 vlan-ids=1 tagged=br1,ether1 untagged="" 
add bridge=br1 vlan-ids=2 tagged=br1,ether1 untagged=ether2,ether3,ether4 
add bridge=br1 vlan-ids=3 tagged=br1,ether1 untagged="" 
add bridge=br1 vlan-ids=4 tagged=br1,ether1 untagged="" 

# =====================================
# capsman wi-fi 6 configuration (routeros 7.x)
# =====================================

# enable capsman manager (specify management interface like working example)
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
# Dedicated 2.4GHz channels per location (non-overlapping: 1, 6, 11)
add name=2ghz-ch1 band=2ghz-ax width=20mhz frequency=2412 comment="->cap-roof"
add name=2ghz-ch6 band=2ghz-ax width=20mhz frequency=2437 comment="->router-main"
add name=2ghz-ch11 band=2ghz-ax width=20mhz frequency=2462 comment="->cap-bsmnt"

# 5GHz channel configuration (shared by all APs)
add name=5ghz-channels band=5ghz-ax width=20/40/80mhz skip-dfs-channels=10min-cac 

# create capsman datapath configurations (for VLAN assignment and local forwarding)
/interface wifi datapath
add name=mgmt-datapath vlan-id=1 bridge=br1
add name=infra-datapath vlan-id=2 bridge=br1 client-isolation=yes
add name=data-datapath vlan-id=3 bridge=br1
add name=guest-datapath vlan-id=4 bridge=br1 client-isolation=yes

# create capsman configurations for all networks
# TX Power: Roof/Main 2.4GHz=15dBm, Basement 2.4GHz=20dBm, All 5GHz=20dBm
/interface wifi configuration
# 2.4GHz networks - dedicated channels per location
# TX Power: Roof=15dBm, Main=15dBm, Basement CAP=20dBm (boosted for concrete penetration)
add name=infra-2ghz-roof ssid="network-infra" security=sec-infra datapath=infra-datapath channel=2ghz-ch1 tx-power=15 hide-ssid=yes country="YOUR_COUNTRY" installation=indoor
add name=data-2ghz-roof ssid="network-data" security=sec-data datapath=data-datapath channel=2ghz-ch1 tx-power=15 hide-ssid=no country="YOUR_COUNTRY" installation=indoor
add name=guest-2ghz-roof ssid="network-guest" security=sec-guest datapath=guest-datapath channel=2ghz-ch1 tx-power=15 hide-ssid=no country="YOUR_COUNTRY" installation=indoor

add name=infra-2ghz-main ssid="network-infra" security=sec-infra datapath=infra-datapath channel=2ghz-ch6 tx-power=15 hide-ssid=yes country="YOUR_COUNTRY" installation=indoor
add name=data-2ghz-main ssid="network-data" security=sec-data datapath=data-datapath channel=2ghz-ch6 tx-power=15 hide-ssid=no country="YOUR_COUNTRY" installation=indoor
add name=guest-2ghz-main ssid="network-guest" security=sec-guest datapath=guest-datapath channel=2ghz-ch6 tx-power=15 hide-ssid=no country="YOUR_COUNTRY" installation=indoor

add name=infra-2ghz-bsmnt ssid="network-infra" security=sec-infra datapath=infra-datapath channel=2ghz-ch11 tx-power=20 hide-ssid=yes country="YOUR_COUNTRY" installation=indoor
add name=data-2ghz-bsmnt ssid="network-data" security=sec-data datapath=data-datapath channel=2ghz-ch11 tx-power=20 hide-ssid=no country="YOUR_COUNTRY" installation=indoor
add name=guest-2ghz-bsmnt ssid="network-guest" security=sec-guest datapath=guest-datapath channel=2ghz-ch11 tx-power=20 hide-ssid=no country="YOUR_COUNTRY" installation=indoor

# 5GHz networks (20 dBm TX power - boosted for better indoor penetration)
add name=mgmt-5ghz ssid="network-mgmt" security=sec-mgmt datapath=mgmt-datapath channel=5ghz-channels tx-power=20 hide-ssid=yes country="YOUR_COUNTRY" installation=indoor
add name=alterdata-5ghz ssid="network-alterdata" security=sec-alterdata datapath=data-datapath channel=5ghz-channels tx-power=20 hide-ssid=no country="YOUR_COUNTRY" installation=indoor

# create capsman provisioning rules (for CAP ax devices to auto-discover)
/interface wifi provisioning
# provision LOCAL 2.4GHz radio (router's own wifi2) - use radio-mac for @local radios
add action=create-dynamic-enabled radio-mac=YOUR_RADIO_MAC supported-bands=2ghz-ax master-configuration=infra-2ghz-main slave-configurations=data-2ghz-main,guest-2ghz-main comment="auto-provision 2.4ghz radio - main local (channel 6)"

# provision REMOTE 2.4GHz radios with fixed primary channels per location
add action=create-dynamic-enabled identity-regexp="cap-roof" supported-bands=2ghz-ax master-configuration=infra-2ghz-roof slave-configurations=data-2ghz-roof,guest-2ghz-roof comment="auto-provision 2.4ghz radios - roof (channel 1)"
add action=create-dynamic-enabled identity-regexp="cap-bsmnt" supported-bands=2ghz-ax master-configuration=infra-2ghz-bsmnt slave-configurations=data-2ghz-bsmnt,guest-2ghz-bsmnt comment="auto-provision 2.4ghz radios - basement (channel 11)"

# provision 5GHz radios with multiple SSIDs (no identity filter = matches local + all remotes)
add action=create-dynamic-enabled supported-bands=5ghz-ax,5ghz-ac master-configuration=mgmt-5ghz slave-configurations=alterdata-5ghz comment="auto-provision 5ghz radios"

# make router radios CAPs managed
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
add name=mgmt-only comment="management access only (MAC-server, sensitive services)"

/interface list member
add interface=ether5 list=wan-interfaces comment="primary wan"
add interface=br1 list=lan-interfaces comment="lan bridge"
add interface=vlan1 list=lan-interfaces comment="mgmt vlan"
add interface=vlan2 list=lan-interfaces comment="infra vlan"
add interface=vlan3 list=lan-interfaces comment="data vlan"
add interface=vlan4 list=lan-interfaces comment="guest vlan"
add interface=vlan1 list=mgmt-only comment="mgmt vlan - restricted access"

# =====================================
# nat configuration
# =====================================

/ip firewall nat
add chain=srcnat out-interface-list=wan-interfaces action=masquerade comment="nat for all wan interfaces"

# =====================================
# basic firewall (placeholder - replaced by router-firewall-sanitized.rsc)
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
# graphing (WebFig monitoring)
# =====================================

/tool graphing interface add interface=all allow-address=192.168.254.0/24
/tool graphing resource add allow-address=192.168.254.0/24

# =====================================
# system services
# =====================================

/system ntp client set enabled=yes servers=pool.ntp.org

# =====================================
# configuration complete
# =====================================

:log info "router-main base configuration applied successfully"
:log info "CAPsMAN controller enabled with auto-provisioning for local and remote radios"
:log info "next steps: apply mtu, steering, firewall, and logging configs"
