library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity demodulation is
generic (
  QUANT_VAL : integer := 10; --to_integer(to_signed('1', 32) sll 10);
  gain : integer := 1;
  quad1 : std_logic_vector(31 downto 0) := (others => '0'); -- PI/4 in quantized, look for it in c code
  quad3 : std_logic_vector(31 downto 0) := (others => '0')--3*PI/4
);
port (
  clock : in std_logic;
  reset : in std_logic;
  real_in : in std_logic_vector(31 downto 0);
  imag : in std_logic_vector(31 downto 0);
  real_prev : in std_logic_vector(31 downto 0);
  imag_prev : in std_logic_vector(31 downto 0);
  demod_out : out std_logic_vector(31 downto 0);
  fifo_in_empty : in std_logic;
  fifo_in_rd_en : in std_logic;
  fifo_out_wr_en : out std_logic;
  fifo_out_full : out std_logic
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
		overflow 	: out std_logic;
    divider_done : out std_logic
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
signal divider_done : std_logic;
type states is (read_in, divide, write_out);
signal state, state_c : states;

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
    port map (
      clk => clock,
      start => start,
      reset => reset,
      dividend => dividend,
      divisor => divisor,
      quotient => r_div,
      remainder => remainder,
      overflow => overflow,
      divider_done => divider_done
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

    clock_process : process(clock, reset) is
      begin
      if (reset = '1') then
        state <= read_in;
        start <= '0';
        fifo_in_rd_en <= '0';
        fifo_out_wr_en_c <= '0';
      elsif (rising_edge(clock)) then
        state <= state_c;
        start <= start_c;
        fifo_in_rd_en <= fifo_in_rd_en_c;
        fifo_out_wr_en <= fifo_out_wr_en_c;
      end if;
    end process clock_process;


    state_process : process(state) is
      begin
      start_c <= start;
      fifo_in_rd_en_c <= fifo_in_rd_en;
      fifo_wr_en_c <= fifo_wr_en;

      case (state) is
        when (read_in) =>
          fifo_wr_en_c <= '0';
          if (fifo_in_empty = '0') then
            fifo_in_rd_en_c <= '1';
            start_c <= '1';
            next_state <= divide;
          else
            fifo_in_rd_en <= '0';
            start_c <= '0';
            next_state <= read_in;
          end if;

        when (divide) =>
          start_c <= '0';
          fifo_wr_en_c <= '0';
          fifo_in_rd_en_c <= '0';
          if (divider_done = '1') then
            next_state <= write_out;
          else
            next_state <= divide;
          end if;

        when (write_out) =>
          start_c <= '0';
          fifo_in_rd_en_c <= '0';
          if (fifo_out_full = '0') then
            next_state <= read_in;
            fifo_out_wr_en_c <= '1';
          else
            fifo_out_wr_en <= '0';
            next_state <= write_out;
          end if;
      end case;
    end process state_process;


end architecture behavioral;
