# MikroTik Router MTU Optimization Configuration
# RouterOS Configuration File - MTU Module
# Date: [DATE]
# 
# IMPORTANT: Apply this AFTER router-base-sanitized.rsc is working
# This optimizes MTU settings for performance

# =====================================
# MTU OPTIMIZATION
# =====================================

# configure primary wan interface with jumbo frames for performance
/interface ethernet set ether5 comment="->wan" mtu=YOUR_ISP_MTU l2mtu=YOUR_ISP_MTU