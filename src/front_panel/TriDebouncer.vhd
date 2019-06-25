----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/25/2019 02:33:35 PM
-- Design Name: 
-- Module Name: TriDebouncer - Behavioral
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

entity TriDebouncer is
    generic (clkfreq    : integer := 100000000);
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             buttonin   : in std_logic;
             buttonout  : out std_logic);
end TriDebouncer;

architecture Behavioral of TriDebouncer is

--constant used for timing
constant period : integer := clkfreq / 30;
--counter
signal count : integer range 0 to (period + 1);
--1 bit signal
signal button : std_logic; --used to buffer buttonin & buttonout

begin

Main: process(clk, reset) begin
    
    buttonout <= button;
    
    if reset = '1' then
        --everything to 0
        button <= '0';
        count <= 0;

    elsif clk'event and clk='1' then
        --if button doesnt match the input then count for some time
        if button /= buttonin then
            count <= count + 1;
            --if time is reached then flip but
            if count = period then
                button <= not button;
            end if;
        else --if the difference is rectified within timespan then reset counter
            count <= 0;
        end if;
                
                
    end if; --end clk & reset     
end process; --end Main
end Behavioral;
