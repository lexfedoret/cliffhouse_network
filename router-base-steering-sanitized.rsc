# MikroTik WiFi Steering Configuration for CAP Devices
# RouterOS Configuration File - WiFi Steering Module
# Date: [DATE]
# 
# IMPORTANT: Apply this AFTER router-base-sanitized.rsc is working
# This adds WiFi steering for band steering and load balancing across CAP devices
# 
# Prerequisites:
# 1. Basic CAPsMAN must be working and provisioning CAPs
# 2. All SSIDs must be broadcasting and clients connecting
# 3. Neighbor groups are auto-created after initial provisioning
# 
# Step 1: Apply router-base-sanitized.rsc (basic CAPsMAN config)
# Step 2: Verify CAPsMAN provisioning is working
# Step 3: Check WiFi interfaces are created: /interface wifi print
# Step 4: Apply this file (router-base-steering-sanitized.rsc)

# =====================================
# WIFI STEERING CONFIGURATION
# =====================================

# IMPORTANT: Getting real neighbor group hashes in RouterOS 7.x
# 
# Step 1: Apply router-base-sanitized.rsc and provision your CAP devices first
# Step 2: Check actual neighbor group names created by CAPsMAN:
#         /interface wifi steering neighbor-group print
# Step 3: Copy the real neighbor group names from the output
# Step 4: Replace the REPLACE_WITH_ACTUAL_HASH placeholders below with real names
#
# Example output from /interface wifi steering neighbor-group print:
# 0  name="dynamic-network-mgmt-a1b2c3d4" 
# 1  name="dynamic-network-infra-e5f6g7h8"
# 2  name="dynamic-network-data-i9j0k1l2"
# etc.
#
# Then use these exact names in the steering configuration below:

# WiFi steering configuration for CAP devices 
/interface wifi steering
add disabled=no name=cap-steering-mgmt comment="management network steering" neighbor-group="dynamic-network-mgmt-REPLACE_WITH_ACTUAL_HASH"
add disabled=no name=cap-steering-infra comment="infrastructure network steering" neighbor-group="dynamic-network-infra-REPLACE_WITH_ACTUAL_HASH"
add disabled=no name=cap-steering-data comment="data network steering" neighbor-group="dynamic-network-data-REPLACE_WITH_ACTUAL_HASH"
add disabled=no name=cap-steering-alterdata comment="alterdata network steering" neighbor-group="dynamic-network-alterdata-REPLACE_WITH_ACTUAL_HASH"
add disabled=no name=cap-steering-guest comment="guest network steering" neighbor-group="dynamic-network-guest-REPLACE_WITH_ACTUAL_HASH"

# =====================================
# UPDATE WIFI CONFIGURATIONS WITH STEERING
# =====================================

# NOTE: After creating steering groups above, update WiFi configurations to use them
# You must run these commands to link configurations to steering groups

# Update WiFi configurations with steering (single block with multiple set commands)
/interface wifi configuration
set [find name=infra-2ghz] steering=cap-steering-infra
set [find name=data-2ghz] steering=cap-steering-data
set [find name=guest-2ghz] steering=cap-steering-guest
set [find name=mgmt-5ghz] steering=cap-steering-mgmt
set [find name=alterdata-5ghz] steering=cap-steering-alterdata

# =====================================
# STEERING VERIFICATION COMMANDS
# =====================================

# After applying this configuration, verify steering is working:
# 
# 1. Check steering policies:
#    /interface wifi steering print
#
# 2. Verify WiFi configurations have steering assigned:
#    /interface wifi configuration print detail
#
# 3. Monitor client steering behavior:
#    /interface wifi registration-table print
#
# 4. Check neighbor groups (get real hashes for steering config):
#    /interface wifi steering neighbor-group print
#
# 5. View steering statistics:
#    /interface wifi steering monitor [find]

# =====================================
# STEERING TUNING (OPTIONAL)
# =====================================

# Fine-tune steering behavior if needed:
# /interface wifi steering set cap-steering-mgmt \
#   load-balance-threshold=70 \
#   signal-threshold=-70 \
#   band-steering=yes

# Note: Adjust thresholds based on your environment and requirements
# - load-balance-threshold: Client distribution threshold (%)
# - signal-threshold: Minimum signal strength for steering (dBm)
# - band-steering: Enable automatic 2.4GHz ↔ 5GHz steering

# =====================================
# CONFIGURATION COMPLETE
# =====================================

:log info "WiFi steering configuration applied"
:log info "steering policies created for all networks"
:log info "WiFi configurations updated with steering assignments"
:log info "IMPORTANT: Replace REPLACE_WITH_ACTUAL_HASH placeholders with real neighbor group names"
:log info "Use: /interface wifi steering neighbor-group print to get actual hash values"
:log info "verify steering operation with /interface wifi steering print"
