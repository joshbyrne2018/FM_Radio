library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package CoArray_pkg is

     type CoArray is array (integer range <>) of std_logic_vector (31 downto 0);

end package CoArray_pkg;
