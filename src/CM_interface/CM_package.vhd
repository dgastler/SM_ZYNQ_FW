library ieee;
use ieee.std_logic_1164.all;

use work.types.all;

package CM_package is

  type to_CM_t is record
    UART_Tx : std_logic;
    TMS     : std_logic;
    TDI     : std_logic;
    TCK     : std_logic;
  end record to_CM_t;

  type from_CM_t is record
    PWR_good : std_logic;
    TDO      : std_logic;
    GPIO     : slv_3_t;
  end record from_CM_t;

end package CM_package;
