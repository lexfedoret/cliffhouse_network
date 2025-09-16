# MikroTik Router Configuration - Sanitized Version

## Overview
This sanitized configuration provides a complete enterprise-grade setup for MikroTik routers with CAPsMAN controller and CAP device management:

- **CAPsMAN Controller**: Centralized WiFi management for CAP devices
- **VLAN Segmentation**: 4-VLAN architecture with proper isolation
- **Backhaul Support**: High-performance backhaul for CAP devices
- **WiFi 6 (802.11ax)**: Dual-band networks with steering and optimization
- **Advanced Failover**: Policy-based routing with health monitoring
- **Zero-Trust Security**: Comprehensive firewall with network isolation

## ⚠️ Sanitization Notice

**This is a sanitized version of the original configuration files. The following sensitive information has been replaced with placeholders:**

### **Sanitized Variables:**
- **Admin passwords** → **`YOUR_ADMIN_PASSWORD`** (all admin passwords)
- **System identities** → **`YOUR_ROUTER_NAME`**, **`YOUR_CAP_NAME`** (device names)
- **Time zone** → **`YOUR_TIME_ZONE`** (system time zone setting)
- **Country** → **`YOUR_COUNTRY`** (WiFi country setting)
- **ISP MTU** → **`YOUR_ISP_MTU`** (ISP-specific MTU setting for WAN interface)
- **WiFi SSIDs** → **`network-mgmt`**, **`network-infra`**, **`network-data`**, **`network-alterdata`**, **`network-guest`** (all network names)
- **WiFi passwords** → **`MGMT_WIFI_PASSWORD`**, **`INFRA_WIFI_PASSWORD`**, **`DATA_WIFI_PASSWORD`**, **`ALTERDATA_WIFI_PASSWORD`**, **`GUEST_WIFI_PASSWORD`** (all WiFi passwords)
- **DNS servers** → **`8.8.8.8,8.8.4.4,1.1.1.1`** (public DNS instead of ISP-specific)
- **WAN interface comments** → **`->wan`**, **`->backup-carrier`** (generic WAN references)
- **Carrier settings** → **`backup.carrier.com`** (generic carrier APN)
- **Device comments** → **`->device1`**, **`->device2`**, **`->device3`** (generic device references)
- **Backhaul references** → **`->backhaul->caps`**, **`backhaul trunk`** (generic backhaul descriptions)
- **Neighbor groups** → **`REPLACE_WITH_ACTUAL_HASH`** (placeholders for real CAPsMAN-generated hashes)
- **Dates** → **`[DATE]`** (placeholder for configuration dates)
- **Location references** → **`[LOCATION]`** (placeholder for physical locations)

## Configuration Sequence

**CRITICAL: Apply configurations in this exact order:**

1. **`router-base-sanitized.rsc`** - Core router & CAPsMAN setup
2. **`router-base-mtu-sanitized.rsc`** - MTU optimization for performance  
3. **`router-base-steering-sanitized.rsc`** - WiFi band steering for CAP devices

**Note**: Failover and firewall configurations are not included in this sanitized version as they have not been fully tested yet.

## Hardware Requirements

### Tested Hardware Configuration

This configuration has been **tested and verified working** on the following hardware setup:

- **Main Router**: MikroTik Chateau 5G R17 ax
  - RouterOS v7.x
  - WiFi 6 (802.11ax) dual-band radios
  - 2.5 Gigabit Ethernet WAN port
  - Built-in 5G/LTE modem for backup WAN
  - CAPsMAN controller functionality

- **Access Points**: MikroTik cAP ax devices
  - WiFi 6 (802.11ax) dual-band radios
  - Managed by CAPsMAN controller
  - Auto-provisioning support
  - VLAN-aware bridge configuration

- **Backhaul Connection**: MoCA (Multimedia over Coax Alliance)
  - High-performance coaxial cable backhaul
  - VLAN trunk support for all network segments
  - Reliable connection between main router and CAP devices
  - No additional WiFi mesh overhead

### Hardware Notes

- **RouterOS Version**: Requires RouterOS v7.x for WiFiWave2 and modern CAPsMAN features
- **MoCA Compatibility**: Any MoCA 2.0+ adapters should work for backhaul
- **CAP Device Variants**: Configuration should work with other cAP ax models (cAP ax, cAP ax lite, etc.)
- **Alternative Backhaul**: Ethernet backhaul can be substituted for MoCA with minimal configuration changes

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
| **ether1** | Device 1 | 2 | Infrastructure device |
| **ether2** | Device 2 | 2 | Infrastructure device |
| **ether3** | Device 3 | 2 | Infrastructure device |
| **ether4** | Backhaul Adapter | Trunk | CAP backhaul (all VLANs) |
| **ether5** | WAN Connection | WAN | Primary internet |
| **lte1** | Backup WAN | WAN | Backup internet |

## Security Considerations (Cheat Sheet)

### Management Access
- **Management WiFi**: Provides full admin access to all devices
- **Service Restrictions**: All management services restricted to management subnet (192.168.254.0/24)
- **Strong Passwords**: Use complex passwords for all accounts and WiFi networks
- **Regular Updates**: Keep RouterOS updated on all devices

### Network Isolation
- **Zero-Trust**: Default deny policy with explicit allow rules
- **VLAN Segmentation**: Proper isolation between network segments
- **Guest Isolation**: Guest network completely isolated from private networks
- **Firewall Logging**: Enable logging for security monitoring

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
# Check neighbor groups
/interface wifi steering neighbor-group print

# Verify steering policies
/interface wifi steering print

# Monitor client steering behavior
/interface wifi registration-table print
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

### Failover Monitoring
```routeros
# Check failover status
/system script environment print

# Monitor failover events  
/log print where topics~"info"

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

**Disclaimer**: This sanitized configuration is provided as a template. Ensure all settings are appropriate for your specific environment and security requirements before deployment. The original configuration was heavily inspired by the MikroTik community forum discussion linked above.