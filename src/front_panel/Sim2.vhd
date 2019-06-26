----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/18/2019 02:24:48 PM
-- Design Name: 
-- Module Name: TopSim - Behavioral
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

entity TopSim is
--  Port ( );
end TopSim;

architecture Behavioral of TopSim is

component Loader
generic (steps      : integer;
         max        : integer;
         flashrate  : integer);
    Port (clk       : in std_logic;
          reset     : in std_logic;
          load      : in std_logic;
          print     : in std_logic;
          flash     : in std_logic;
          dataout   : out std_logic_vector (7 downto 0);
          busy      : out std_logic;
          SCK       : out std_logic;
          SDA       : out std_logic;
          test      : out std_logic_vector (5 downto 0));
end component;

--inputs
signal clk, update, reset, print, flash : std_logic; --delete
--signal clk, reset, buttonin
--outputs
signal dataout : std_logic_vector (7 downto 0);
signal busy, SCK, SDA : std_logic; 
signal test : std_logic_vector (5 downto 0); --delete



begin

    Sim: Loader --FrontGrande 
    generic map (--clkfreq => 100000000,
                 --pulselength => 1,
                 steps => 4,
                 max => 10,
                 flashrate => 10)
    port map (clk => clk,
              reset => reset,
              load => update, --buttonin => buttonin
              dataout => dataout,
              busy => busy,
              SCK => SCK,
              SDA => SDA,
              print => print, --delete
              flash => flash, --delete
              test => test); --delete
              
end Behavioral;
