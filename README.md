# MikroTik Router Configuration - Sanitized Version

## Overview
A home network configuration template for MikroTik routers with CAPsMAN controller and CAP AX devices:

- **CAPsMAN Controller**: Centralized WiFi management for CAP devices
- **VLAN Segmentation**: 4-VLAN architecture with proper isolation
- **Backhaul Support**: High-performance backhaul for CAP devices (MoCA/Ethernet)
- **WiFi 6 (802.11ax)**: Dual-band networks with steering and optimization
- **Zero-Trust Security**: Comprehensive firewall with network isolation
- **Advanced Logging**: Optimized memory + disk logging with security audit trail
- **Advanced Failover**: Planned for future (hardware ready)

## ⚠️ Sanitization Notice

**This is a sanitized version of the original configuration files. The following sensitive information has been replaced with placeholders:**

### **Sanitized Variables:**
- **Admin passwords** → **`YOUR_ADMIN_PASSWORD`**, **`CHANGE_THIS_PASSWORD`** (all admin passwords)
- **System identities** → **`router-main`**, **`cap-roof`**, **`cap-bsmnt`** (device names)
- **Country** → **`YOUR_COUNTRY`** (WiFi country setting)
- **Radio MAC** → **`YOUR_RADIO_MAC`** (for local radio provisioning)
- **WiFi SSIDs** → **`network-mgmt`**, **`network-infra`**, **`network-data`**, **`network-alterdata`**, **`network-guest`** (all network names)
- **WiFi passwords** → **`MGMT_WIFI_PASSWORD`**, **`INFRA_WIFI_PASSWORD`**, **`DATA_WIFI_PASSWORD`**, **`ALTERDATA_WIFI_PASSWORD`**, **`GUEST_WIFI_PASSWORD`** (all WiFi passwords)
- **DNS servers** → **`8.8.8.8,8.8.4.4,1.1.1.1`** (public DNS)
- **WAN interface comments** → **`->wan`** (generic WAN references)
- **Device comments** → **`->device1`**, **`->device2`**, **`->device3`** (generic device references)
- **Backhaul references** → **`->backhaul->caps`**, **`backhaul trunk`** (generic backhaul descriptions)
- **Neighbor groups** → **`<hash>`** (placeholders for CAPsMAN-generated hashes)
- **Dates** → **`[DATE]`** (placeholder for configuration dates)

## Configuration Sequence

**CRITICAL: Apply configurations in this exact order:**

1. **`router-base-sanitized.rsc`** - Core router & CAPsMAN setup
2. **`router-base-mtu-sanitized.rsc`** - MTU optimization for performance  
3. **`router-base-steering-sanitized.rsc`** - WiFi band steering for CAP devices
4. **`router-firewall-sanitized.rsc`** - Zero-trust firewall with network isolation
5. **`router-logging-sanitized.rsc`** - Logging optimization (memory + disk audit)

**CAP Devices:**
- **`cap-device-sanitized.rsc`** - Generic template for all CAP AX devices

**Note**: WAN failover configuration planned for future implementation.

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
| **ether1** | Backhaul Adapter | Trunk | CAP backhaul (all VLANs tagged) |
| **ether2** | Device 1 | 2 | Infrastructure device |
| **ether3** | Device 2 | 2 | Infrastructure device |
| **ether4** | Device 3 | 2 | Infrastructure device |
| **ether5** | WAN Connection | WAN | Primary internet (2.5G) |
| **lte1** | Backup WAN | WAN | Backup internet (planned) |

### WiFi Configuration
- **TX Power**: 2.4GHz = 15-20 dBm (location-based), 5GHz = 20 dBm
- **Channel Assignment**: Non-overlapping 2.4GHz channels (1, 6, 11) per location
- **RSSI Enforcement**: 5GHz = -72 dBm, 2.4GHz = -75 dBm (band-specific thresholds)
- **Client Isolation**: Enabled on Guest and Infrastructure networks (L2)

## Security Features

### Zero-Trust Firewall
- **Default Policy**: DROP all, explicit allow rules only
- **Invalid Connections**: Dropped early in chain
- **Anti-Spoofing**: Strict reverse path filtering, private src from WAN blocked
- **Logging**: Key drops logged (INPUT-DROP, FWD-DROP, GUEST-PRIV)

### Network Isolation
| Source | Internet | Guest | Data | Infra | Mgmt |
|--------|----------|-------|------|-------|------|
| Guest | ✓ | ✗ | ✗ | ✗ | ✗ |
| Data | ✓ | ✗ | ✓ | ✗ | ✗ |
| Infra | ✓ | ✗ | ✗ | ✓ | ✗ |
| Mgmt | ✗ | ✓ | ✓ | ✓ | ✓ |

### Client Isolation (L2)
- **Guest Network**: Enabled (prevents guest-to-guest communication)
- **Infrastructure Network**: Enabled (prevents IoT device-to-device communication)
- **Data Network**: Disabled (allows device communication for media sharing)

### Silent Drop Rules (reduces log noise)
| Traffic | Port | Interface | Purpose |
|---------|------|-----------|---------|
| WAN noise | All | wan-interfaces | Internet scanners/bots |
| IoT discovery | UDP 6667 | vlan2 | Device discovery protocols |
| Spotify discovery | UDP 57621 | vlan3 | Spotify Connect |
| DHCP discover | UDP 68→67 | All | Broadcast IP requests |
| NetBIOS | UDP 137 | lan-interfaces | Windows/Mac discovery |

### DNS Security
- **Guest Network**: DNS redirect to router (captive portal ready)
- **All VLANs**: DNS queries allowed to router

### Service Restrictions
- **WebFig**: HTTPS only (TLS 1.2) on management subnet
- **WinBox/SSH**: Management subnet only (192.168.254.0/24)
- **MAC-Server**: Restricted to management VLAN only
- **Disabled**: HTTP, API, Telnet, FTP

## Logging Configuration

### Memory Logs
- **Main**: 500 lines (info/error/warning)
- **WiFi**: 200 lines (wireless,!debug)

### Disk Logs
- **Security**: `security.x.txt` - firewall audit trail (500×3 files)
- **System**: `system.x.txt` - dhcp/caps/script events (500×2 files)
- **WiFi**: `wifi-logs.x.txt` - wireless events

### Best Practice
- Debug excluded from all production rules
- Prevents DHCP packet dumps, CAPsMAN spam, verbose wireless

## Troubleshooting Tips

### CAPsMAN Issues
```routeros
# Check CAPsMAN status
/interface wifi capsman print
/interface wifi capsman remote-cap print

# Check CAPsMAN logs
/log print where topics~"caps"

# Check provisioning rules
/interface wifi provisioning print
```

### WiFi Steering Issues
```routeros
# Check neighbor groups (update steering config with actual names)
/interface wifi neighbor print

# Verify steering policies
/interface wifi steering print

# Monitor client steering behavior
/interface wifi registration-table print
```

### Firewall Issues
```routeros
# View firewall drops
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
```

### Performance Monitoring
```routeros
# Monitor WiFi performance
/interface wifi monitor wifi1

# Check CPU usage
/system resource print

# Check client distribution across CAPs
/interface wifi registration-table print

# View traffic graphs (WebFig)
# https://192.168.254.254/graphs
```

### Log Files
```routeros
# View disk log files
/file print where type="log"

# Check log sizes
/system logging action print

# View logging rules
/system logging print
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

1. **Passwords**: Replace all `*_PASSWORD` and `CHANGE_THIS_PASSWORD` placeholders
2. **SSIDs**: Replace `network-*` with your preferred network names
3. **Country**: Replace `YOUR_COUNTRY` with your country code
4. **Radio MAC**: Replace `YOUR_RADIO_MAC` in provisioning rules (find with `/interface wifi print`)
5. **Device names**: Replace `router-main`, `cap-roof`, `cap-bsmnt` as needed
6. **Steering hashes**: Update `<hash>` placeholders after initial provisioning (check `/interface wifi neighbor print`)

## Resources and Inspiration

### **Primary Inspiration:**
- **MikroTik Forum Discussion**: [Chateau LTE12 and self-managed WiFi with CAPsMAN](https://forum.mikrotik.com/t/chateau-lte12-and-self-managed-wifi-with-capsman/176219)

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

---

**Disclaimer**: This sanitized configuration is provided as a template. Ensure all settings are appropriate for your specific environment and security requirements before deployment.
