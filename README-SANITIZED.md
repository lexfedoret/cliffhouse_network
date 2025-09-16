# MikroTik Router Configuration - Sanitized Version

## Overview
This sanitized configuration provides a complete enterprise-grade setup for MikroTik routers with CAPsMAN controller and CAP device management:

- **CAPsMAN Controller**: Centralized WiFi management for CAP devices
- **VLAN Segmentation**: 4-VLAN architecture with proper isolation
- **Backhaul Support**: High-performance backhaul for CAP devices
- **WiFi 6 (802.11ax)**: Dual-band networks with steering and optimization
- **Advanced Failover**: Policy-based routing with health monitoring
- **Zero-Trust Security**: Comprehensive firewall with network isolation

## ⚠️ IMPORTANT: Sanitization Notice

**This is a sanitized version of the original configuration files. All sensitive information has been replaced with placeholders:**

- **Passwords**: Replace `CHANGE_THIS_PASSWORD` with strong passwords
- **SSIDs**: Replace `network-*` with your desired network names
- **WiFi Passwords**: Replace `*_WIFI_PASSWORD` with strong WiFi passwords
- **Device Names**: Replace `router-main`, `cap-device-LOCATION` with your naming scheme
- **ISP Settings**: Replace `backup.carrier.com` with your carrier's APN
- **Location Names**: Replace `[LOCATION]` with actual locations
- **Dates**: Replace `[DATE]` with current dates

## Configuration Sequence

**CRITICAL: Apply configurations in this exact order:**

1. **`router-base-sanitized.rsc`** - Core router & CAPsMAN setup
2. **`router-base-mtu-sanitized.rsc`** - MTU optimization for performance  
3. **`router-base-steering-sanitized.rsc`** - WiFi band steering for CAP devices
4. **`router-failover-sanitized.rsc`** - Advanced WAN failover & monitoring
5. **`router-firewall-sanitized.rsc`** - Comprehensive security rules

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

## Pre-Deployment Customization

### 1. Security Settings
```routeros
# Change admin password
/user set admin password="YourStrongPassword123!"

# Update WiFi passwords in security configurations
/interface wifi security set sec-mgmt passphrase="YourMgmtWiFiPassword"
/interface wifi security set sec-infra passphrase="YourInfraWiFiPassword"
/interface wifi security set sec-data passphrase="YourDataWiFiPassword"
/interface wifi security set sec-alterdata passphrase="YourAltDataWiFiPassword"
/interface wifi security set sec-guest passphrase="YourGuestWiFiPassword"
```

### 2. Network Naming
```routeros
# Update system identity
/system identity set name="your-router-name"

# Update WiFi network names
/interface wifi configuration set infra-2ghz ssid="your-infra-network"
/interface wifi configuration set data-2ghz ssid="your-data-network"
/interface wifi configuration set guest-2ghz ssid="your-guest-network"
/interface wifi configuration set mgmt-5ghz ssid="your-mgmt-network"
/interface wifi configuration set alterdata-5ghz ssid="your-alterdata-network"
```

### 3. Carrier-Specific Settings
```routeros
# Update APN for your backup carrier
/interface lte apn set [find name="backup.carrier.com"] name="your-carrier-apn" apn="your-carrier-apn"

# Common carrier APNs:
# T-Mobile: "fast.t-mobile.com"
# Verizon: "vzwinternet"
# AT&T: "broadband"
```

### 4. CAP Device Configuration
```routeros
# For each CAP device, update identity
/system identity set name="cap-device-location-name"

# Update comments and descriptions as needed
```

## Installation Steps

### Prerequisites
1. **Factory reset** all devices (main router + CAP devices)
2. **Backhaul adapters** installed and connected
3. **Customize configurations** with your specific settings
4. **Document passwords** securely

### Method 1: WinBox (Recommended)

#### Main Router Setup
1. Connect to router via **ether1-3** (avoid ether4/ether5)
2. Open WinBox → Connect to `192.168.88.1` or MAC address
3. Login: `admin` / (no password initially)
4. **Upload all customized configuration files** via Files menu
5. **Apply configurations in sequence:**
   ```routeros
   /import router-base-sanitized.rsc
   # Wait for completion, verify CAPsMAN is working
   
   /import router-base-mtu-sanitized.rsc
   # Apply MTU optimizations
   
   /import router-base-steering-sanitized.rsc
   # Configure WiFi steering (update neighbor groups first!)
   
   /import router-failover-sanitized.rsc
   # Add advanced failover
   
   /import router-firewall-sanitized.rsc
   # Apply security rules
   ```
6. **Reboot**: `/system reboot`

#### CAP Device Setup
1. **Factory reset** each CAP device
2. Connect via ethernet temporarily
3. Upload and apply customized CAP configuration:
   ```routeros
   /import cap-device-sanitized.rsc
   ```
4. **Connect backhaul** and remove ethernet
5. **Verify discovery** on main router: `/interface wifi capsman remote-cap print`

## Post-Installation Configuration

### 1. Verify CAPsMAN Operation
```routeros
# Check CAPsMAN status
/interface wifi capsman print

# Verify CAP discovery
/interface wifi capsman remote-cap print

# Check provisioned interfaces
/interface wifi print
```

### 2. Update WiFi Steering (IMPORTANT!)
```routeros
# Check neighbor groups (after CAPs are provisioned)
/interface wifi neighbor print

# Update steering configuration with actual group names
/interface wifi steering set cap-steering-mgmt neighbor-group="actual-group-name"
# Repeat for all steering entries
```

### 3. Verify Network Connectivity
```routeros
# Test VLAN connectivity
/ping 192.168.254.254 count=3  # Management
/ping 192.168.255.1 count=3    # Infrastructure  
/ping 172.16.250.1 count=3     # Data
/ping 172.16.252.1 count=3     # Guest

# Check DHCP leases
/ip dhcp-server lease print
```

## Security Considerations

### Management Access
- **Management WiFi**: Provides full admin access to all devices
- **Service Restrictions**: All management services restricted to management subnet
- **Strong Passwords**: Use complex passwords for all accounts and WiFi networks
- **Regular Updates**: Keep RouterOS updated on all devices

### Network Isolation
- **Zero-Trust**: Default deny policy with explicit allow rules
- **VLAN Segmentation**: Proper isolation between network segments
- **Guest Isolation**: Guest network completely isolated from private networks
- **Firewall Logging**: Enable logging for security monitoring

## Troubleshooting

### CAPsMAN Issues
```routeros
# Check CAPsMAN logs
/log print where topics~"caps"

# Verify interface status
/interface wifi print detail

# Check provisioning rules
/interface wifi provisioning print
```

### Network Connectivity
```routeros
# Test inter-VLAN connectivity (should be blocked per security rules)
/tool ping address=192.168.255.1 interface=vlan3  # Should fail (data→infra)

# Check firewall rules
/ip firewall filter print

# Monitor connections
/ip firewall connection print
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
# Check failover status
/system script environment print

# Monitor failover events  
/log print where topics~"info"

# View active routes
/ip route print where active
```

## Support Resources

- **MikroTik Documentation**: https://help.mikrotik.com/docs/
- **CAPsMAN Guide**: https://help.mikrotik.com/docs/display/ROS/CAPsMAN
- **WiFi Configuration**: https://help.mikrotik.com/docs/display/ROS/WiFi
- **Community Forum**: https://forum.mikrotik.com/

## Important Notes

⚠️ **Sanitized Configuration**: Remember to customize all placeholders before deployment

⚠️ **Configuration Dependencies**: Always apply configurations in the specified sequence

⚠️ **WiFi Steering**: Update neighbor-group names after initial CAPsMAN provisioning

⚠️ **Security**: Management network provides full admin access - protect credentials

⚠️ **Testing**: Thoroughly test all functionality after customization and deployment

---

**Disclaimer**: This sanitized configuration is provided as a template. Ensure all settings are appropriate for your specific environment and security requirements before deployment.
