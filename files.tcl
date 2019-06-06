set bd_path bd/

set bd_name zynq_bd

set bd_files "\
    bd/create.tcl \
    "

set vhdl_files "\
     src/top.vhd \
     src/misc/types.vhd \
     src/axiReg/axiRegPkg.vhd \
     src/axiReg/axiReg.vhd \
     src/SGMII/SGMII_INTF_clocking.vhd \
     src/SGMII/SGMII_INTF_resets.vhd \
     src/services/services.vhd \
     src/services/SGMII_MON_pkg.vhd \
     src/SGMII/i2c_package.vhd \
     src/SGMII/I2C_reg_master.vhd \
     src/SGMII/SGMII_SiConfig.vhd \
     src/SGMII/SGMII_SiConfig_data.vhd \
     "

set xdc_files src/top.xdc

set xci_files "\
    	      cores/SGMII_INTF/SGMII_INTF.xci \
    	      cores/onboard_CLK/onboard_CLK.xci \
    	      "
