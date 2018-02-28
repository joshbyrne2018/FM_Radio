library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.divider_const.all;

entity deemphasis is
port (

);
end entity deemphasis;

architecture behavioral of deemphasis is


function DEQUANTIZE (val_in : std_logic_vector(31 downto 0))
  return std_logic_vector(31 downto 0) is
begin
  return std_logic_vector(shift_right(to_unsigned(val_in, 32),QUANT_VAL));
end DEQUANTIZE;

function QUANTIZE (val_in : std_logic_vector(31 downto 0))
  return std_logic_vector(31 downto 0) is
begin
  return std_logic_vector(shift_left(to_unsigned(val_in,32), QUANT_VAL));
end QUANTIZE;


begin

end architecture behavioral;
