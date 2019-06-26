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
    generic (steps      : integer := 4; --how many clk ticks corresond to a SCK tick
             max        : integer range 1 to 64 := 10; --how many entries are in the Darray
             flashrate  : integer := 10); --how many clk ticks are inbetween each falsh in blinking mode
    Port    (clk        : in std_logic;
             reset      : in std_logic;
             load       : in std_logic; --moves to the next register value
             print      : in std_logic; --displays the current position in the register
             flash      : in std_logic; --blinks the current value
             dataout    : out std_logic_vector (7 downto 0);
             busy       : out std_logic;
             SCK        : out std_logic;
             SDA        : out std_logic;
             test       : out std_logic_vector (5 downto 0)); --delete
end Loader;

architecture Behavioral of Loader is

--State Machine for loader
type states is (SR,      --state to readout next value
                DISPLAY, --state to print current position
                BLINK); --state to blink current value
signal State : states;

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

StateFcn: process (clk,reset) begin
    
    if reset = '1' then
        flashcount <= 0;
        position <= "000000";
        flashbit <= '0';
        
    elsif clk'event and clk='1' then

        case State is
            when SR =>
                if active = '0' then
                    if print = '0' then
                        if flash = '1' then
                            position <= position - 1;
                        else
                            loaddata <= data(to_integer(position));
                            if load = '1' then
                                update <= '1';
                            end if;
                        end if;
                    end if;
                else
                    if update = '1' then
                        update <= '0';
                        if to_integer(position) = max - 1 then
                            position <= "000000";
                        else
                            position <= position + 1;
                        end if;
                    end if;
                end if;
            
            when DISPLAY =>
                if active = '0' then
                    loaddata <= "00" & std_logic_vector(position);
                    update <= '1';
                else
                    update <= '0';
                end if;
                    
            when Blink =>
                if flash = '0' then
                    loaddata <= data(to_integer(position));
                    --wait for last flash to finish then return to readout state & readout data 1 more time
                    if active = '0' then
                        --State <= SR;
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
            
            when others => null;
        end case; --end state machine
    end if; --end clk & reset
end process; --end StateFcn


StateFlow: process (clk, reset) begin

    if reset = '1' then
        if State = BLINK then
            State <= BLINK;
        else
            State <= SR;
        end if;

    elsif clk'event and clk='1' then
        case State is
            when SR =>
                if active = '0' then
                    if print = '1' then
                        State <= DISPLAY;
                    elsif flash = '1' then
                        State <= BLINK;
                    end if;
                end if;
            
            when DISPLAY =>
                if active = '1' then
                    state <= SR;
                end if;
        
            when Blink =>
                if flash = '0' then --if flash = '0' and active = '0' then
                    if active = '0' then
                        State <= SR;
                    end if;
                end if;
        
            
            when others => 
                State <= SR;
        end case; --end state machine
    end if; --end clk & reset
end process; --end StateFlow
end Behavioral;

--StateFcn2: process (clk, reset) begin
--    if reset = '1'
    
    
    
    
--    elsif clk'event and clk='1' then
    
--        case State is
        
    
    
    
--            when others => null;
--        end case; --end State Machine
--    end if; --end clk & reset





--end process; --end StateFcn2

--StateFlow2: process (clk, reset) begin
--    if reset = '1'
--        State <= IDLE;
    
    
    
--    elsif clk'event and clk='1' then
    
--        case State is
        
    
    
    
--        when others => 
--            State <= IDLE;
--        end case; --end state machine
--    end if; --end clk & reset





--end process; --end StateFlow2
--end Behavorial;

