# MikroTik Advanced Firewall Rules Configuration
# RouterOS Configuration File - Firewall Module
# Date: [DATE]
# 
# IMPORTANT: Apply this AFTER router-base-sanitized.rsc
# This replaces the basic "allow everything" firewall rule with proper security
# 
# Step 1: Apply router-base-sanitized.rsc (basic config with open firewall)
# Step 2: Apply this file (router-firewall-sanitized.rsc) for proper security

# =====================================
# ADVANCED FIREWALL RULES (ZERO-TRUST)
# =====================================

# create address lists for advanced firewall rules
/ip firewall address-list
add list=private-nets address=172.16.0.0/12
add list=private-nets address=192.168.0.0/16

# Remove basic firewall rule from router-base-sanitized.rsc (replace with zero-trust)
/ip firewall filter
:do { remove [find comment~"allow everything"] } on-error={}

# advanced inter-vlan firewall rules (zero-trust segmentation)
/ip firewall filter

# =====================================
# INPUT CHAIN RULES (router access)
# =====================================
add chain=input src-address=192.168.254.0/24 action=accept comment="allow input from mgmt"
add chain=input connection-state=established,related action=accept comment="accept established/related"
add chain=input protocol=icmp action=accept comment="allow icmp (ping)"
add chain=input protocol=udp dst-port=67-68 action=accept comment="allow dhcp"
add chain=input protocol=udp dst-port=53 in-interface-list=lan-interfaces action=accept comment="allow DNS (UDP)"
add chain=input protocol=tcp dst-port=53 in-interface-list=lan-interfaces action=accept comment="allow DNS (TCP)"
add chain=input in-interface-list=wan-interfaces action=drop comment="silent drop WAN noise"
add chain=input protocol=udp dst-port=6667 in-interface=vlan2 action=drop comment="silent drop IoT discovery (6667)"
add chain=input protocol=udp dst-port=57621 in-interface=vlan3 action=drop comment="silent drop Spotify discovery (57621)"
add chain=input protocol=udp src-port=68 dst-port=67 dst-address=255.255.255.255 action=drop comment="silent drop DHCP discover broadcasts"
add chain=input protocol=udp dst-port=137 in-interface-list=lan-interfaces action=drop comment="silent drop NetBIOS name service (137)"
add chain=input action=drop log=yes log-prefix="INPUT-DROP" comment="drop everything else (input)"

# =====================================
# FORWARD CHAIN RULES (inter-vlan routing)
# =====================================
add chain=forward connection-state=established,related action=accept comment="accept established/related"
add chain=forward protocol=icmp action=accept comment="allow icmp forwarding (ping)"

# guest network restrictions
add chain=forward src-address=172.16.252.0/23 dst-address-list=private-nets action=drop log=yes log-prefix="GUEST-PRIV" comment="guest > all private drop"
add chain=forward src-address=172.16.252.0/23 dst-address=172.16.252.0/23 action=drop comment="guest > guest isolation"
add chain=forward src-address=172.16.252.0/23 out-interface-list=wan-interfaces action=accept comment="guest > internet allow"
add chain=forward src-address=172.16.252.0/23 action=drop comment="guest > any drop (safety net)"

# data network restrictions
add chain=forward src-address=172.16.250.0/23 dst-address=192.168.255.0/24 action=drop comment="data > infra drop"
add chain=forward src-address=172.16.250.0/23 dst-address=192.168.254.0/24 action=drop comment="data > mgmt drop"
add chain=forward src-address=172.16.250.0/23 dst-address=172.16.252.0/23 action=drop comment="data > guest drop"
add chain=forward src-address=172.16.250.0/23 out-interface-list=wan-interfaces action=accept comment="data > internet allow"
add chain=forward src-address=172.16.250.0/23 action=drop comment="data > any drop (safety net)"

# infrastructure network policies
add chain=forward src-address=192.168.255.0/24 out-interface-list=wan-interfaces action=accept comment="infra > internet allow"
add chain=forward src-address=192.168.255.0/24 dst-address-list=private-nets action=drop comment="infra > private drop (isolation)"
add chain=forward src-address=192.168.255.0/24 action=accept comment="infra > infra allow (intra-vlan)"

# management network policies
add chain=forward src-address=192.168.254.0/24 dst-address=192.168.255.0/24 action=accept comment="mgmt > infra allow"
add chain=forward src-address=192.168.254.0/24 out-interface-list=wan-interfaces action=drop comment="mgmt > internet block"
add chain=forward src-address=192.168.254.0/24 action=accept comment="mgmt > any vlan allow"

# default deny (zero-trust)
add chain=forward action=drop log=yes log-prefix="FWD-DROP" comment="drop all other forwarding (zero-trust)"

# =====================================
# WIFI ACCESS LIST (RSSI ENFORCEMENT)
# =====================================

# Band-specific RSSI thresholds based on WiFi survey analysis:
# - 5GHz: -72 dBm threshold (relaxed for better coverage, weak clients fall back to 2.4GHz)
# - 2.4GHz: -75 dBm threshold (lenient for concrete penetration and outdoor areas)
#
# This ensures devices use strong 2.4GHz instead of sticking to weak 5GHz

/interface wifi access-list

# 5GHz networks - -72 dBm threshold
add ssid-regexp="network-mgmt" signal-range=-72..120 action=accept comment="5GHz mgmt: accept -72+"
add ssid-regexp="network-mgmt" signal-range=-120..-73 action=reject comment="5GHz mgmt: reject weak (<-72)"
add ssid-regexp="network-alterdata" signal-range=-72..120 action=accept comment="5GHz alterdata: accept -72+"
add ssid-regexp="network-alterdata" signal-range=-120..-73 action=reject comment="5GHz alterdata: reject weak (<-72)"

# 2.4GHz networks - lenient -75 dBm threshold
add ssid-regexp="network-infra" signal-range=-75..120 action=accept comment="2.4GHz infra: accept -75+"
add ssid-regexp="network-infra" signal-range=-120..-76 action=reject comment="2.4GHz infra: reject weak"
add ssid-regexp="network-data" signal-range=-75..120 action=accept comment="2.4GHz data: accept -75+"
add ssid-regexp="network-data" signal-range=-120..-76 action=reject comment="2.4GHz data: reject weak"
add ssid-regexp="network-guest" signal-range=-75..120 action=accept comment="2.4GHz guest: accept -75+"
add ssid-regexp="network-guest" signal-range=-120..-76 action=reject comment="2.4GHz guest: reject weak"

# =====================================
# SERVICE SECURITY
# =====================================

# Generate SSL certificate for web interface (if not exists)
:if ([:len [/certificate find where name="local-ca"]] = 0) do={
    /certificate add name=local-ca common-name=router-ca key-size=2048 days-valid=3650 key-usage=key-cert-sign,crl-sign
    :delay 2s
    /certificate sign local-ca
    :delay 3s
    :log info "Local CA certificate created"
}
:if ([:len [/certificate find where name="webfig-cert"]] = 0) do={
    /certificate add name=webfig-cert common-name=router-main key-size=2048 days-valid=3650 key-usage=digital-signature,key-encipherment,tls-server
    :delay 2s
    /certificate sign webfig-cert ca=local-ca
    :delay 3s
    :log info "SSL certificate generated for web interface"
}

/ip service set www disabled=yes
:if ([:len [/certificate find where name="webfig-cert"]] > 0) do={
    /ip service set www-ssl address=192.168.254.0/24 certificate=webfig-cert tls-version=only-1.2 disabled=no
}
/ip service set winbox address=192.168.254.0/24
/ip service set ssh address=192.168.254.0/24
/ip service set api disabled=yes
/ip service set api-ssl disabled=yes
/ip service set telnet disabled=yes
/ip service set ftp disabled=yes

# =====================================
# FIREWALL HARDENING PATCH
# =====================================

# ---- Address-lists: include 10/8 as private (for VPN/remote) ----
/ip firewall address-list
:if ([:len [find where list=private-nets and address="10.0.0.0/8"]]=0) do={ add list=private-nets address=10.0.0.0/8 comment="private" }

# ---- INPUT hardening ----
/ip firewall filter
# drop invalid early
:do { add chain=input connection-state=invalid action=drop comment="drop invalid (input)" place-before=0 } on-error={}

# restrict mgmt allow to LAN interfaces (anti-spoof)
:do { set [find where chain=input and comment="allow input from mgmt"] in-interface-list=lan-interfaces } on-error={}
# restrict DHCP & ICMP to LAN only
:do { set [find where chain=input and comment="allow dhcp"] in-interface-list=lan-interfaces } on-error={}
:do { set [find where chain=input and comment="allow icmp (ping)"] in-interface-list=lan-interfaces } on-error={}

# ---- FORWARD hardening ----
# drop invalid early
:do { add chain=forward connection-state=invalid action=drop comment="drop invalid (forward)" place-before=0 } on-error={}

# scope ICMP forwarding to Internet only (prevents guest→private ping)
:do { set [find where chain=forward and comment="allow icmp forwarding (ping)"] out-interface-list=wan-interfaces } on-error={}

# Note: Infra rules are now in main forward chain (before default deny) for proper evaluation

# ---- L2/Neighbor surface reduction ----
:do { /ip neighbor discovery-settings set discover-interface-list=lan-interfaces } on-error={}
# MAC-server restricted to mgmt-only (prevents guest/infra MAC-Winbox access)
:do { /tool mac-server set allowed-interface-list=mgmt-only } on-error={}
:do { /tool mac-server mac-winbox set allowed-interface-list=mgmt-only } on-error={}

# ---- CAPsMAN controller support ----
# allow CAPsMAN communication from Management VLAN (before INPUT-DROP)
:do { add chain=input src-address=192.168.254.0/24 protocol=udp dst-port=5246-5247 action=accept comment="allow capsman from mgmt" place-before=[find where chain=input and comment="drop everything else (input)"] } on-error={}

# ---- WAN DHCP client support ----
:do { add chain=input in-interface-list=wan-interfaces protocol=udp src-port=67 dst-port=68 action=accept comment="allow DHCP client on WAN" place-before=[find where chain=input and comment="drop everything else (input)"] } on-error={}

# ---- WAN anti-spoofing protection (early in chain) ----
:do { add chain=input in-interface-list=wan-interfaces src-address-list=private-nets action=drop comment="anti-spoof: private src from WAN" place-before=[find where chain=input and comment="allow input from mgmt"] } on-error={}

# enable strict reverse path filtering
:do { /ip settings set rp-filter=strict } on-error={}

# =====================================
# DNS REDIRECT FOR GUESTS
# =====================================

# Force guest network to use router DNS (prevents bypass, enables captive portal)
/ip firewall nat
add chain=dstnat src-address=172.16.252.0/23 protocol=udp dst-port=53 action=redirect to-ports=53 comment="force guest DNS (UDP)"
add chain=dstnat src-address=172.16.252.0/23 protocol=tcp dst-port=53 action=redirect to-ports=53 comment="force guest DNS (TCP)"

:log info "advanced firewall rules applied successfully"
:log info "zero-trust network segmentation enabled"
:log info "guest network isolated from private networks"
:log info "data network restricted from management/infrastructure"
:log info "infrastructure network accessible only from management"
:log info "firewall hardening patch applied - enhanced security"
:log info "WiFi access list configured - band-specific thresholds: 5GHz=-72dBm, 2.4GHz=-75dBm"
:log info "WAN noise silenced - internet scanner drops not logged"

# =====================================
# FIREWALL DEPLOYMENT INSTRUCTIONS
# =====================================
#
# This configuration provides:
# - Zero-trust network segmentation
# - Guest network complete isolation from private networks
# - Data network restricted from management and infrastructure
# - Infrastructure network accessible only from management
# - Management network blocked from internet (security)
# - Default deny policy for all unspecified traffic
# - WiFi RSSI enforcement (minimum signal thresholds per band)
#
# Network Access Matrix:
# ┌─────────────┬──────────┬───────┬──────┬───────┬──────────┐
# │ Source      │ Internet │ Guest │ Data │ Infra │ Mgmt     │
# ├─────────────┼──────────┼───────┼──────┼───────┼──────────┤
# │ Guest       │    ✓     │   ✗   │  ✗   │   ✗   │    ✗     │
# │ Data        │    ✓     │   ✗   │  ✓   │   ✗   │    ✗     │
# │ Infra       │    ✓     │   ✗   │  ✗   │   ✓   │    ✗     │
# │ Mgmt        │    ✗     │   ✓   │  ✓   │   ✓   │    ✓     │
# └─────────────┴──────────┴───────┴──────┴───────┴──────────┘
#
# Key Security Enhancements:
# - ICMP forwarding scoped to Internet only (prevents guest→private ping)
# - Infrastructure network can access Internet (✓ in matrix)
# - Infrastructure blocked from other private networks (one-way isolation)
# - Invalid connection states dropped early (performance + security)
# - Input services restricted to LAN interfaces only (anti-spoofing)
# - L2/neighbor discovery limited to LAN (reduces attack surface)
# - 10.0.0.0/8 included in private-nets (VPN/remote network protection)
# - Invalid drops moved to chain tops for optimal performance
# - CAPsMAN controller support (UDP 5246-5247 from Management VLAN)
# - WAN DHCP client support (UDP 67→68 from WAN interfaces)
# - WAN anti-spoofing protection (private source addresses blocked from WAN)
# - Strict reverse path filtering (kernel-level spoofing prevention)
# - Silent WAN drop (internet scanner noise not logged - keeps Winbox clean)
# - Silent IoT discovery drop (port 6667 on vlan2 - device discovery)
# - Silent Spotify discovery drop (port 57621 on vlan3 - Spotify Connect)
# - Silent DHCP discover drop (broadcast from devices requesting IP)
# - Silent NetBIOS drop (port 137 - Windows/Mac network discovery)
#
# Client Isolation (L2):
# Guest and Infrastructure datapaths have client-isolation=yes enabled.
# This prevents same-VLAN L2 traffic (ARP, direct MAC communication) between wireless clients.
# Configured in router-base-sanitized.rsc:
#   /interface wifi datapath set guest-datapath client-isolation=yes
#   /interface wifi datapath set infra-datapath client-isolation=yes
#
# WiFi RSSI Enforcement (Band-Specific):
# - 5GHz threshold: -72 dBm (relaxed - forces fallback to 2.4GHz when weak)
# - 2.4GHz threshold: -75 dBm (lenient - for concrete penetration and outdoor)
# - Prevents sticky clients from using weak 5GHz when 2.4GHz is stronger
#
# Monitoring Commands:
# /ip firewall filter print                    # View all filter rules
# /ip firewall address-list print             # View address lists
# /log print where topics~"firewall"          # View firewall logs (INPUT-DROP, FWD-DROP, GUEST-PRIV)
# /ip firewall filter print stats             # View rule statistics
# /interface wifi access-list print           # View WiFi RSSI rules
# /interface wifi registration-table print    # View connected clients and signal strength
#


