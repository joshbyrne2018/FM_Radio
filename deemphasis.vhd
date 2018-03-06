library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.divider_const.all;

entity deemphasis is
generic (
  decimation : integer := 1
);
port (
  clock : in std_logic;
  reset : in std_logic;

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

signal y1, y1_c : std_logic_vector(31 downto 0);
signal y2, y2_c : std_logic_vector(31 downto 0);
signal i, i_c : std_logic_vector(31 downto 0);
signal j, j_c : std_logic_vector(31 downto 0);
type state_type is (s1, s2);
signal state, state_c : state_type;

begin

  clock_process : process(reset, clock) is
  begin
    if (reset = '1') then
      -- reset signals to default values
      y1 <= (others => '0');
      y2 <= (others => '0');
      i <= (others =>'0');
      j <= (others => '0');
    elsif (rising_edge(clock)) then
      y1 <= y1_c;
      y2 <= y2_c;
      i <= i_c;
      j <= j_c;
    end if;
  end process clock_process;

state_process : process(state) is
begin
  case (state) is
    when (s1) =>
      x[j] = x [j - decimation];
    when (s2) =>
  end case;
end process state_process;


end architecture behavioral;
