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
use IEEE.NUMERIC_STD.ALL; -- arithmetic functions with Signed or Unsigned values

entity Loader is
    generic (clkfreq    : integer := 100000000; --onboad clock frequency in hz
             steps      : integer := 4; --how many clk ticks corresond to a SCK tick
             max        : integer range 1 to 64 := 10); --how many entries are in the Darray
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             load       : in std_logic; --moves to the next register value
             prev       : in std_logic; --displays the current position in the register
             flash      : in std_logic; --blinks the current value
             dataout    : out std_logic_vector (7 downto 0);
             busy       : out std_logic;
             SCK        : out std_logic;
             SDA        : out std_logic);
end Loader;

architecture Behavioral of Loader is

--array of 64 8-bit registers
type Darray is array(0 to 63) of std_logic_vector(7 downto 0);
signal data : Darray := (
0 => x"0A",
1 => x"0B",
2 => x"0C",
3 => x"0D",
4 => x"0E",
5 => x"0F",
6 => x"A0",
7 => x"B0",
8 => x"C0",
9 => x"D0",
others => x"FF"
);

--State Machine
type states is (IDLE,   --Idle
                  PRINT,  --Print current value
                  BLINK); --Blink position         
signal State : states;

--register for loading data
signal LoadData : std_logic_vector(7 downto 0);

--1-bit signals
signal update: std_logic; --used to update
signal active: std_logic; --used to buffer busy output, never assign directly to this
signal flashbit: std_logic; --used for flashing data or 0

--counters
signal position: unsigned (5 downto 0); --to count position in register
signal count : integer range 0 to clkfreq;

--constants for timing
signal refresh : integer := (clkfreq / 10); --1/10th of a second
signal flashrate : integer := (clkfreq / 2); --half a second

--Declare SR_out
component SR_out
    generic (steps : integer);
    Port (clk       : in std_logic;
          reset     : in std_logic;
          datain    : in std_logic_vector (7 downto 0);
          update    : in std_logic;
          dataout   : out std_logic_vector (7 downto 0);         
          busy      : out std_logic;
          SCK       : out std_logic;
          SDA       : out std_logic);
end component;

begin

--using SR_out
U1 : SR_out
    generic map (steps => 4)
    port map (clk => clk,
              reset => reset,
              datain => LoadData,
              update => update,
              dataout => dataout,
              busy => active,
              SCK => SCK,
              SDA => SDA);
              
--continuous assignment of outputs
busy <= active;

--This process manages the position within the register
Shift: process (clk, reset)
begin
  if reset = '1' then
    position <= "000000";

  elsif clk'event and clk='1' then
    if state /= BLINK then
      if load = '1' then
        if to_integer(position) = (max - 1) then
          position <= "000000";
        else
          position <= position + 1;
        end if;
      elsif prev = '1' then
        if position = "000000" then
          position <= to_unsigned((max - 1), 6);
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
    --reset count
    count <= 0;
    
  elsif clk'event and clk='1' then
    --state machine
    case State is
      when IDLE => 
        if flash = '1' then
          --reset count if moving to BLINK b/c flash is high
          count <= 0;
          flashbit <= '0';
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
          update <= '0'; --set update low
        else
          if flash <= '0' then
            count <= 0; --if not in 
          else
            count <= count + 1;
            if count = flashrate then
              count <= 0; --reset count
              flashbit <= not flashbit; --flip flashbit
              if flashbit = '1' then --load position
                loaddata <= "00" & std_logic_vector(position);
                update <= '1';
              else --load 0
                loaddata <= X"00";
                update <= '1';
              end if;
            end if;
          end if;
        end if;
  
      when others =>
        null;
        
    end case; --end state machine
  end if; --end clk & reset
end process; --end StateFcn3

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
        --return to IDLE when flash is turned off
        if flash = '0' then
          state <= IDLE;
        end if;

      when others => --if broken, go to IDLE
        State <= IDLE;
        
    end case; --end state machine
  end if; --end clk & reset
end process; --end stateFcn3
end Behavioral; --end it all

