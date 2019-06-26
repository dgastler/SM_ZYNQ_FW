source ../bd/axi_slave_helpers.tcl
#================================================================================
#  Configure and add AXI slaves
#================================================================================

proc ADD_AXI_SLAVES { } {
    [AXI_DEVICE_ADD SI     axi_interconnect_0/M00_AXI axi_interconnect_0/M00_ACLK axi_interconnect_0/M00_ARESETN 50000000]    
    [AXI_DEVICE_ADD SERV M01 PL_CLK PL_RESET_N 50000000]
    
    [AXI_DEVICE_ADD XVC1    axi_interconnect_0/M02_AXI axi_interconnect_0/M02_ACLK axi_interconnect_0/M02_ARESETN 50000000]
    [AXI_DEVICE_ADD XVC2    axi_interconnect_0/M03_AXI axi_interconnect_0/M03_ACLK axi_interconnect_0/M03_ARESETN 50000000]

    [AXI_DEVICE_ADD SLAVE_I2C M04 PL_CLK PL_RESET_N 50000000]
    [AXI_DEVICE_ADD CM M05 PL_CLK PL_RESET_N 50000000]

    [AXI_DEVICE_ADD ESM_UART     axi_interconnect_0/M06_AXI axi_interconnect_0/M06_ACLK axi_interconnect_0/M06_ARESETN 50000000]
    [AXI_DEVICE_ADD CM1_UART     axi_interconnect_0/M07_AXI axi_interconnect_0/M07_ACLK axi_interconnect_0/M07_ARESETN 50000000]
    [AXI_DEVICE_ADD CM2_UART     axi_interconnect_0/M08_AXI axi_interconnect_0/M08_ACLK axi_interconnect_0/M08_ARESETN 50000000]    
    
    [AXI_DEVICE_ADD C2C1    axi_interconnect_0/M09_AXI axi_interconnect_0/M09_ACLK axi_interconnect_0/M09_ARESETN 50000000]    
#    [AXI_DEVICE_ADD C2C2    axi_interconnect_0/M03_AXI axi_interconnect_0/M03_ACLK axi_interconnect_0/M03_ARESETN 50000000]
#
    [AXI_DEVICE_ADD C2C1_GT M10 PL_CLK PL_RESET_N 50000000] 
}

proc CONFIGURE_AXI_SLAVES { } {
    global AXI_BUS_M
    global AXI_BUS_RST
    global AXI_BUS_CLK
    global AXI_MASTER_CLK
    global AXI_MASTER_RST
    global AXI_INTERCONNECT_NAME


    #========================================
    # Si5344 I2C master
    #========================================
    [AXI_IP_I2C SI]
    
    #========================================
    #  XVC1 (xilinx axi debug XVC)
    #========================================
    puts "Adding Xilinx XVC1"
    [AXI_IP_XVC XVC1]
    #========================================
    #  XVC2 (xilinx axi debug XVC)
    #========================================
    puts "Adding Xilinx XVC2"
    [AXI_IP_XVC XVC2]


    #========================================
    #  Ethernet switch UART
    #========================================
    puts "Adding Xilix UART for ESM"
    [AXI_IP_UART ESM_UART 115200]
    #========================================
    #  Command module 1 UART
    #========================================
    puts "Adding Xilix UART for CM1"
    [AXI_IP_UART CM1_UART 115200]
    #========================================
    #  Command module 2 UART
    #========================================
    puts "Adding Xilix UART for CM2"
    [AXI_IP_UART CM2_UART 115200]

#    #========================================
#    #  AXI C2C 1
#    #========================================
    [AXI_C2C_MASTER C2C1]
#    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_chip2chip:5.0 C2C1
#    set_property CONFIG.C_AXI_STB_WIDTH {4}         [get_bd_cells C2C1]
#    set_property CONFIG.C_AXI_DATA_WIDTH {32}	    [get_bd_cells C2C1]
#    set_property CONFIG.C_NUM_OF_IO {58.0}	    [get_bd_cells C2C1]
#    set_property CONFIG.C_INTERFACE_MODE {0}	    [get_bd_cells C2C1]
#    set_property CONFIG.C_INTERFACE_TYPE {2}	    [get_bd_cells C2C1]
#    set_property CONFIG.C_AURORA_WIDTH {1.0}        [get_bd_cells C2C1]
#    set_property CONFIG.C_EN_AXI_LINK_HNDLR {false} [get_bd_cells C2C1]
#
#    [AXI_DEV_CONNECT C2C1 $AXI_BUS_M(C2C1) $AXI_BUS_CLK(C2C1) $AXI_BUS_RST(C2C1)]
#    connect_bd_net [get_bd_pins $AXI_MASTER_CLK] [get_bd_pins $AXI_BUS_CLK(C2C1)]
#    connect_bd_net [get_bd_pins $AXI_MASTER_RST] [get_bd_pins $AXI_BUS_RST(C2C1)]
#
#    #expose signals to aurora code
#    #to USER_DATA_M_AXIS_RX
#    make_bd_intf_pins_external  [get_bd_intf_pins C2C1/AXIS_RX]
#    #to USER_DATA_M_AXIS_TX
#    make_bd_intf_pins_external  [get_bd_intf_pins C2C1/AXIS_TX]
#    #to user_clk_out
#    make_bd_pins_external  [get_bd_pins C2C1/axi_c2c_phy_clk]
#    #to channel up
#    make_bd_pins_external  [get_bd_pins C2C1/axi_c2c_aurora_channel_up]
#    #to init_clk_out
#    make_bd_pins_external  [get_bd_pins C2C1/aurora_init_clk]
#    #to mmcm_not_locked_out
#    make_bd_pins_external  [get_bd_pins C2C1/aurora_mmcm_not_locked]
#    #to pma_init
#    make_bd_pins_external  [get_bd_pins C2C1/aurora_pma_init_out]
#    #to reset_pb
#    make_bd_pins_external  [get_bd_pins C2C1/aurora_reset_pb]           
#    
#    
#    assign_bd_address [get_bd_addr_segs {C2C1/S_AXI/Mem }]
#
#
##    #========================================
##    #  AXI C2C 2
##    #========================================
##    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_chip2chip:5.0 C2C2
##    set_property CONFIG.C_AXI_STB_WIDTH {8}         [get_bd_cells C2C2]
##    set_property CONFIG.C_AXI_DATA_WIDTH {64}	    [get_bd_cells C2C2]
##    set_property CONFIG.C_NUM_OF_IO {84.0}	    [get_bd_cells C2C2]
##    set_property CONFIG.C_INTERFACE_MODE {0}	    [get_bd_cells C2C2]
##    set_property CONFIG.C_INTERFACE_TYPE {2}	    [get_bd_cells C2C2]
##    set_property CONFIG.C_AURORA_WIDTH {2.0}        [get_bd_cells C2C2]
##    set_property CONFIG.C_EN_AXI_LINK_HNDLR {false} [get_bd_cells C2C2]
##
##    [AXI_DEV_CONNECT C2C2 $AXI_BUS_M(C2C2) $AXI_BUS_CLK(C2C2) $AXI_BUS_RST(C2C2)]
##    connect_bd_net [get_bd_pins $AXI_MASTER_CLK] [get_bd_pins $AXI_BUS_CLK(C2C2)]
##    connect_bd_net [get_bd_pins $AXI_MASTER_RST] [get_bd_pins $AXI_BUS_RST(C2C2)]
#
#    
    #========================================
    #  Add non-xilinx AXI slave
    #========================================
    puts "Adding user slaves"
    #AXI_PL_CONNECT creates all the PL slaves in the list passed to it.
    [AXI_PL_CONNECT "SERV SLAVE_I2C CM C2C1_GT"]

    validate_bd_design
}


proc AXI_IP_I2C {device_name} {
    global AXI_BUS_M
    global AXI_BUS_RST
    global AXI_BUS_CLK
    global AXI_MASTER_CLK
    global AXI_MASTER_RST

    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 $device_name

    #create external pins
    make_bd_pins_external  -name ${device_name}_scl_i [get_bd_pins $device_name/scl_i]
    make_bd_pins_external  -name ${device_name}_sda_i [get_bd_pins $device_name/sda_i]
    make_bd_pins_external  -name ${device_name}_sda_o [get_bd_pins $device_name/sda_o]
    make_bd_pins_external  -name ${device_name}_scl_o [get_bd_pins $device_name/scl_o]
    make_bd_pins_external  -name ${device_name}_scl_t [get_bd_pins $device_name/scl_t]
    make_bd_pins_external  -name ${device_name}_sda_t [get_bd_pins $device_name/sda_t]
    #connect to AXI, clk, and reset between slave and mastre
    [AXI_DEV_CONNECT $device_name $AXI_BUS_M($device_name) $AXI_BUS_CLK($device_name) $AXI_BUS_RST($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_CLK] [get_bd_pins $AXI_BUS_CLK($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_RST] [get_bd_pins $AXI_BUS_RST($device_name)]
    #build the DTSI chunk for this device to be a UIO
    [AXI_DEV_UIO_DTSI_POST_CHUNK $device_name]
    puts "Added Xilinx I2C AXI Slave: $device_name"
}

proc AXI_IP_XVC {device_name} {
    global AXI_BUS_M
    global AXI_BUS_RST
    global AXI_BUS_CLK
    global AXI_MASTER_CLK
    global AXI_MASTER_RST
    #Create a xilinx axi debug bridge
    create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge:3.0 $device_name
    #configure the debug bridge to be 
    set_property CONFIG.C_DEBUG_MODE  {3} [get_bd_cells $device_name]
    set_property CONFIG.C_DESIGN_TYPE {0} [get_bd_cells $device_name]

    #connect to AXI, clk, and reset between slave and mastre
    [AXI_DEV_CONNECT $device_name $AXI_BUS_M($device_name) $AXI_BUS_CLK($device_name) $AXI_BUS_RST($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_CLK] [get_bd_pins $AXI_BUS_CLK($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_RST] [get_bd_pins $AXI_BUS_RST($device_name)]

    
    #generate ports for the JTAG signals
    make_bd_pins_external       [get_bd_cells $device_name]
    make_bd_intf_pins_external  [get_bd_cells $device_name]
    #build the DTSI chunk for this device to be a UIO
    [AXI_DEV_UIO_DTSI_POST_CHUNK $device_name]
    puts "Added Xilinx XVC AXI Slave: $device_name"
}

proc AXI_IP_UART {device_name baud_rate} {
    global AXI_BUS_M
    global AXI_BUS_RST
    global AXI_BUS_CLK
    global AXI_MASTER_CLK
    global AXI_MASTER_RST
    #Create a xilinx UART
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 $device_name
    #configure the debug bridge to be
    set_property CONFIG.C_BAUDRATE $baud_rate [get_bd_cells $device_name]

    #connect to AXI, clk, and reset between slave and mastre
    [AXI_DEV_CONNECT $device_name $AXI_BUS_M($device_name) $AXI_BUS_CLK($device_name) $AXI_BUS_RST($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_CLK] [get_bd_pins $AXI_BUS_CLK($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_RST] [get_bd_pins $AXI_BUS_RST($device_name)]

    
    #generate ports for the JTAG signals
    make_bd_pins_external  -name ${device_name}_rx [get_bd_pins $device_name/rx]
    make_bd_pins_external  -name ${device_name}_tx [get_bd_pins $device_name/tx]

    
    #build the DTSI chunk for this device to be a UIO
    [AXI_DEV_UIO_DTSI_POST_CHUNK $device_name]
    puts "Added Xilinx UART AXI Slave: $device_name"
}


proc AXI_C2C_MASTER {device_name} {
    global AXI_BUS_M
    global AXI_BUS_RST
    global AXI_BUS_CLK
    global AXI_MASTER_CLK
    global AXI_MASTER_RST

    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_chip2chip:5.0 $device_name
    set_property CONFIG.C_AXI_STB_WIDTH {4}         [get_bd_cells $device_name]
    set_property CONFIG.C_AXI_DATA_WIDTH {32}	    [get_bd_cells $device_name]
    set_property CONFIG.C_NUM_OF_IO {58.0}	    [get_bd_cells $device_name]
    set_property CONFIG.C_INTERFACE_MODE {0}	    [get_bd_cells $device_name]
    set_property CONFIG.C_INTERFACE_TYPE {2}	    [get_bd_cells $device_name]
    set_property CONFIG.C_AURORA_WIDTH {1.0}        [get_bd_cells $device_name]
    set_property CONFIG.C_EN_AXI_LINK_HNDLR {false} [get_bd_cells $device_name]

    [AXI_DEV_CONNECT $device_name $AXI_BUS_M($device_name) $AXI_BUS_CLK($device_name) $AXI_BUS_RST($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_CLK] [get_bd_pins $AXI_BUS_CLK($device_name)]
    connect_bd_net [get_bd_pins $AXI_MASTER_RST] [get_bd_pins $AXI_BUS_RST($device_name)]

    #expose signals to aurora code
    #to USER_DATA_M_AXIS_RX
    make_bd_intf_pins_external  [get_bd_intf_pins $device_name/AXIS_RX]
    #to USER_DATA_M_AXIS_TX
    make_bd_intf_pins_external  [get_bd_intf_pins $device_name/AXIS_TX]
    #to user_clk_out
    make_bd_pins_external  [get_bd_pins $device_name/axi_c2c_phy_clk]
    #to channel up
    make_bd_pins_external  [get_bd_pins $device_name/axi_c2c_aurora_channel_up]
    #to init_clk_out
    make_bd_pins_external  [get_bd_pins $device_name/aurora_init_clk]
    #to mmcm_not_locked_out
    make_bd_pins_external  [get_bd_pins $device_name/aurora_mmcm_not_locked]
    #to pma_init
    make_bd_pins_external  [get_bd_pins $device_name/aurora_pma_init_out]
    #to reset_pb
    make_bd_pins_external  [get_bd_pins $device_name/aurora_reset_pb]           
    
    
    assign_bd_address [get_bd_addr_segs {$device_name/S_AXI/Mem }]
    puts "Added C2C master: $device_name"
}
