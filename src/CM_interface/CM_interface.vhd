library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.AXIRegPkg.all;

use work.types.all;
use work.CM_package.all;

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
  constant Default_reg_data : slv32_array_t(integer range 0 to 15) := (0 => x"00000003",
                                                                       4 => x"00000001",
                                                                       5 => x"00001010",
                                                                       8 => x"00000000",
                                                                       others => x"00000000");



  signal CM1_disable : std_logic;
  signal CM2_disable : std_logic;
begin  -- architecture behavioral

  -------------------------------------------------------------------------------
  -- CM interface
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------  
  --CM1
  CM1_UART_BUF : OBUFT
    port map (
      T => CM1_disable,
      I => to_CM1_in.UART_Tx,
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


  CM_powerup: process (enableCM1,enableCM2,from_CM1.PWR_good,from_CM2.PWR_good) is
  begin  -- process CM_powerup
      CM1_disable <= '1';
      if enableCM1 = '1' then
        CM1_disable <= not from_CM1.PWR_good;
      end if;

      CM2_disable <= '1';
      if enableCM2 = '1' then
        CM2_disable <= not from_CM2.PWR_good;
      end if;
  end process CM_powerup;
  
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
  
  reads: process (localRdReq,localAddress,reg_data) is
  begin  -- process reads
    localRdAck  <= '0';
    localRdData <= x"00000000";
    if localRdReq = '1' then
      localRdAck  <= '1';
      case localAddress(3 downto 0) is
        when x"0" => NULL;
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
      if localWrEn = '1' then
        case localAddress(3 downto 0) is
          when x"0" => NULL;
          when others => null;
        end case;
      end if;
    end if;
  end process reg_writes;
  -------------------------------------------------------------------------------


  

  
end architecture behavioral;
