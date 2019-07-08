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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FrontPanel_Top is
    Generic (CLKFREQ        : integer := 100000000;
             REG_COUNT      : integer := 10;
             FLASHLENGTH    : integer := 0;
             FLASHRATE      : integer := 0);
    Port    (clk            : in std_logic;
             reset          : in std_logic;
             --display_regs   : in slv8_array_t (0 to (REG_COUNT - 1)) := (others => X"00"); --impliment
             buttonin       : in std_logic;
             LEDout         : out std_logic_vector (7 downto 0);
--             busy           : out std_logic;
--             SCK            : out std_logic;
--             SDA            : out std_logic;
             --for testing, delete ports below this line
             tshort     : out std_logic;
             tlong      : out std_logic;
             ttwo       : out std_logic;
             tshutdown  : out std_logic);
end FrontPanel_Top;

architecture Behavioral of FrontPanel_Top is

--for testing data declarations
signal display_regs : slv8_array_t := (
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
             disp_regs      : in slv8_array_t (0 to (REG_Count - 1));
             LEDout         : out std_logic_vector (7 downto 0);
             --testing below
             tshort         : out std_logic;
             tlong          : out std_logic;
             ttwo           : out std_logic;
             tshutdown      : out std_logic);
end component;
             




begin


end Behavioral;
