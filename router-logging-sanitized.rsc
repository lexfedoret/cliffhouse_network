# MikroTik Logging Configuration
# RouterOS Configuration File - Logging Module
# Date: [DATE]
#
# IMPORTANT: Apply this AFTER router-firewall-sanitized.rsc
# Optimizes logging for memory efficiency and security auditing
#
# Configuration Sequence:
# 1. router-base-sanitized.rsc
# 2. router-base-mtu-sanitized.rsc
# 3. router-base-steering-sanitized.rsc
# 4. router-firewall-sanitized.rsc
# 5. router-logging-sanitized.rsc  <-- This file

# =====================================
# LOGGING ACTIONS (destinations)
# =====================================

# Reduce main memory log (Winbox view) - less noise
/system logging action set memory memory-lines=500

# WiFi memory log (separate from main log)
:if ([:len [/system logging action find where name="wifimem"]] = 0) do={
    /system logging action add name=wifimem target=memory memory-lines=200 memory-stop-on-full=no
} else={
    /system logging action set wifimem memory-lines=200
}

# WiFi disk log
:if ([:len [/system logging action find where name="wifidisk"]] = 0) do={
    /system logging action add name=wifidisk target=disk disk-file-name=wifi-logs disk-lines-per-file=1000
}

# Security disk log for firewall audit trail (500 lines × 3 files = 1500 entries)
:if ([:len [/system logging action find where name="securitydisk"]] = 0) do={
    /system logging action add name=securitydisk target=disk disk-file-name=security disk-lines-per-file=500 disk-file-count=3
}

# System disk log for troubleshooting (500 lines × 2 files = 1000 entries)
:if ([:len [/system logging action find where name="systemdisk"]] = 0) do={
    /system logging action add name=systemdisk target=disk disk-file-name=system disk-lines-per-file=500 disk-file-count=2
}

# =====================================
# LOGGING RULES (routing)
# Best Practice: Exclude debug from all rules
# =====================================

# Firewall events to security disk (audit trail) - no debug level for firewall
:if ([:len [/system logging find where topics~"firewall" and action=securitydisk]] = 0) do={
    /system logging add topics=firewall action=securitydisk
}

# System events to disk (exclude debug - too verbose)
:if ([:len [/system logging find where topics~"system" and action=systemdisk]] = 0) do={
    /system logging add topics=system,!debug action=systemdisk
}

# Script events to disk (exclude debug)
:if ([:len [/system logging find where topics~"script" and action=systemdisk]] = 0) do={
    /system logging add topics=script,!debug action=systemdisk
}

# DHCP events to disk (exclude debug - packet dumps too verbose)
:if ([:len [/system logging find where topics~"dhcp" and action=systemdisk]] = 0) do={
    /system logging add topics=dhcp,!debug action=systemdisk
}

# CAPsMAN events to disk (exclude debug - "no suitable CAPsMAN" spam)
:if ([:len [/system logging find where topics~"caps" and action=systemdisk]] = 0) do={
    /system logging add topics=caps,!debug action=systemdisk
}

# =====================================
# WIRELESS LOGGING (separate from main log)
# =====================================

# Remove default wireless rules (they flood main log)
:foreach i in=[/system logging find where topics~"wireless" and action=memory] do={
    /system logging remove $i
}

# Wireless to dedicated memory buffer (exclude debug)
:if ([:len [/system logging find where topics~"wireless" and action=wifimem]] = 0) do={
    /system logging add topics=wireless,!debug action=wifimem
}

# Wireless to disk (exclude debug)
:if ([:len [/system logging find where topics~"wireless" and action=wifidisk]] = 0) do={
    /system logging add topics=wireless,!debug action=wifidisk
}

:log info "Logging optimization applied"
:log info "Memory logs reduced: main=500, wifi=200"
:log info "Disk logs enabled: security (firewall), system (dhcp/caps/script)"
:log info "Debug excluded from all disk logging (best practice)"

# =====================================
# LOG FILE SUMMARY
# =====================================
#
# Disk Files Created:
# - security.0.txt, security.1.txt, security.2.txt  (firewall audit)
# - system.0.txt, system.1.txt                      (system/dhcp/caps/script, !debug)
# - wifi-logs.0.txt, wifi-logs.1.txt                (wireless events, !debug)
# - log.0.txt, log.1.txt                            (general - existing default)
#
# Memory Logs (Winbox):
# - Main memory: 500 lines (info/error/warning)
# - WiFi memory: 200 lines (wireless,!debug)
#
# Best Practice: Debug excluded from all custom rules
# - Debug is for troubleshooting, not production
# - Prevents: DHCP packet dumps, CAPsMAN self-discovery spam, verbose wireless
#
# Monitoring Commands:
# /system logging print                    # View logging rules
# /system logging action print             # View logging actions
# /file print where name~"security"        # View security log files
# /file print where name~"system"          # View system log files
# /log print                               # View main memory log
#



