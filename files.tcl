set bd_path bd/

set bd_name zynq_bd

set bd_files "\
    bd/create.tcl \
    "

set vhdl_files "\
     src/top.vhd \
     src/misc/types.vhd \
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
     "

#     src/TCDS/lhc_clock_module.vhd \
#     src/TCDS/lhc_gt_usrclk_source.vhd \
#     src/TCDS/lhc_support.vhd \
#     src/TCDS/MGBT2_common_reset.vhd \
#     src/TCDS/MGBT2_common.vhd \
#     src/TCDS/TCDS.vhd \
#
#     src/SGMII/i2c_package.vhd \
#     src/SGMII/I2C_reg_master.vhd \
#     src/SGMII/SGMII_SiConfig.vhd \
#     src/SGMII/SGMII_SiConfig_data.vhd \

set xdc_files src/top.xdc

set xci_files "\
    	      cores/SGMII_INTF/SGMII_INTF.xci \
    	      cores/onboard_CLK/onboard_CLK.xci \
	      cores/aurora_64b66b_0/aurora_64b66b_0.xci \
    	      "

#	      cores/LHC/LHC.xci \
