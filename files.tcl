set bd_path bd/

set bd_name zynq_bd

set bd_files "\
    bd/create.tcl \
    "

set vhdl_files "\
     src/top.vhd \
     src/misc/types.vhd \
     src/misc/uart.vhd \
     src/misc/uart_rx6.vhd \
     src/misc/uart_tx6.vhd \
     src/misc/asym_dualport_ram.vhd \
     src/axiReg/axiRegPkg.vhd \
     src/axiReg/axiReg.vhd \
     src/SGMII/SGMII_INTF_clocking.vhd \
     src/SGMII/SGMII_INTF_resets.vhd \
     src/services/services.vhd \
     src/services/SGMII_MON_pkg.vhd \
     src/IPMC_i2c_slave/i2c_slave.vhd \
     src/IPMC_i2c_slave/IPMC_i2c_slave.vhd \
     src/CM_interface/CM_interface.vhd \
     src/CM_interface/CM_package.vhd \
     src/front_panel/Button_Debouncer.vhd \
     src/front_panel/Button_Decoder.vhd \
     src/front_panel/FrontPanel_UI.vhd \
     src/front_panel/LED_Encoder.vhd \
     src/front_panel/SR_Out.vhd \
     "


set xdc_files src/top.xdc

set xci_files "\
    	      cores/SGMII_INTF/SGMII_INTF.xci \
    	      cores/onboard_CLK/onboard_CLK.xci \
    	      "

#	      cores/aurora_64b66b_0/aurora_64b66b_0.xci \
