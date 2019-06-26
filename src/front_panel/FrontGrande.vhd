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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FrontGrande is
    generic (clkfreq        : integer := 100000000; --frequency of onboard clock signal in hz 
             pulselength    : integer := 1; --how many clk ticks do you want an output to be high for
             steps          : integer := 10000000;--how many clk ticks corresond to a SCK tick --consider basing off of clkfreq
             max            : integer := 10); --how many entries are in the Darray
    Port    (clk            : in std_logic; --onboard clk
             reset          : in std_logic; --reset system
             buttonin       : in std_logic; --short press = load, long press = flash, two = print
             dataout        : out std_logic_vector (7 downto 0); --data out from register
             busy           : out std_logic; --indicates readout is active
             SCK            : out std_logic; --the "effective clk" of the readout
             SDA            : out std_logic;--); --value being readout at SCK
             --for testing
             tshort         : out std_logic;
             tlong          : out std_logic;
             ttwo           : out std_logic);
end FrontGrande;

architecture Behavioral of FrontGrande is

--signals for transmisitting across components
signal short    : std_logic;
signal long     : std_logic;
signal two      : std_logic;
--signal for treating a long press like a switch
signal flipper  : std_logic;

--Declare TriButton
component TriButton
    generic (clkfreq        : integer;
             pulselength    : integer);
    port    (clk            : in std_logic;
             reset          : in std_logic;
             buttonin       : in std_logic;
             short          : out std_logic;
             long           : out std_logic;
             two            : out std_logic);
end component; --end TriButton

--Declare Loader
component Loader
    generic (clkfreq    : integer;
             steps      : integer;
             max        : integer);
    port    (clk        : in std_logic;
             reset      : in std_logic;
             load       : in std_logic;
             prev       : in std_logic;
             flash      : in std_logic;
             dataout    : out std_logic_vector (7 downto 0);
             busy       : out std_logic;
             SCK        : out std_logic;
             SDA        : out std_logic);
end component; --end Loader

begin

TB1 : TriButton --using triButton
    generic map (clkfreq        => clkfreq,
                 pulselength    => pulselength)
    port map    (clk            => clk,
                 reset          => reset,
                 buttonin       => buttonin,
                 short          => short,
                 long           => long,
                 two            => two);
                 
L1 : Loader --using Loader
    generic map (clkfreq    => clkfreq,
                 steps      => steps,
                 max        => max)
    port map    (clk        => clk,
                 reset      => reset,
                 load       => short, --moves to the next register value
                 prev       => two, --displays the current position in the register
                 flash      => flipper, --blinks the current value
                 dataout    => dataout,
                 busy       => busy,
                 SCK        => SCK,
                 SDA        => SDA);
                 
--for testin
tshort <= short;
tlong <= long;
ttwo <= two;

Main : process (clk, reset)
begin
    if reset = '1' then
        flipper <= '0';
        
    elsif clk'event and clk='1' then
        if long = '1' then
            flipper <= not flipper;
        end if;
    end if;--end clk &reset
end process;
end Behavioral;
