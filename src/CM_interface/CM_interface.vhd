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
  

  signal reg_data :  slv32_array_t(integer range 0 to 15);
  constant Default_reg_data : slv32_array_t(integer range 0 to 15) := (0 => x"00000000",
                                                                       others => x"00000000");


  signal enableCM : std_logic_vector(1 downto 0);
  signal CM1_disable : std_logic;
  signal CM2_disable : std_logic;
  signal overridePWRGood : std_logic_vector(1 downto 0);

  signal baud_counter : unsigned(4 downto 0);
  constant baud_counter_end : unsigned(4 downto 0) := "11010";
  signal en_16_x_baud : std_logic;
  signal CM1_tx : std_logic;
  
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
      I => CM1_tx,
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
      I => to_CM2_in.UART_Tx,
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

  baud_counter_proc: process (clk_axi) is
  begin  -- process baud_counter
    if clk_axi'event and clk_axi = '1' then  -- rising clock edge
      en_16_x_baud <= '0';
      if baud_counter = baud_counter_end then
        baud_counter <= (others => '0');
        en_16_x_baud <= '1';
      else
        baud_counter <= baud_counter + 1;  
      end if;
      
    end if;
  end process baud_counter_proc;
  uart_tx6_1: entity work.uart_tx6
    port map (
      data_in             => reg_data(1)(7 downto 0),
      en_16_x_baud        => en_16_x_baud,
      serial_out          => CM1_tx,
      buffer_write        => reg_data(1)(8),
      buffer_data_present => open,
      buffer_half_full    => open,
      buffer_full         => open,
      buffer_reset        => '0',
      clk                 => clk_axi);
  
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
      reg_data(1)(8) <= '0';
      if localWrEn = '1' then
        case localAddress(3 downto 0) is
          when x"0" =>
            reg_data(0)( 3 downto  0) <= localWrData(3 downto 0);
          when x"1" =>
            reg_data(1)(7 downto 0) <= localWrData(7 downto 0);
            reg_data(1)(8) <= '1';
          when others => null;
        end case;
      end if;
    end if;
  end process reg_writes;
  -------------------------------------------------------------------------------


  

  
end architecture behavioral;
