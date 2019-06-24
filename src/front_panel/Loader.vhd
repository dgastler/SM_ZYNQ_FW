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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Loader is
    generic (steps      : integer := 4;
             max        : integer range 1 to 64 := 10;
             flashrate  : integer := 10);
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             load       : in std_logic; --displays next LED config
             print      : in std_logic; --flashes position
             flash      : in std_logic; --flashes current LED config
             dataout    : out std_logic_vector (7 downto 0);
             busy       : out std_logic;
             SCK        : out std_logic;
             SDA        : out std_logic;
             test       : out std_logic_vector (5 downto 0)); --delete
end Loader;

architecture Behavioral of Loader is

--States for position readout?
type states is (SR, Display, Blink);
signal state : states;

--array of 64 8-bit registers
type Darray is array(0 to 63) of std_logic_vector(7 downto 0);
signal data : Darray := (
0 => x"00",
1 => x"01",
2 => x"02",
3 => x"03",
4 => x"04",
5 => x"05",
6 => x"06",
7 => x"07",
8 => x"08",
9 => x"09",
others => x"FF"
);

--register for loading data
signal LoadData : std_logic_vector(7 downto 0);

--1-bit signals
signal update: std_logic; --used to update
signal active: std_logic; --used to buffer busy output, never assign directly to this
signal flashbit: std_logic; --used for flashing data or 0

--counters
signal position: unsigned (5 downto 0); --to count position in register
signal flashcount : integer; --to count flash timing

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
test <= std_logic_vector(position); --delete

--Main process
Main: process (clk,reset)
begin
    --reset
    if reset = '1' then
        --reset counters & position
        flashcount <= 0;
        position <= "000000";
        flashbit <= '0';
        --return state
        if state = Blink then
            state <= Blink;
        else
            State <= SR;
        end if;

    --on posedge clk
    elsif clk'event and clk='1' then
    
        --In readout state
        if state = SR then
            --if not active then wait for print or load signal
            if active = '0' then
                --if print is active then switch states
                if print = '1' then
                    state <= Display;
                    --position <= position - 1;
                else
                    if flash = '1' then
                        position <= position - 1;
                        State <= Blink;
                    else
                    --if load is active then move to updating
                        loaddata <= data(to_integer(position));
                        if load = '1' then
                            update <= '1';
                        end if;
                    end if;
                end if;
            --while running
            else
                --on a "shift" set shift and update back to 0
                if update = '1' then
                    update <= '0';
                    --if at the max posion then go back to positon 0 else incriment
                    if to_integer(position) = max - 1 then
                        position <= "000000";
                    else
                        position <= position + 1;
                    end if; 
                end if;
            end if;  
                   
        --Display state 
        elsif state = Display then
            --load position vector into datain and trigger update
            if active = '0' then
                loaddata <= "00" & std_logic_vector(position);--
                update <= '1';
            else
                --set update low and return to readout state
                update <= '0';
                State <= SR;
            end if;
        
        --Flashing state
        elsif state = Blink then
            --if flash is turned off
            if flash = '0' then
                --make sure loaddata get set to data
                loaddata <= data(to_integer(position)); --maybe del
                --wait for last flash to finish then return to readout state & readout data 1 more time
                if active = '0' then
                    state <= SR;
                    update <= '1';
                end if;   
            else --While flash is on
                --load in data or 0 depending on flashbit
                if flashbit = '1' then
                    loaddata <= data(to_integer(position));
                else
                    loaddata <= X"00";
                end if;
                
                if active = '0' then
                    --timing between flashes
                    flashcount <= flashcount + 1;
                    if flashcount = flashrate - 1 then
                        flashcount <= 0;
                        update <= '1';
                        --flip flashbit
                        flashbit <= not flashbit;
                    end if;
                else
                    update <= '0';
                end if;
            end if;
             
        end if; --end state machine
    end if; --end machine w/ reset
    
end process;
end Behavioral;
