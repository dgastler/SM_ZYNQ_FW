library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.AXIRegPkg.all;

use work.types.all;
use work.CM_package.all;



Library UNISIM;
use UNISIM.vcomponents.all;


entity CM_interface is
  
  port (
    clk_axi         : in  std_logic;
    reset_axi_n     : in  std_logic;
    readMOSI        : in  AXIReadMOSI;
    readMISO        : out AXIReadMISO := DefaultAXIReadMISO;
    writeMOSI       : in  AXIWriteMOSI;
    writeMISO       : out AXIWriteMISO := DefaultAXIWriteMISO;
    enableCM1       : out std_logic;
    enableCM2       : out std_logic;
    enableCM1_PWR   : out std_logic;
    enableCM2_PWR   : out std_logic;
    enableCM1_IOs   : out std_logic;
    enableCM2_IOs   : out std_logic;
    from_CM1        :  in from_CM_t;
    from_CM2        :  in from_CM_t;
    to_CM1_in       :  in to_CM_t;  --from SM
    to_CM2_in       :  in to_CM_t;  --from SM
    to_CM1_out      : out to_CM_t;  --from SM, but tristated
    to_CM2_out      : out to_CM_t;  --from SM, but tristated
    CM1_C2C_Mon     :  in C2C_Monitor_t;
    CM2_C2C_Mon     :  in C2C_Monitor_t;
    CM1_C2C_Ctrl    : out C2C_Control_t;
    CM2_C2C_Ctrl    : out C2C_Control_t
    );
end entity CM_interface;

architecture behavioral of CM_interface is
  signal localAddress : slv_32_t;
  signal localRdData  : slv_32_t;
  signal localRdData_latch  : slv_32_t;
  signal localWrData  : slv_32_t;
  signal localWrEn    : std_logic;
  signal localRdReq   : std_logic;
  signal localRdAck   : std_logic;
  

  signal reg_data :  slv32_array_t(integer range 0 to 64);
  constant Default_reg_data : slv32_array_t(integer range 0 to 64) := (0 => x"00000000",
                                                                       1 => x"00000000",
                                                                       others => x"00000000");

  signal PWR_good         : slv_2_t;
  signal enableCM         : slv_2_t;
  signal enableCM_PWR     : slv_2_t;
  signal override_PWRGood : slv_2_t;
  signal enable_uC        : slv_2_t;
  signal enable_PWR       : slv_2_t;
  signal enable_IOs       : slv_2_t;
  signal CM_seq_state     : slv_8_t;
  signal CM1_disable      : std_logic;
  signal CM2_disable      : std_logic;


  signal reset             : std_logic;                     
  signal uart_tx           : slv_2_t;
  signal uart_rx           : slv_2_t;
  signal uart_wr_en        : slv_2_t;                
  signal uart_wr_half_full : slv_2_t;         
  signal uart_wr_full      : slv_2_t;              
  signal uart_rd_data      : slv8_array_t(0 to 1);
  signal uart_rd_en        : slv_2_t;                
  signal uart_rd_available : slv_2_t;         
  signal uart_rd_half_full : slv_2_t;         
  signal uart_rd_full      : slv_2_t;

  
begin  -- architecture behavioral

  reset <= not reset_axi_n;
  
  -------------------------------------------------------------------------------
  -- CM interface
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------  
  --CM1
  CM1_UART_BUF : OBUFT
    port map (
      T => CM1_disable,
      I => uart_tx(0),
      O => to_CM1_out.UART_Tx);
  CM1_TMS_BUF : OBUFT
    port map (
      T => CM1_disable,
      I => to_CM1_in. TMS,
      O => to_CM1_out.TMS);
  CM1_TDI_BUF : OBUFT
    port map (
      T => CM1_disable,
      I => to_CM1_in. TDI,
      O => to_CM1_out.TDI);
  CM1_TCK_BUF : OBUFT
    port map (
      T => CM1_disable,
      I => to_CM1_in. TCK,
      O => to_CM1_out.TCK);
  --CM2
  CM2_UART_BUF : OBUFT
    port map (
      T => CM2_disable,
      I => uart_tx(1),
      O => to_CM2_out.UART_Tx);
  CM2_TMS_BUF : OBUFT
    port map (
      T => CM2_disable,
      I => to_CM2_in. TMS,
      O => to_CM2_out.TMS);
  CM2_TDI_BUF : OBUFT
    port map (
      T => CM2_disable,
      I => to_CM2_in. TDI,
      O => to_CM2_out.TDI);
  CM2_TCK_BUF : OBUFT
    port map (
      T => CM2_disable,
      I => to_CM2_in. TCK,
      O => to_CM2_out.TCK);


  
  -------------------------------------------------------------------------------
  --Power-up sequences
  -------------------------------------------------------------------------------
  PWR_good(0)   <= from_CM1.PWR_good;
  enableCM1     <= enable_uC(0);
  enableCM1_PWR <= enable_PWR(0);
  enableCM1_IOs <= enable_IOs(0);
  CM1_disable   <= not enable_IOs(0);

  PWR_good(1)   <= from_CM2.PWR_good;
  enableCM2     <= enable_uC(1);
  enableCM2_PWR <= enable_PWR(1);
  enableCM2_IOs <= enable_IOs(1);
  CM2_disable   <= not enable_IOs(1);

  CM_PWR_SEQ: for iCM in 0 to 1 generate
    CM_pwr_1: entity work.CM_pwr
      port map (
        clk               => clk_axi,
        reset             => reset,
        start_uC          => enableCM(iCM),
        start_PWR         => enableCM_PWR(iCM),
        sequence_override => override_PWRGood(iCM),
        current_state     => CM_seq_state((4*iCM) +3 downto 4*iCM),
        enable_uC         => enable_uC(iCM),
        enable_PWR        => enable_PWR(iCM),
        enable_IOs        => enable_IOs(iCM),
        power_good        => PWR_good(iCM));
  end generate CM_PWR_SEQ;
  
  -------------------------------------------------------------------------------
  --UARTS
  -------------------------------------------------------------------------------
  uart_rx <= from_CM2.UART_Rx & from_CM1.UART_Rx;
  CM_UARTs: for iCM in 0 to 1 generate  
    uart_CM: entity work.uart
      generic map (
        BAUD_COUNT => 26)
      port map (
        clk             => clk_axi,
        reset           => reset,
        tx              => uart_tx(iCM),
        rx              => uart_rx(iCM),
        write_data      => reg_data(iCM*16 + 16)(7 downto 0),
        write_en        => uart_wr_en(iCM),
        write_half_full => uart_wr_half_full(iCM),
        write_full      => uart_wr_full(iCM),
        read_data       => uart_rd_data(iCM),
        read_en         => uart_rd_en(iCM),
        read_available  => uart_rd_available(iCM),
        read_half_full  => uart_rd_half_full(iCM),
        read_full       => uart_rd_full(iCM));             
  end generate CM_UARTs;
  -------------------------------------------------------------------------------
  -- AXI 
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  AXIRegBridge : entity work.axiLiteReg
    port map (
      clk_axi     => clk_axi,
      reset_axi_n => reset_axi_n,
      readMOSI    => readMOSI,
      readMISO    => readMISO,
      writeMOSI   => writeMOSI,
      writeMISO   => writeMISO,
      address     => localAddress,
      rd_data     => localRdData_latch,
      wr_data     => localWrData,
      write_en    => localWrEn,
      read_req    => localRdReq,
      read_ack    => localRdAck);

  latch_reads: process (clk_axi) is
  begin  -- process latch_reads
    if clk_axi'event and clk_axi = '1' then  -- rising clock edge
      if localRdReq = '1' then
        localRdData_latch <= localRdData;        
      end if;
    end if;
  end process latch_reads;

  enableCM        (0) <= reg_data(0)(0); --CM1 enabled
  enableCM_PWR    (0) <= reg_data(0)(1); --CM1 power eneable
  override_PWRGood(0) <= reg_data(0)(2); --CM1 override
  enableCM        (1) <= reg_data(1)(0); --CM2 enabled
  enableCM_PWR    (1) <= reg_data(1)(1); --CM2 power eneable
  override_PWRGood(1) <= reg_data(1)(2); --CM2 override

  reads: process (localRdReq,localAddress,reg_data) is
  begin  -- process reads
    localRdAck  <= '0';
    localRdData <= x"00000000";
    if localRdReq = '1' then
      localRdAck  <= '1';
      case localAddress(7 downto 0) is
        when x"0" =>
          --control
          localRdData( 2 downto  0) <= reg_data(0)( 2 downto  0);
          --pwr good
          localRdData( 3)           <= PWR_good(0);
          --pwr state
          localRdData( 7 downto  4) <= CM_seq_state(3 downto 0);
          --pwr state outputs
          localRdData( 8)            <= enable_uC(0);
          localRdData( 9)            <= enable_PWR(0);
          localRdData(10)            <= enable_IOs(0);
        when x"1" =>
          --control
          localRdData( 2 downto  0) <= reg_data(1)( 2 downto  0);
          --pwr good
          localRdData( 3)           <= PWR_good(1);
          --pwr state
          localRdData( 7 downto  4) <= CM_seq_state(7 downto 4);
          --pwr state outputs
          localRdData( 8)            <= enable_uC(1);
          localRdData( 9)            <= enable_PWR(1);
          localRdData(10)            <= enable_IOs(1);
        when x"10" =>
          localRdData( 7 downto  0) <= reg_data(16)( 7 downto  0);
          localRdData(13) <= uart_wr_half_full(0);
          localRdData(14) <= uart_wr_full(0);
        when x"11" =>
          localRdData( 7 downto  0) <= uart_rd_data(0);
          localRdData(12) <= uart_rd_available(0);
          localRdData(13) <= uart_rd_half_full(0);
          localRdData(14) <= uart_rd_full(0);
        when x"12" =>
          localRdData(0) <= CM1_C2C_Mon.axi_c2c_config_error_out;   
          localRdData(1) <= CM1_C2C_Mon.axi_c2c_link_error_out;     
          localRdData(2) <= CM1_C2C_Mon.axi_c2c_link_status_out;    
          localRdData(3) <= CM1_C2C_Mon.axi_c2c_multi_bit_error_out;
          localRdData(4) <= CM1_C2C_Mon.aurora_do_cc;
          localRdData(5) <= reg_data(18)(5);
          
          localRdData(8) <= CM1_C2C_Mon.phy_link_reset_out;     
          localRdData(9) <= CM1_C2C_Mon.phy_gt_pll_lock;        
          localRdData(10) <= CM1_C2C_Mon.phy_mmcm_not_locked_out;
          localRdData(12 + CM1_C2C_Mon.phy_lane_up'length -1 downto 12) <= CM1_C2C_Mon.phy_lane_up;
          localRdData(16) <= CM1_C2C_Mon.phy_hard_err;           
          localRdData(17) <= CM1_C2C_Mon.phy_soft_err;

          localRdData(20) <= CM1_C2C_Mon.cplllock;
          localRdData(21) <= CM1_C2C_Mon.eyescandataerror;
          localRdData(22) <= reg_data(18)(22); --eyescanreset;
          localRdData(23) <= reg_data(18)(23); --eyescantrigger;
          localRdData(31 downto 24) <= CM1_C2C_Mon.dmonitorout;

        when x"13" =>
          localRdData( 2 downto  0) <= CM1_C2C_Mon.rxbufstatus;
          localRdData( 9 downto  3) <= CM1_C2C_Mon.rxmonitorout;     
          localRdData(10) <= CM1_C2C_Mon.rxprbserr;        
          localRdData(11) <= CM1_C2C_Mon.rxresetdone;                
          localRdData(12) <= reg_data(19)(12);  --rxbufreset;       
          localRdData(13) <= reg_data(19)(13);  --rxcdrhold;        
          localRdData(14) <= reg_data(19)(14);  --rxdfeagchold;     
          localRdData(15) <= reg_data(19)(15);  --rxdfeagcovrden;   
          localRdData(16) <= reg_data(19)(16);  --rxdfelfhold;      
          localRdData(17) <= reg_data(19)(17);  --rxdfelpmreset;    
          localRdData(18) <= reg_data(19)(18);  --rxlpmen;          
          localRdData(19) <= reg_data(19)(19);  --rxlpmhfovrden;    
          localRdData(20) <= reg_data(19)(20);  --rxlpmlfklovrden;  
          localRdData(22 downto 21) <= reg_data(19)(22 downto 21); --rxmonitorsel;     
          localRdData(23) <= reg_data(19)(23);  --rxpcsreset;       
          localRdData(24) <= reg_data(19)(24);  --rxpmareset;       
          localRdData(25) <= reg_data(19)(25);  --rxprbscntreset;   
          localRdData(28 downto 26) <= reg_data(19)(28 downto 26); --rxprbssel;        
        when x"14" =>
          localRdData( 1 downto  0) <= CM1_C2C_Mon.txbufstatus;
          localRdData( 2)           <= CM1_C2C_Mon.txresetdone;
          localRdData( 6 downto  3) <= reg_data(20)( 6 downto  3);  --txdiffctrl;
          localRdData( 7)           <= reg_data(20)( 7)          ;  --txinhibit;
          localRdData(14 downto  8) <= reg_data(20)(14 downto  8);  --txmaincursor;
          localRdData(15)           <= reg_data(20)(15)          ;  --txpcsreset;    
          localRdData(16)           <= reg_data(20)(16)          ;  --txpmareset;    
          localRdData(17)           <= reg_data(20)(17)          ;  --txpolarity;    
          localRdData(22 downto 18) <= reg_data(20)(22 downto 18);  --txpostcursor;  
          localRdData(23)           <= reg_data(20)(23)          ;  --txprbsforceerr;
          localRdData(26 downto 24) <= reg_data(20)(26 downto 24);  --txprbssel;     
          localRdData(31 downto 27) <= reg_data(20)(31 downto 27);  --txprecursor;
        when x"20" =>
          localRdData( 7 downto  0) <= reg_data(32)( 7 downto  0);
          localRdData(13) <= uart_wr_half_full(1);
          localRdData(14) <= uart_wr_full(1);
        when x"21" =>
          localRdData( 7 downto  0) <= uart_rd_data(1);
          localRdData(12) <= uart_rd_available(1);
          localRdData(13) <= uart_rd_half_full(1);
          localRdData(14) <= uart_rd_full(1);
        when x"22" =>
          localRdData(0) <= CM2_C2C_Mon.axi_c2c_config_error_out;   
          localRdData(1) <= CM2_C2C_Mon.axi_c2c_link_error_out;     
          localRdData(2) <= CM2_C2C_Mon.axi_c2c_link_status_out;    
          localRdData(3) <= CM2_C2C_Mon.axi_c2c_multi_bit_error_out;
          localRdData(4) <= CM2_C2C_Mon.aurora_do_cc;
          localRdData(5) <= reg_data(34)(5);
          
          localRdData(8) <= CM2_C2C_Mon.phy_link_reset_out;     
          localRdData(9) <= CM2_C2C_Mon.phy_gt_pll_lock;        
          localRdData(10) <= CM2_C2C_Mon.phy_mmcm_not_locked_out;
          localRdData(12 + CM2_C2C_Mon.phy_lane_up'length -1 downto 12) <= CM2_C2C_Mon.phy_lane_up;
          localRdData(16) <= CM2_C2C_Mon.phy_hard_err;           
          localRdData(17) <= CM2_C2C_Mon.phy_soft_err;                                       

        when others =>
          localRdData <= x"00000000";
      end case;
    end if;
  end process reads;


  CM1_C2C_Ctrl.aurora_pma_init_in <= reg_data(18)(5);
  CM2_C2C_Ctrl.aurora_pma_init_in <= reg_data(34)(5);
  CM1_C2C_Ctrl.eyescanreset    <=  reg_data(18)(22); 
  CM1_C2C_Ctrl.eyescantrigger  <=  reg_data(18)(23);
  CM1_C2C_Ctrl.rxbufreset      <=  reg_data(19)(12);           
  CM1_C2C_Ctrl.rxcdrhold       <=  reg_data(19)(13);           
  CM1_C2C_Ctrl.rxdfeagchold    <=  reg_data(19)(14);           
  CM1_C2C_Ctrl.rxdfeagcovrden  <=  reg_data(19)(15);           
  CM1_C2C_Ctrl.rxdfelfhold     <=  reg_data(19)(16);           
  CM1_C2C_Ctrl.rxdfelpmreset   <=  reg_data(19)(17);           
  CM1_C2C_Ctrl.rxlpmen         <=  reg_data(19)(18);           
  CM1_C2C_Ctrl.rxlpmhfovrden   <=  reg_data(19)(19);           
  CM1_C2C_Ctrl.rxlpmlfklovrden <=  reg_data(19)(20);           
  CM1_C2C_Ctrl.rxmonitorsel    <=  reg_data(19)(22 downto 21); 
  CM1_C2C_Ctrl.rxpcsreset      <=  reg_data(19)(23);           
  CM1_C2C_Ctrl.rxpmareset      <=  reg_data(19)(24);           
  CM1_C2C_Ctrl.rxprbscntreset  <=  reg_data(19)(25);           
  CM1_C2C_Ctrl.rxprbssel       <=  reg_data(19)(28 downto 26); 
  CM1_C2C_Ctrl.txdiffctrl      <=  reg_data(20)( 6 downto  3); 
  CM1_C2C_Ctrl.txinhibit       <=  reg_data(20)( 7);           
  CM1_C2C_Ctrl.txmaincursor    <=  reg_data(20)(14 downto  8); 
  CM1_C2C_Ctrl.txpcsreset      <=  reg_data(20)(15);           
  CM1_C2C_Ctrl.txpmareset      <=  reg_data(20)(16);           
  CM1_C2C_Ctrl.txpolarity      <=  reg_data(20)(17);           
  CM1_C2C_Ctrl.txpostcursor    <=  reg_data(20)(22 downto 18); 
  CM1_C2C_Ctrl.txprbsforceerr  <=  reg_data(20)(23);           
  CM1_C2C_Ctrl.txprbssel       <=  reg_data(20)(26 downto 24);
  CM1_C2C_Ctrl.txprecursor     <=  reg_data(20)(31 downto 27); 
  
  reg_writes: process (clk_axi, reset_axi_n) is
  begin  -- process reg_writes
    if reset_axi_n = '0' then                 -- asynchronous reset (active high)
      reg_data <= default_reg_data;
    elsif clk_axi'event and clk_axi = '1' then  -- rising clock edge
      uart_wr_en <= (others => '0');
      uart_rd_en <= (others => '0');
      if localWrEn = '1' then
        case localAddress(7 downto 0) is
          when x"0" =>
            reg_data(0)( 2 downto  0) <= localWrData(2 downto 0);
          when x"1" =>
            reg_data(1)( 2 downto  0) <= localWrData(2 downto 0);
          when x"10" =>
            reg_data(16)(7 downto 0) <= localWrData(7 downto 0);
            uart_wr_en(0) <= '1';
          when x"11" =>
            uart_rd_en(0) <= '1';
          when x"12" =>
            reg_data(18)(5)  <= localWrData(5);
            reg_data(18)(22) <= localWrData(22); --eyescanreset;
            reg_data(18)(23) <= localWrData(23); --eyescantrigger;

          when x"13" =>
            reg_data(19)(12)           <= localWrData(12);           --rxbufreset;       
            reg_data(19)(13)           <= localWrData(13);           --rxcdrhold;        
            reg_data(19)(14)           <= localWrData(14);           --rxdfeagchold;     
            reg_data(19)(15)           <= localWrData(15);           --rxdfeagcovrden;   
            reg_data(19)(16)           <= localWrData(16);           --rxdfelfhold;      
            reg_data(19)(17)           <= localWrData(17);           --rxdfelpmreset;    
            reg_data(19)(18)           <= localWrData(18);           --rxlpmen;          
            reg_data(19)(19)           <= localWrData(19);           --rxlpmhfovrden;    
            reg_data(19)(20)           <= localWrData(20);           --rxlpmlfklovrden;  
            reg_data(19)(22 downto 21) <= localWrData(22 downto 21); --rxmonitorsel;     
            reg_data(19)(23)           <= localWrData(23);           --rxpcsreset;       
            reg_data(19)(24)           <= localWrData(24);           --rxpmareset;       
            reg_data(19)(25)           <= localWrData(25);           --rxprbscntreset;   
            reg_data(19)(28 downto 26) <= localWrData(28 downto 26); --rxprbssel;        
          when x"14" =>
            reg_data(20)( 6 downto  3) <= localWrData( 6 downto  3); --txdiffctrl;
            reg_data(20)( 7)           <= localWrData( 7);           --txinhibit;
            reg_data(20)(14 downto  8) <= localWrData(14 downto  8); --txmaincursor;
            reg_data(20)(15)           <= localWrData(15);           --txpcsreset;    
            reg_data(20)(16)           <= localWrData(16);           --txpmareset;    
            reg_data(20)(17)           <= localWrData(17);           --txpolarity;    
            reg_data(20)(22 downto 18) <= localWrData(22 downto 18); --txpostcursor;  
            reg_data(20)(23)           <= localWrData(23);           --txprbsforceerr;
            reg_data(20)(26 downto 24) <= localWrData(26 downto 24); --txprbssel;     
            reg_data(20)(31 downto 27) <= localWrData(31 downto 27); --txprecursor;
            
          when x"20" =>
            reg_data(32)(7 downto 0) <= localWrData(7 downto 0);
            uart_wr_en(1) <= '1';
          when x"21" =>
            uart_rd_en(1) <= '1';
          when x"22" =>
            reg_data(34)(5)  <= localWrData(5);
          when others => null;
        end case;
      end if;
    end if;
  end process reg_writes;
  -------------------------------------------------------------------------------


  

  
end architecture behavioral;
