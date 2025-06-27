# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\yakun\ebaz4205\7sho\blink_ip_zq\blink_ip_zq.vitis\bilink_ip_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\yakun\ebaz4205\7sho\blink_ip_zq\blink_ip_zq.vitis\bilink_ip_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {bilink_ip_platform}\
-hw {C:\Users\yakun\ebaz4205\7sho\blink_ip_zq\blink_ip_zq.vitis\blink_ip_zq_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {C:/Users/yakun/ebaz4205/7sho/blink_ip_zq/blink_ip_zq.vitis}

platform write
platform generate -domains 
platform active {bilink_ip_platform}
platform generate
