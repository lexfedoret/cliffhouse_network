# MikroTik Router - MTU Optimization Configuration
# RouterOS Configuration File - MTU Module
# Date: [DATE]
# 
# Apply this configuration after router-base-sanitized.rsc
# This module optimizes MTU settings for improved network performance
#
# MTU Configuration:
# - Increases MTU on primary WAN interface (ether5)
# - Enables jumbo frames for better throughput
# - Recommended for high-speed connections

# =====================================
# mtu optimization
# =====================================

# configure 2.5g interface with jumbo frames
/interface ethernet set ether5 mtu=9192 l2mtu=9192

# =====================================
# configuration complete
# =====================================

:log info "router-main MTU optimization applied"
:log info "ether5 (WAN) configured with MTU=9192 for jumbo frame support"

