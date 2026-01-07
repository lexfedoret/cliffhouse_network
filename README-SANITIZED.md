# MikroTik Router Configuration Guide

**Last Updated:** [DATE]

## Overview
This configuration provides a comprehensive home network setup for your MikroTik router with CAPsMAN controller and CAP AX device management:

- **CAPsMAN Controller**: Centralized WiFi management for CAP AX devices
- **VLAN Segmentation**: 4-VLAN architecture with proper isolation
- **Backhaul Support**: High-performance backhaul for CAP devices (MoCA/Ethernet)
- **WiFi 6 (802.11ax)**: Dual-band networks with steering and optimization
- **Advanced Failover**: Planned for future (hardware ready)
- **Zero-Trust Security**: Comprehensive firewall with network isolation

## Configuration Sequence

**CRITICAL: Apply configurations in this exact order:**

1. **`router-base-sanitized.rsc`** - Core router & CAPsMAN setup
2. **`router-base-mtu-sanitized.rsc`** - MTU optimization for performance  
3. **`router-base-steering-sanitized.rsc`** - WiFi band steering for CAP AX devices
4. **`router-firewall-sanitized.rsc`** - Comprehensive security rules (replaces base config's open firewall)
5. **`router-logging-sanitized.rsc`** - Logging optimization (memory + disk audit)

*Note: WAN failover config planned for future*

## Network Architecture

### VLAN Structure
| VLAN | Name | Network | Gateway | Purpose |
|------|------|---------|---------|---------|
| **1** | Management | `192.168.254.0/24` | `.254.254` | Admin & CAPsMAN |
| **2** | Infrastructure | `192.168.255.0/24` | `.255.1` | Smart home & compute |
| **3** | Data | `172.16.250.0/23` | `.250.1` | User devices |
| **4** | Guest | `172.16.252.0/23` | `.252.1` | Isolated guest access |

### WiFi Networks (5 SSIDs)
| SSID | Band | VLAN | Visibility | Purpose |
|------|------|------|------------|---------|
| `network-mgmt` | 5GHz | 1 | Hidden | Management access |
| `network-infra` | 2.4GHz | 2 | Hidden | Infrastructure devices |
| `network-data` | 2.4GHz | 3 | Visible | Primary user network |
| `network-alterdata` | 5GHz | 3 | Visible | Alternative user network |
| `network-guest` | 2.4GHz | 4 | Visible | Guest access |

### Physical Port Assignment
| Port | Device | VLAN | Purpose |
|------|---------|------|---------|
| **ether1** | Backhaul Adapter | Trunk | CAP backhaul (all VLANs tagged) |
| **ether2** | Device 1 | 2 | Infrastructure device |
| **ether3** | Device 2 | 2 | Infrastructure device |
| **ether4** | Device 3 | 2 | Infrastructure device |
| **ether5** | WAN | WAN | Primary internet (2.5G) |

## Security Considerations (Cheat Sheet)

### Management Access
- **Management WiFi**: `network-mgmt` provides full admin access to all devices
- **WebFig Access**: HTTPS only (TLS 1.2) at https://192.168.254.254 (self-signed certificate)
- **Service Restrictions**: All management services restricted to management subnet (192.168.254.0/24)
- **Strong Passwords**: Complex passwords used for all accounts and WiFi networks
- **Regular Updates**: Keep RouterOS updated on all devices

### Network Isolation
- **Zero-Trust**: Default deny policy with explicit allow rules
- **VLAN Segmentation**: Proper isolation between network segments
- **Guest Isolation**: L2 client isolation + L3 firewall isolation from private networks
- **IoT Isolation**: Infrastructure devices isolated from each other (L2 client isolation)
- **Firewall Logging**: Key drop rules logged (INPUT-DROP, FWD-DROP, GUEST-PRIV)
- **Silent Drops**: WAN noise, IoT (6667), Spotify (57621), DHCP discover, NetBIOS (137)
- **DNS Redirect**: Guest DNS forced through router (captive portal ready)
- **MAC-Server**: Restricted to mgmt-only list (vlan1) - prevents guest MAC-Winbox access

### Key Security Rules
```routeros
# Management network can access everything
src-address=192.168.254.0/24 action=accept

# Guest network isolated from all private networks
src-address=172.16.252.0/23 dst-address-list=private-nets action=drop

# Data network blocked from infrastructure and management
src-address=172.16.250.0/23 dst-address=192.168.255.0/24 action=drop
src-address=172.16.250.0/23 dst-address=192.168.254.0/24 action=drop

# Infrastructure network internet access only
src-address=192.168.255.0/24 out-interface-list=wan-interfaces action=accept
```

## Troubleshooting Tips (Cheat Sheet)

### CAPsMAN Issues
```routeros
# Check CAPsMAN status
/interface wifi capsman print

# Verify CAP discovery
/interface wifi capsman remote-cap print

# Check CAPsMAN logs
/log print where topics~"caps"

# Verify interface status
/interface wifi print detail

# Check provisioning rules
/interface wifi provisioning print
```

### WiFi Steering Issues
```routeros
# Check neighbor groups (update steering config with actual names)
/interface wifi steering neighbor-group print

# Verify steering policies
/interface wifi steering print

# Monitor client steering behavior
/interface wifi registration-table print

# Update steering configuration with actual group names
/interface wifi steering set cap-steering-mgmt neighbor-group="actual-group-name"
```

### Firewall Issues
```routeros
# View firewall drops in log
/log print where message~"DROP"

# Check rule order (infra rules must be BEFORE default deny)
/ip firewall filter print where chain=forward

# View rule statistics
/ip firewall filter print stats
```

### Network Connectivity
```routeros
# Test VLAN connectivity
/ping 192.168.254.254 count=3  # Management
/ping 192.168.255.1 count=3    # Infrastructure  
/ping 172.16.250.1 count=3     # Data
/ping 172.16.252.1 count=3     # Guest

# Test inter-VLAN isolation (should be blocked per security rules)
/tool ping address=192.168.255.1 interface=vlan3  # Should fail (data→infra)

# Check DHCP leases
/ip dhcp-server lease print

# Check firewall rules
/ip firewall filter print

# Monitor connections
/ip firewall connection print
```

### Failover Monitoring (Future)
*Failover config not yet implemented. These commands will be relevant when failover is configured.*

```routeros
# View active routes
/ip route print where active

# Check WAN interface status
/interface print stats
```

### Performance Monitoring
```routeros
# Monitor WiFi performance
/interface wifi monitor wifi1

# Check CPU usage
/system resource print

# Monitor interface statistics
/interface print stats

# Check client distribution across CAPs
/interface wifi registration-table print
```

### Log Files
```routeros
# View disk log files
/file print where type="log"

# View security audit log (firewall events)
# Download security.0.txt from Files in Winbox

# View system log (dhcp/caps/script)
# Download system.0.txt from Files in Winbox

# Check log sizes
/system logging action print
```

## Backup and Maintenance

### Regular Backups
```routeros
# Export configuration
/export compact file=backup-$(date)

# Create system backup
/system backup save name=system-backup-$(date)
```

### Health Monitoring
```routeros
# Check system health
/system health print

# Monitor logs
/log print

# Check disk usage
/system resource print
```

## Customization Checklist

Before deploying, update these values in the configuration files:

1. **Passwords**: Replace all `*_PASSWORD` placeholders
2. **SSIDs**: Replace `network-*` with your preferred network names
3. **Country**: Replace `YOUR_COUNTRY` with your country code
4. **Radio MAC**: Replace `YOUR_RADIO_MAC` in provisioning rules
5. **Device names**: Replace `router-main`, `cap-roof`, `cap-bsmnt` as needed
6. **Steering hashes**: Update `<hash>` placeholders after initial provisioning

## Resources and Inspiration

This configuration was developed using the following resources:

### **Primary Inspiration:**
- **MikroTik Forum Discussion**: [Chateau LTE12 and self-managed WiFi with CAPsMAN](https://forum.mikrotik.com/t/chateau-lte12-and-self-managed-wifi-with-capsman/176219) - The working forum example that heavily inspired this configuration approach

### **Official Documentation:**
- **MikroTik Documentation**: https://help.mikrotik.com/docs/
- **CAPsMAN Guide**: https://help.mikrotik.com/docs/display/ROS/CAPsMAN
- **WiFi Configuration**: https://help.mikrotik.com/docs/display/ROS/WiFi
- **RouterOS Firewall**: https://help.mikrotik.com/docs/display/ROS/Filter
- **VLAN Configuration**: https://help.mikrotik.com/docs/display/ROS/Bridging+and+Switching

### **Community Resources:**
- **MikroTik Community Forum**: https://forum.mikrotik.com/
- **MikroTik Training**: https://mikrotik.com/training
- **RouterOS Downloads**: https://mikrotik.com/download

### **Technical References:**
- **RouterOS v7 WiFi**: https://help.mikrotik.com/docs/display/ROS/WiFi
- **Policy-Based Routing**: https://help.mikrotik.com/docs/display/ROS/Policy+Based+Routing
- **Bridge VLAN Filtering**: https://help.mikrotik.com/docs/display/ROS/Bridge+VLAN+Filtering

---

**Note**: This configuration was heavily inspired by the MikroTik community forum discussion linked above. The original working example provided the foundation for this home network implementation.
