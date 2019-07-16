source ../bd/axi_slave_helpers.tcl
source ../bd/Xilinx_AXI_slaves.tcl
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

    [AXI_DEVICE_ADD C2C1      axi_interconnect_0/M06_AXI axi_interconnect_0/M06_ACLK axi_interconnect_0/M06_ARESETN 50000000]
    [AXI_DEVICE_ADD MONITOR   axi_interconnect_0/M07_AXI axi_interconnect_0/M07_ACLK axi_interconnect_0/M07_ARESETN 50000000]

    [AXI_DEVICE_ADD XVC_LOCAL   axi_interconnect_0/M08_AXI axi_interconnect_0/M08_ACLK axi_interconnect_0/M08_ARESETN 50000000]
    [AXI_DEVICE_ADD C2C1_LITE axi_interconnect_0/M09_AXI axi_interconnect_0/M09_ACLK axi_interconnect_0/M09_ARESETN 50000000]    
#    [AXI_DEVICE_ADD C2C1_A_GT M08 PL_CLK PL_RESET_N 50000000]
#    [AXI_DEVICE_ADD C2C1_B_GT M08 PL_CLK PL_RESET_N 50000000] 
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
    #  XVC_Local (xilinx axi debug XVC)
    #========================================
    puts "Adding Local Xilinx XVC"
    [AXI_IP_LOCAL_XVC XVC_LOCAL]

    
    #========================================
    #  MONITOR (xilinx axi XADC)
    #========================================
    puts "Adding Xilinx XADC Monitor"
    [AXI_IP_XADC MONITOR]

    
    #========================================
    #  AXI C2C 1
    #========================================
    set INIT_CLK init_clk
    create_bd_port -dir I -type clk ${INIT_CLK}
    set_property CONFIG.FREQ_HZ 50000000 [get_bd_ports ${INIT_CLK}]            
    [AXI_C2C_MASTER C2C1]
    
    #========================================
    #  Add non-xilinx AXI slave
    #========================================
    puts "Adding user slaves"
    #AXI_PL_CONNECT creates all the PL slaves in the list passed to it.
    [AXI_PL_CONNECT "SERV SLAVE_I2C CM "]

    validate_bd_design
}

