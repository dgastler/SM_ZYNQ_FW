----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/24/2019 01:06:51 PM
-- Design Name: 
-- Module Name: Debouncer - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TriButton is
    generic (clkfreq        : integer := 100000000; --frequency of onboard clock signal in hz 
             pulselength    : integer := 50000000); --how many clk ticks do you want an output to be high for
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             buttonin   : in std_logic;
             short      : out std_logic;
             long       : out std_logic;
             two        : out std_logic);--
end TriButton;

architecture Behavioral of TriButton is

--constants used for timing
constant longtime   : integer := clkfreq;
constant shorttime  : integer := (clkfreq / 2);
--counters
signal count : integer range 0 to longtime;
--state machine for main process
type states is (SM_IDLE,       --Waiting for a button press
                SM_WAIT,    --Timing how long button is held
                SM_READ,       --waiting for a multipress
                SM_HOLD);      --holding output
signal State : states;
--1 bit signals
signal twoflip : std_logic; --to recognize a double press
signal button : std_logic; --clean button output from the debouncer
--Declare Debouncer
component TriDebouncer
    generic (clkfreq    : integer);
    port    (clk        : in std_logic;
             reset      : in std_logic;
             buttonin   : in std_logic;
             buttonout  : out std_logic);
end component;

begin

TD1 : TriDebouncer --using debouncer
generic map (clkfreq    => clkfreq)
port map    (clk        => clk,
             reset      => reset,
             buttonin   => buttonin,
             buttonout  => button);

--This process defines what each state does
StateFcn: process (clk, reset) begin

    if reset = '1' then  
        --state going to idle because a reset is an effecive reset
    elsif clk'event and clk='1' then
    
        case State is
        
            when SM_IDLE =>
                --no counting
                count <= 0;
                --no outputs
                short <= '0';
                long <= '0';
                two <= '0';
                --twoflip is 0;
                twoflip <= '0';
                
            when SM_WAIT =>
                if button = '1' then
                    count <= count + 1;
                    if count = longtime then
                        long <= '1';
                        count <= 0;
                    end if;
                else
                    count <= 0;
                end if;
            
            when SM_READ =>
                count <= count + 1;
                if button = '1' then
                    twoflip <= '1';
                end if;
                if count = shorttime then
                    count <= 0;
                    if twoflip = '1' then
                        two <= '1';
                    else
                        short <= '1';
                    end if;
                end if;
            
            when SM_HOLD =>
                count <= count + 1;
                if count = (pulselength - 1) then
                    count <= 0;
                end if;
                 
            when others => null;
        end case; --end state machine
    
    
    end if; --end clk & reset
end process; --end StateFcn

--This process describes the transition between states
--An ASCII flowchart is commented into the bottom of this file
--possible failure in lagre implimentation: chage (pulslength - 1) to pulslength
StateFlow: process (clk, reset) begin
    
    if reset = '1' then
        state <= SM_IDLE;
    
    
    elsif clk'event and clk='1' then
        
        case State is 
        
            when SM_IDLE =>
                if button = '1' then
                    State <= SM_WAIT;
                else   
                    State <= SM_IDLE;
                end if;
                
            when SM_WAIT =>
                if button = '1' then
                    if count = longtime then
                        State <= SM_HOLD;
                    end if;
                else
                    State <= SM_READ;
                end if;
            
            when SM_READ =>
                if count = shorttime then
                    State <= SM_HOLD;
                end if;

            when SM_HOLD =>
                if count = (pulselength - 1) then
                    State <= SM_IDLE;
                end if;
                  
            when others => 
                State <= SM_IDLE;
        end case; --end state machine
    
    
    end if; --end clk & reset
end process; --end StateFlow
end Behavioral;

                            
--                                            +------+<----------------------------------------------------+
--                                            |      |                                                     | button = 1
--                                            |      +<--------------------------------------------+       | during .5s
--                                            | HOLD |                                   button = 0|       | two <= 1
--                                            |      +<-------------------+                 for .5s|       |
--                                            +--+---+          button = 1|              short <= 1|       |
--                                               |              for 1s    |                        |       |
--                            +---------+        v              long <= 1 |                        |       |
--                            |reset = 1|     Wait 1s                     |                        |       |
--                            +---+-----+        +                        |                        |       |
--                                |              |                        |                        |       |
--                                |           +--v---+               +----+----+               +---+---+   |
--                                |           |      |  button = 1   |         |   button = 0  |       |   |
--                                +------>+-->+ IDLE +---------------> WAITING +-------------->+ READ  +---+
--                                        |   |      |               |         |               |       |
--                                        |   +---+--+               +---------+               +-------+
--                                        |       |
--                                        |       |
--                                        +-------+ button = 0
