library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.CoArray_pkg.all;


entity fir_decimation is
generic(
constant DECIMATION : integer := 1;
constant QUANT_VAL : integer := 10;
constant Taps : integer := 8;
constant ValSize : integer := 10;
constant Coeff : CoArray
);
port(
signal clock : in std_logic;
signal reset : in std_logic;
signal empty_in : in std_logic;
signal full_in : in std_logic;
signal x_in : in std_logic_vector(ValSize-1 downto 0);
signal y_out : out std_logic_vector(ValSize-1 downto 0);
signal read_en : out std_logic;
signal write_en : out std_logic
);
end fir_decimation;

architecture behavior of fir_decimation is
type states is (s0,s1,s2,s3);
signal state, next_state : states := s0;
type Buff is array (Taps-1 downto 0) of std_logic_vector(ValSize - 1 downto 0);
signal X_buffer, X_temp : Buff;
signal y, y_next,y_temp : std_logic_vector (ValSize-1 downto 0);
signal state_one_counter : integer := DECIMATION-1;
signal read_next, write_next : std_logic;

function DEQUANTIZE (val_in : std_logic_vector(31 downto 0))
  return std_logic_vector is
begin
  return std_logic_vector(shift_right(unsigned(val_in),QUANT_VAL));
end DEQUANTIZE;

function QUANTIZE (val_in : std_logic_vector(31 downto 0))
  return std_logic_vector is
begin
  return std_logic_vector(shift_left(unsigned(val_in), QUANT_VAL));
end QUANTIZE;




begin

fir_fsm_process : process(state)
begin

case (state) is
	when s0 =>
	for I in (Taps-DECIMATION-1) downto 0 loop
	X_temp(I+DECIMATION) <= X_buffer(I);
	end loop;
	X_buffer <= X_temp;
	read_next <= '1';
	next_state <= s1;
	when s1 =>
	X_buffer(state_one_counter) <= x_in;
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
	y_temp <=  std_logic_vector(signed(y_temp) + signed(DEQUANTIZE(std_logic_vector(coeff(Taps - I - 1)*signed(X_buffer(I)))))); --THIS IS PLACEHOLDER TO ADD IN ACTUAL DEQUANTIZE FUNCTION	
	end loop;
	y_next <= y_temp;
	next_state <= s3;
	when s3 =>
	y_out <= y;
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
read_en <= read_next;
end if;
end process fir_reg_process;




end architecture behavior;
