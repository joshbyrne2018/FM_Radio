library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.divider_const.all;

entity demodulation is
generic (
  QUANT_VAL : integer := 10 --to_integer(to_signed('1', 32) sll 10);
  gain : integer := 1;
  quad1 --PI/4
  quad3 --3*PI/4
);
port (
  clk : in std_logic;
  reset : in std_logic;
  real_in : in std_logic_vector(31 downto 0);
  imag : in std_logic_vector(31 downto 0);
  real_prev : in std_logic_vector(31 downto 0);
  imag_prev : in std_logic_vector(31 downto 0);
  demod_out : out std_logic_vector(31 downto 0)
  -- NEED TO SHIFT REAL_PREV AND IMAG_PREV OUTSIDE OF THIS FUNCTION CALL
);
end entity demodulation;



architecture behavioral of demodulation is

component divider is
	port(
		--Inputs
		clk			: in std_logic;
		start 		: in std_logic;
		reset		: in std_logic;
        dividend 	: in std_logic_vector(DIVIDEND_WIDTH - 1 downto 0);
        divisor 	: in std_logic_vector(DIVISOR_WIDTH - 1 downto 0);

	--Outputs
		quotient 	: out std_logic_vector (DIVIDEND_WIDTH - 1 downto 0);
		remainder : out std_logic_vector (DIVISOR_WIDTH - 1 downto 0);
		overflow 	: out std_logic
		);

end component divider;





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


signal r : std_logic_vector(31 downto 0);
signal r_div : std_logic_vector(31 downto 0);
signal i : std_logic_vector(31 downto 0);
signal abs_y : std_logic_vector(31 downto 0);
signal dividend : std_logic_vector(31 downto 0);
signal divisor : std_logic_vector(31 downto 0);
signal start : std_logic;
signal remainder : std_logic_vector(31 downto 0);
signal overflow : std_logic;
signal angle : std_logic_vector(31 downto 0);
signal angle_adjusted : std_logic_vector(31 downto 0);

begin
    r <= std_logic_vector(to_signed(DEQUANTIZE(to_signed((real_prev,32)*
      to_signed(real_in,32),32))-to_signed(DEQUANTIZE(
      to_signed(imag_prev,32)*to_signed(imag,32))));
    i <= <= std_logic_vector(to_signed(DEQUANTIZE(to_signed((real_prev,32)*
      to_signed(imag,32),32))-to_signed(DEQUANTIZE(
      to_signed(imag_prev,32)*to_signed(real_in,32))));





    start <= '1';
    -- NEED TO PERFORM DIVISION FOR ARCTAN
    division_unit : divider
    port map(
      clk => clk,
      start => start,
      reset => reset,
      dividend => dividend,
      divisor => divisor,
      quotient => r_div,
      remainder => remainder,
      overflow => overflow
    );


    abs_y <= std_logic_vector(abs(to_signed(i,32))+1);

    if (to_signed(r) >= 0) then
      dividend <= std_logic_vector(to_signed(r,32)-to_signed(abs_y,32));
      divisor <= std_logic_vector(to_signed(abs_y,32)+to_signed(r,32));
      angle = std_logic_vector(to_signed(quad1) - to_signed(
        DEQUANTIZE(std_logic_vector(to_signed(
        quad1,32)*to_signed(r_div,32))),32));
    else
      dividend <= std_logic_vector(to_signed(r,32)+to_signed(abs_y,32));
      divisor <= std_logic_vector(to_signed(abs_y,32)-to_signed(r,32));
      angle = std_logic_vector(to_signed(quad3) - to_signed(
        DEQUANTIZE(std_logic_vector(to_signed(
        quad1,32)*to_signed(r_div,32))),32));
    end if;

    -- Adjust angle
    if (to_signed(i,32) < 0) then
      angle_adjusted <= std_logic_vector(to_signed(angle,32)*(-1));
    else
      angle_adjusted <= angle;
    end if;

    demod_out <= DEQUANTIZE(std_logic_vector(gain*
      to_signed(angle_adjusted, 32)));

end architecture behavioral;
