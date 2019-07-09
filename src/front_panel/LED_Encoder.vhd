----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/20/2019 11:47:20 AM
-- Design Name: 
-- Module Name: Loader - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.ALL;

entity LED_Encoder is
    generic (CLKFREQ        : integer; --onboad clock frequency in hz
             STEPS          : integer; --how many clk ticks corresond to a SCK tick
             REG_COUNT      : integer range 1 to 64;  --how many entries are in the array 
             FLASHLENGTH    : integer; --how many seconds do you want it to flash for
             FLASHRATE      : integer);  --how many times do you want it to flash per second
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             addressin : in unsigned (5 downto 0);
             force_address : in std_logic;
             data       : in slv8_array_t(0 to (REG_COUNT - 1));
             load       : in std_logic; --moves to the next register value
             prev       : in std_logic; --displays the current position in the register
             flash      : in std_logic; --blinks the current value
             dataout    : out std_logic_vector (7 downto 0);
             addressout : out unsigned (5 downto 0);
             SCK        : out std_logic;
             SDA        : out std_logic);
end LED_Encoder;

architecture Behavioral of LED_Encoder is

--State Machine
type states is (IDLE,   --Idle
                PRINT,  --Print current value
                BLINK); --Blink position         
signal State : states;
--register for loading data
signal LoadData     : std_logic_vector(7 downto 0);
--1-bit signals
signal update       : std_logic; --used to update
signal active       : std_logic; --used to buffer busy output, never assign directly to this
signal flashbit     : std_logic; --used for flashing data or 0
--constants for timing
constant refresh        : integer := (CLKFREQ / 100); --refresh every 10 ms,
constant flashtiming    : integer := (CLKFREQ / (2 * FLASHRATE)); --the rate which the flash happens
constant endflash       : integer := (2 * (FLASHRATE + 3));
--counters
signal position         : unsigned (5 downto 0); --to count position in register
signal count            : integer range 0 to (CLKFREQ / 2); --for general purpose counting
signal flashcount       : integer range 0 to (endflash + 1); --to count the amount of times flashed


--Declare SR_out
component SR_Out
    generic (STEPS      : integer);
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             datain     : in std_logic_vector (7 downto 0);
             update     : in std_logic;
             dataout    : out std_logic_vector (7 downto 0);         
             busy       : out std_logic;
             SCK        : out std_logic;
             SDA        : out std_logic);
end component; --end SR_out

begin

--continuous outputs
addressout <= position;


U1 : SR_Out --using SR_Out
    generic map (STEPS      => STEPS)
    port map    (clk        => clk,
                 reset      => reset,
                 datain     => LoadData,
                 update     => update,
                 dataout    => dataout,
                 busy       => active,
                 SCK        => SCK,
                 SDA        => SDA);
              
--continuous assignment of outputs
--busy <= active;

--This process manages the position within the register
Shift: process (clk, reset)
begin
  if reset = '1' then
    position <= "000000";

  elsif clk'event and clk='1' then
  
    if force_address = '1' then
        position <= addressin;
        
    elsif state /= BLINK then
      if load = '1' then
        if to_integer(position) = (REG_COUNT - 1) then
          position <= "000000";
        else
          position <= position + 1;
        end if;
      elsif prev = '1' then
        if position = "000000" then
          position <= to_unsigned((REG_COUNT - 1), 6);
        else
          position <= position - 1;
        end if;
      end if;
    else
      position <= position;
    end if; --end position movement
  end if; --end clk & reset
end process; --end position process

        
--This process is for the functionality of each state
StateFcn3: process (clk, reset)
begin
  
  if reset = '1' then
    --set signals low
    flashbit <= '0';
    update <= '0';
    --reset counters
    count <= 0;
    flashcount <= 0;
    
  elsif clk'event and clk='1' then
    --state machine
    case State is
      when IDLE => 
        if flash = '1' then
          --reset count if moving to BLINK b/c flash is high
          count <= 0;
          flashbit <= '0';
          flashcount <= 0;
        else --if not going to BLINK
          --increment count
          count <= count + 1;
          if count = refresh then --at refrestrate
            --load data, set update high
            loaddata <= data(to_integer(position));
            update <= '1';
          end if;
        end if;
        
      when PRINT => --set update low and reset count
        update <= '0'; 
        count <= 0;
        
      when BLINK =>

        if active = '1' then
            update <= '0';
        else
            count <= count + 1;
            if count = flashtiming then
                count <= 0;
                flashcount <= flashcount + 1;
                if flashcount = 0 then   --all 1's first flash
                    loaddata <= X"FF";
                    update <= '1';
                elsif flashcount = endflash then
                    loaddata <= X"FF";
                    update <= '1';
                elsif flashbit = '1' then --if flashbit = "1' then
                    loaddata <= "00" & std_logic_vector(position);
                    update <= '1';
                    flashbit <= not flashbit;
                else
                    loaddata <= X"00";
                    update <= '1';
                    flashbit <= not flashbit;
                end if;
            end if;
        end if;
  
      when others =>
        null;
        
    end case; --end state machine
  end if; --end clk & reset
end process; --end StateFcn3

--This process is for the transitions between states
StateFlow3: process (clk, reset)
begin

  --reset
  if reset = '1' then
    State <= IDLE;

  elsif clk'event and clk='1' then
    --state machine
    case State is
      when IDLE =>
        --if flash is high go to BLINK
        if flash = '1' then
          state <= BLINK;
        --if readout is active, move to PRINT state
        elsif active = '1' then
          State <= PRINT;
        end if;

      when PRINT =>
        --return to IDLE after readout completes
        if active = '0' then
          State <= IDLE;
        end if;

      when BLINK =>
        if flashcount = (endflash + 1) then
            State <= IDLE;
        end if;
        

      when others => --if broken, go to IDLE
        State <= IDLE;
        
    end case; --end state machine
  end if; --end clk & reset
end process; --end stateFcn3
end Behavioral; --end it all

