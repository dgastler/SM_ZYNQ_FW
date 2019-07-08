----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/25/2019 04:31:24 PM
-- Design Name: 
-- Module Name: FrontGrande - Behavioral
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
library IEEE; --to use std_logic_vector for my_array package
use IEEE.STD_LOGIC_1164.ALL;

--Package for the array
package my_array is 
    type the_array is array(0 to 63) of std_logic_vector(7 downto 0);
end package my_array;

library IEEE; --Have to repeat, no clue why though
use IEEE.STD_LOGIC_1164.ALL;
use work.my_array.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;


entity FrontPanel_UI is
    generic (CLKFREQ        : integer := 100000000; --frequency of onboard clock signal in hz 
             REG_COUNT      : integer := 10); --how many entries are in the Darray
    Port    (clk            : in std_logic; --onboard clk
             reset          : in std_logic; --reset system
             buttonin       : in std_logic; --short press = load, long press = flash, two = print
             --display_regs   : in slv8_array_t(0 to REG_COUNT-1) := (others => x"00");
             LEDout         : out std_logic_vector (7 downto 0); --data out from register
             busy           : out std_logic; --indicates readout is active
             SCK            : out std_logic; --the "effective clk" of the readout
             SDA            : out std_logic;--); --value being readout at SCK
             --for testing, delete all ports below this line
             tshort         : out std_logic;
             tlong          : out std_logic;
             ttwo           : out std_logic);
end FrontPanel_UI;

architecture Behavioral of FrontPanel_UI is

--signals for transmisitting across components
signal short    : std_logic;
signal long     : std_logic;
signal two      : std_logic;
--shift reg for readout
signal shiftreg : std_logic_vector (7 downto 0);
--1 bit logic
signal shifty   : std_logic; --used for shifting shiftreg
signal SCK2     : std_logic; --used to buffer SCK
signal SDA2     : std_logic; --used to buffer SDA
--constants for timing
constant steps  : integer := CLKFREQ / 1000000; --this makes SCK run at 1 Mhz, 10 us for a full readout, --2 does work
--kinda a placeholder, may go away
signal dataout : std_logic_vector (7 downto 0);
--counter for testing, delete these signals
signal count : integer range 0 to CLKFREQ; --del
signal hold  : std_logic;  --del

--The data
signal data : the_array := (
0 => x"01",
1 => x"02",
2 => x"03",
3 => x"04",
4 => x"05",
5 => x"06",
6 => x"07",
7 => x"08",
8 => x"09",
9 => x"0A", others => x"FF");

--Declare TriButton
component Button_Decoder
    generic (CLKFREQ    : integer);
    port    (clk        : in std_logic;
             reset      : in std_logic;
             buttonin   : in std_logic;
             short      : out std_logic;
             long       : out std_logic;
             two        : out std_logic);
end component; --end TriButton

--Declare LED_Encoder
component LED_Encoder
    generic (CLKFREQ    : integer;
             STEPS      : integer;
             REG_COUNT  : integer);
    port    (clk        : in std_logic;
             reset      : in std_logic;
             data       : in the_array;
             load       : in std_logic;
             prev       : in std_logic;
             flash      : in std_logic;
             dataout    : out std_logic_vector (7 downto 0);
             busy       : out std_logic;
             SCK        : out std_logic;
             SDA        : out std_logic);
end component; --end LED_Encoder

begin

TB1 : Button_Decoder --using triButton
    generic map (CLKFREQ    => CLKFREQ)
    port map    (clk        => clk,
                 reset      => reset,
                 buttonin   => buttonin,
                 short      => short,
                 long       => long,
                 two        => two);
                                
L1 : LED_Encoder --using LED_Encoder
    generic map (CLKFREQ    => CLKFREQ,
                 STEPS      => STEPS,
                 REG_COUNT  => REG_COUNT)
    port map    (clk        => clk,
                 reset      => reset,
                 data       => data,
                 load       => short,--short, --moves to the next register value
                 prev       => two,--two --displays the current position in the register
                 flash      => long, --long --blinks the current value
                 dataout    => dataout,
                 busy       => busy,
                 SCK        => SCK2,
                 SDA        => SDA2);
                   
--continuout
LEDout <= shiftreg(0) & shiftreg(1) & shiftreg(2) & shiftreg(3) & shiftreg(4) & shiftreg(5) & shiftreg(6) & shiftreg(7);
SCK <= SCK2;
SDA <= SDA2;
                   
Shifting : process (clk, reset)
begin
    if reset = '1' then
        shifty <= '0';
        shiftreg <= X"00";
    elsif clk'event and clk='1' then
        if SCK2 = '1' then
            if shifty = '1' then
                shiftreg <= SDA2 & shiftreg (7 downto 1);
                shifty <= '0';
            end if;  
        else
            shifty <= '1';
            shiftreg <= shiftreg;
        end if;
    end if;
end process;
              
--for testing --delete all below this line

ButtonHolding: process (clk, reset)
begin
    if reset = '1' then
        hold <= '0';
        count <= 0;
    
    elsif clk'event and clk='1' then
    
        if hold = '0' then
            if short = '1' then
                tshort <= '1';
                hold <= '1';
            elsif long = '1' then
                tlong <= '1';
                hold <= '1';
            elsif two = '1' then
                ttwo <= '1';
                hold <= '1';
            else
                tshort <= '0';
                tlong <= '0';
                ttwo <= '0';
                hold <= '0';
                count <= 0;
            end if;
        else
            count <= count + 1;
            if count = (clkfreq / 10) then
                count <= 0;
                hold <= '0';
            end if;
        end if;
    end if;
end process;
end Behavioral;
