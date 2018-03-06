library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.CoArray_pkg.all;


entity fir_cmplx is
generic(
constant DECIMATION : integer := 1;
constant Taps : integer := 8;
constant ValSize : integer := 10;
constant Coeff,Coeff_im : CoArray
);
port(
signal clock : in std_logic;
signal reset : in std_logic;
signal empty_in : in std_logic;
signal full_in : in std_logic;
signal x_in : in std_logic_vector(ValSize-1 downto 0);
signal y_out : out std_logic_vector(ValSize-1 downto 0);
signal x_in_im : in std_logic_vector(ValSize-1 downto 0);
signal y_out_im : out std_logic_vector(ValSize-1 downto 0);
signal read_en : out std_logic;
signal write_en : out std_logic;
signal read_en_im : out std_logic;
signal write_en_im : out std_logic
);
end fir_cmplx;

architecture behavior of fir_cmplx is
type states is (s0,s1,s2,s3);
signal state, next_state : states := s0;
type Buff is array (Taps-1 downto 0) of std_logic_vector(ValSize - 1 downto 0);
signal X_buffer, X_temp, X_buffer_im, X_temp_im : Buff;
signal y,y_im, y_next,y_temp, y_next_im,y_temp_im : std_logic_vector (ValSize-1 downto 0);
signal state_one_counter : integer := DECIMATION-1;
signal read_next, write_next : std_logic;

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

fir_fsm_process : process(state)
begin

case (state) is
	when s0 =>
	for I in (Taps-DECIMATION-1) downto 0 loop
	X_temp(I+DECIMATION) <= X_buffer(I);
	X_temp_im(I+DECIMATION) <= X_buffer_im(I);
	end loop;
	X_buffer <= X_temp;
	X_buffer_im <= X_temp_im;
	read_next <= '1';
	next_state <= s1;

	when s1 =>
	X_buffer(state_one_counter) <= x_in;
	X_buffer_im(state_one_counter) <= x_in_im;
	if (state_one_counter = 0) then
	next_state <= s2;
	state_one_counter <= DECIMATION -1;
	read_next <= '0';
	else
	next_state <= s1;
	state_one_counter <= state_one_counter -1;
	read_next <= '1';
	end if;

	when s2 =>
	for I in 0 to Taps-1 loop
	--THIS IS WRONG
	y_temp <=  y_next + DEQUANTIZE(signed(coeff(I))*signed(X_buffer(I))-(signed(coeff_im(I))*signed(X_buffer_im(I)))); --THIS IS PLACEHOLDER TO ADD IN ACTUAL DEQUANTIZE FUNCTION
	y_temp_im <=  y_next_im + DEQUANTIZE(signed(coeff(I))*signed(X_buffer_im(I))-(signed(coeff_im(I))*signed(X_buffer(I)))); --THIS IS PLACEHOLDER TO ADD IN ACTUAL DEQUANTIZE FUNCTION
	end loop;
	y_next <= y_temp;
	y_next_im <= y_temp_im;
	next_state <= s3;

	when s3 =>
	y_out <= y;
	y_out_im <= y_im;
	write_en <= '1';
	when OTHERS =>
	next_state <= s0;

end case;


end process fir_fsm_process;

fir_reg_process : process(reset,clock)
begin
if (reset = '1') then
y <= (others => '0');
X_buffer <= (others => (others => '0'));
state <= s0;
elsif (rising_edge(clock)) then
state <= next_state;
y <= y_next;
y_im <= y_next_im;
read_en <= read_next;
read_en_im <= read_next;
end if;
end process fir_reg_process;




end architecture behavior;
