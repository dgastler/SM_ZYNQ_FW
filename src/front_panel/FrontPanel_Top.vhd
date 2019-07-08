----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/08/2019 01:35:23 PM
-- Design Name: 
-- Module Name: FrontPanel_Top - Behavioral
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

use work.types.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL; ---del

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FrontPanel_Top is
    port    (clk            : in std_logic;
             reset          : in std_logic;
             buttonin       : in std_logic;
             LEDout         : out std_logic_vector (7 downto 0);
             --for testing, delete ports below this line
             tshort     : out std_logic;
             tlong      : out std_logic;
             ttwo       : out std_logic;
             tshutdown  : out std_logic);
end FrontPanel_Top;

architecture Behavioral of FrontPanel_Top is

--signals for transmisitting across components
signal short    : std_logic; 
signal long     : std_logic;
signal two      : std_logic;
signal shutdown : std_logic;
signal LEDreset : std_logic;
signal SCK2      : std_logic;
signal SDA2      : std_logic;
--shift reg for readout
signal shiftreg : std_logic_vector (7 downto 0);
--1 bit logic
signal shifty   : std_logic; --used for shifting shiftreg
--constants for timing
constant STEPS  : integer := 100000000 / 1000000; --this makes SCK run at 1 Mhz, 10 us for a full readout, --2 does work
--kinda a placeholder, may go away
signal dataout : std_logic_vector (7 downto 0);
--counter for testing, delete these signals
signal count : integer range 0 to 100000000; --del
signal hold  : std_logic;  --del

--for testing data declarations
signal display_regs : slv8_array_t(0 to 9) := (
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

--Declare Front UI
component FrontPanel_UI
    generic (CLKFREQ        : integer;
             REG_COUNT      : integer;
             FLASHLENGTH    : integer;
             FLASHRATE      : integer);
    port    (clk            : in std_logic;
             reset          : in std_logic;
             buttonin       : in std_logic;
             display_regs   : in slv8_array_t (0 to (REG_Count - 1));
             SCK        : out std_logic;
             SDA    : out std_logic;
             --testing below
             shortout         : out std_logic;
             longout          : out std_logic;
             twoout           : out std_logic;
             shutdownout      : out std_logic);
end component;
             




begin



--continuous output
LEDout <= shiftreg(0) & shiftreg(1) & shiftreg(2) & shiftreg(3) & shiftreg(4) & shiftreg(5) & shiftreg(6) & shiftreg(7);
--reset for LED includes shutdown signal
LEDreset <= shutdown or reset;






F1: FrontPanel_UI
    generic map (CLKFREQ => 100000000,
                 REG_COUNT => 10,
                 FLASHLENGTH => 0,
                 FLASHRATE => 0)
    port map    (clk => clk,
                 reset => reset,
                 buttonin => buttonin,
                 display_regs => display_regs,
                 SCK => SCK2,
                 SDA => SDA2,
                 --testing below
                 shortout => short,
                 longout => long,
                 twoout => two,
                 shutdownout => shutdown);
    




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

LEDpause: process (clk, reset)
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
            elsif shutdown = '1' then
                tshutdown <= '1';
                hold <= '1';
            else
                tshutdown <= '0';
                tshort <= '0';
                tlong <= '0';
                ttwo <= '0';
                hold <= '0';
                count <= 0;
            end if;
        else
            count <= count + 1;
            if count = (100000000 / 10) then
                count <= 0;
                hold <= '0';
            end if;
        end if;
    end if;
end process;


end Behavioral;
