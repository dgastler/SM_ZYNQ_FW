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
    from_CM1        :  in from_CM_t;
    from_CM2        :  in from_CM_t;
    to_CM1_in       :  in to_CM_t;  --from SM
    to_CM2_in       :  in to_CM_t;  --from SM
    to_CM1_out      : out to_CM_t;  --from SM, but tristated
    to_CM2_out      : out to_CM_t   --from SM, but tristated


    
    
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
                                                                       others => x"00000000");


  signal enableCM : std_logic_vector(1 downto 0);
  signal CM1_disable : std_logic;
  signal CM2_disable : std_logic;
  signal overridePWRGood : std_logic_vector(1 downto 0);


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

  -------------------------------------------------------------------------------
  -- CM interface
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------  
  --CM1
  CM1_UART_BUF : OBUFT
    port map (
      T => CM1_disable,
--      I => to_CM1_in.UART_Tx,
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


  enableCM1 <= enableCM(0);
  enableCM2 <= enableCM(1);
  CM_powerup: process (enableCM(0),enableCM(1),from_CM1.PWR_good,from_CM2.PWR_good) is
  begin  -- process CM_powerup
      CM1_disable <= '1';
      if enableCM(0) = '1' then
        CM1_disable <= (from_CM1.PWR_good and (not overridePWRGood(0)));
--        CM1_disable <= (not from_CM1.PWR_good) and (not overridePWRGood(0));
      end if;

      CM2_disable <= '1';
      if enableCM(1) = '1' then
        CM2_disable <= (from_CM2.PWR_good and (not overridePWRGood(1)));
        --CM2_disable <= (not from_CM2.PWR_good) and (not overridePWRGood(1));
      end if;
  end process CM_powerup;


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

  enableCM       ( 1 downto  0) <= reg_data(0)(1 downto 0); --CM1/2 enabled
  overridePWRGood( 1 downto  0) <= reg_data(0)(3 downto 2); --CM1/2 override
                                                            --power good
  reads: process (localRdReq,localAddress,reg_data) is
  begin  -- process reads
    localRdAck  <= '0';
    localRdData <= x"00000000";
    if localRdReq = '1' then
      localRdAck  <= '1';
      case localAddress(3 downto 0) is
        when x"0" =>
          localRdData( 3 downto  0) <= reg_data(0)( 3 downto  0);
          localRdData( 4) <= not CM1_disable;  -- CM1 outputs enabled
          localRdData( 5) <= not CM2_disable;  -- CM2 outputs enabled
        when x"10" =>
          localRdData( 7 downto  0) <= reg_data(16)( 7 downto  0);
          localRdData(13) <= uart_wr_half_full(0);
          localRdData(14) <= uart_wr_full(0);
        when x"11" =>
          localRdData( 7 downto  0) <= uart_rd_data(0);
          localRdData(12) <= uart_rd_available(0);
          localRdData(13) <= uart_rd_half_full(0);
          localRdData(14) <= uart_rd_full(0);
        when x"20" =>
          localRdData( 7 downto  0) <= reg_data(32)( 7 downto  0);
          localRdData(13) <= uart_wr_half_full(1);
          localRdData(14) <= uart_wr_full(1);
        when x"21" =>
          localRdData( 7 downto  0) <= uart_rd_data(1);
          localRdData(12) <= uart_rd_available(1);
          localRdData(13) <= uart_rd_half_full(1);
          localRdData(14) <= uart_rd_full(1);
        when others =>
          localRdData <= x"00000000";
      end case;
    end if;
  end process reads;

  reg_writes: process (clk_axi, reset_axi_n) is
  begin  -- process reg_writes
    if reset_axi_n = '0' then                 -- asynchronous reset (active high)
      reg_data <= default_reg_data;
    elsif clk_axi'event and clk_axi = '1' then  -- rising clock edge
      uart_wr_en <= (others => '0');
      uart_rd_en <= (others => '0');
      if localWrEn = '1' then
        case localAddress(3 downto 0) is
          when x"0" =>
            reg_data(0)( 3 downto  0) <= localWrData(3 downto 0);
          when x"10" =>
            reg_data(16)(7 downto 0) <= localWrData(7 downto 0);
            uart_wr_en(0) <= '1';
          when x"11" =>
            uart_rd_en(0) <= '1';
          when x"20" =>
            reg_data(16)(7 downto 0) <= localWrData(7 downto 0);
            uart_wr_en(0) <= '1';
          when x"21" =>
            uart_rd_en(0) <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process reg_writes;
  -------------------------------------------------------------------------------


  

  
end architecture behavioral;
