# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\Users\yakun\ebaz4205\7sho\blink_ip_zq\blink_ip_zq.vitis\blink_ip_app_system\_ide\scripts\debugger_blink_ip_app-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\Users\yakun\ebaz4205\7sho\blink_ip_zq\blink_ip_zq.vitis\blink_ip_app_system\_ide\scripts\debugger_blink_ip_app-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT2 C306BD8CABCD" && level==0 && jtag_device_ctx=="jsn-JTAG-SMT2-C306BD8CABCD-13722093-0"}
fpga -file C:/Users/yakun/ebaz4205/7sho/blink_ip_zq/blink_ip_zq.vitis/blink_ip_app/_ide/bitstream/blink_ip_zq_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw C:/Users/yakun/ebaz4205/7sho/blink_ip_zq/blink_ip_zq.vitis/bilink_ip_platform/export/bilink_ip_platform/hw/blink_ip_zq_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source C:/Users/yakun/ebaz4205/7sho/blink_ip_zq/blink_ip_zq.vitis/blink_ip_app/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow C:/Users/yakun/ebaz4205/7sho/blink_ip_zq/blink_ip_zq.vitis/blink_ip_app/Debug/blink_ip_app.elf
configparams force-mem-access 0
bpadd -addr &main
