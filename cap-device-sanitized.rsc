# MikroTik CAP AX Device Configuration
# RouterOS Configuration File - Backhaul Version
# Date: [DATE]
# 
# CAP AX device configuration for backhaul via ether1
# Management IP: DHCP assigned from 192.168.254.0/24 (VLAN 1)
#
# This is a generic template - customize for each CAP location:
# - cap-roof: Roof/attic location
# - cap-bsmnt: Basement location
# - cap-floor2: Second floor, etc.

# =====================================
# system configuration
# =====================================

# set admin password
/user set admin password="YOUR_ADMIN_PASSWORD"
/system identity set name="YOUR_CAP_NAME"
/system clock set time-zone-name=America/New_York

# =====================================
# interface configuration
# =====================================

# create main bridge with vlan filtering
/interface bridge add name=br1 vlan-filtering=yes protocol-mode=rstp

# add datapath for CAPsMAN
/interface wifi datapath add bridge=br1 disabled=no name=cap-datapath

# configure bridge ports
/interface bridge port
add bridge=br1 interface=ether1 frame-types=admit-only-vlan-tagged comment="backhaul trunk (tagged only)"

# physically disable ether2 for security (if unused)
/interface ethernet set ether2 disabled=yes

# =====================================
# vlan configuration for backhaul
# =====================================

# create VLAN interface for management
/interface vlan
add interface=br1 name=vlan1-mgmt vlan-id=1 comment="management VLAN interface"

# configure bridge VLANs
/interface bridge vlan
add bridge=br1 vlan-ids=1 tagged=br1,ether1 untagged="" comment="management vlan"
add bridge=br1 vlan-ids=2 tagged=br1,ether1 untagged="" comment="infrastructure vlan"
add bridge=br1 vlan-ids=3 tagged=br1,ether1 comment="data vlan"
add bridge=br1 vlan-ids=4 tagged=br1,ether1 comment="guest vlan"

# =====================================
# ip address configuration
# =====================================

# get management IP via DHCP from main router
/ip dhcp-client add interface=vlan1-mgmt disabled=no comment="cap management dhcp client"

# =====================================
# wifi configuration
# =====================================

# configure wifi interfaces for CAPsMAN management
/interface wifi
set wifi1 configuration.manager=capsman datapath=cap-datapath disabled=no
set wifi2 configuration.manager=capsman datapath=cap-datapath disabled=no

# do NOT add physical radios to bridge - CAPsMAN will create VIFs and attach them automatically

# =====================================
# capsman client configuration
# =====================================

# enable CAP client mode
/interface wifi cap set caps-man-addresses=192.168.254.254 discovery-interfaces=vlan1-mgmt enabled=yes slaves-datapath=cap-datapath slaves-static=yes

# =====================================
# system services
# =====================================

/system ntp client set enabled=yes servers=pool.ntp.org

# NOTE: Auto-update handled by CAPsMAN controller (upgrade-policy=require-same-version)
# CAPs automatically upgrade when the controller upgrades

# =====================================
# service security
# =====================================

# lock management services to management subnet only
/ip service set www disabled=yes
/ip service set www-ssl address=192.168.254.0/24 disabled=no
/ip service set winbox address=192.168.254.0/24
/ip service set ssh address=192.168.254.0/24
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes

:log info "CAP device backhaul configuration applied"
:log info "management dhcp client enabled on vlan1-mgmt"
:log info "backhaul via ether1 trunk port"
:log info "wifi radios ready for CAPsMAN provisioning"
:log info "discovery enabled via vlan1-mgmt interface"

# =====================================
# deployment instructions
# =====================================
#
# MikroTik CAP AX Device - [LOCATION]
#
# Device: YOUR_CAP_NAME
# Management IP: DHCP assigned from 192.168.254.0/24
# Backhaul: Via ether1 (VLAN trunk)
#
# Key Features:
# - Backhaul via ether1 with full VLAN support
# - WiFi AX radios ready for CAPsMAN auto-provisioning
# - Management network discovery via VLAN 1
# - All VLANs (1,2,3,4) available for client assignment
#
# Physical Connections:
# - ether1: Backhaul adapter (VLAN trunk - all VLANs tagged)
# - ether2: DISABLED for security (or configure as needed)
#
# Network Configuration:
# - Management: VLAN 1 via backhaul trunk only
# - Infrastructure: VLAN 2 via backhaul trunk only
# - Data/Guest: VLAN 3/4 via backhaul trunk only
#
# CAPsMAN Integration:
# - Discovers controller at 192.168.254.254 via vlan1-mgmt
# - Receives 5 SSID configurations via auto-provisioning
# - Local VLAN switching with per-SSID assignment
#
# Customization:
# 1. Change YOUR_CAP_NAME to your device identity (e.g., cap-roof, cap-bsmnt)
# 2. Change YOUR_ADMIN_PASSWORD to your admin password
# 3. If using ether2 for a wired device, configure it with appropriate PVID
#