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
     "

set xdc_files src/top.xdc

set xci_files "\
    	      "
