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
constant ValSize : integer := 32;
constant Coeff : CoArray(0 to 31) := (others => (others => '0'))
);
port(
signal clock : in std_logic;
signal reset : in std_logic;
signal empty_in : in std_logic;
signal full_out : in std_logic;
signal x_in : in std_logic_vector(ValSize-1 downto 0);
signal y_out : out std_logic_vector(ValSize-1 downto 0);
signal read_en : out std_logic;
signal write_en : out std_logic
);
end fir_decimation;

architecture behavior of fir_decimation is
type states is (s0,s1,s2,s3,sI);
signal state, next_state : states := sI;
type Buff is array (Taps-1 downto 0) of std_logic_vector(ValSize - 1 downto 0);
signal X_buffer, X_temp, X_buffer_next,X_temp_next : Buff;
signal y, y_next,y_out_next : std_logic_vector (ValSize-1 downto 0);
signal read_next, write_next : std_logic;
signal state_one_counter,state_one_counter_next : integer;
signal state_two_counter,state_two_counter_next : integer;
signal state_zero_counter,state_zero_counter_next : integer; 
signal ready : std_logic;

function DEQUANTIZE (val_in : std_logic_vector(31 downto 0))
  return std_logic_vector is
begin
  return std_logic_vector(shift_right(unsigned(val_in),QUANT_VAL));
end DEQUANTIZE;

function DEQUANTIZE_64 (val_in : std_logic_vector(63 downto 0))
  return std_logic_vector is
begin
  return std_logic_vector(to_signed((to_integer(signed(val_in(31 downto 0))) / to_integer((shift_left(to_signed(1, 32), QUANT_VAL)))), 32));
end DEQUANTIZE_64;

function QUANTIZE (val_in : std_logic_vector(31 downto 0))
  return std_logic_vector is
begin
  return std_logic_vector(shift_left(unsigned(val_in), QUANT_VAL));
end QUANTIZE;




begin

fir_fsm_process : process(empty_in, state, full_out, y, X_buffer, X_temp, state_one_counter,state_two_counter,state_zero_counter)


begin

next_state <= state;
X_buffer_next <= X_buffer;
X_temp_next <= X_temp;
state_one_counter_next <= state_one_counter;
state_two_counter_next <= state_two_counter;
state_zero_counter_next <= state_zero_counter;
y_next <= y;

case (state) is
	when sI => 
			write_next <= '0';
			state_one_counter_next <= DECIMATION -1;
			X_buffer_next <= (others => (others => '0'));
			X_temp_next <= (others => (others => '0'));
		if (ready = '1') then
			next_state <= s1;
			read_next <= '1';
		else
			next_state <= sI;
			read_next <= '0';		
		end if;
	
	when s0 =>
		write_next <= '0';
		if (state_zero_counter >= 0) then
			X_temp_next(state_zero_counter + DECIMATION) <= X_buffer(state_zero_counter);
			next_state <= s0;
			state_zero_counter_next <= state_zero_counter - 1;
			X_buffer_next <= X_buffer;
			if(state_zero_counter > (Taps - DECIMATION - 1 - (DECIMATION -1 ))) then
				read_next <= '1';
			else
				read_next <= '0';
			end if;
		else
			next_state <= s1;
			state_zero_counter_next <= Taps - DECIMATION - 1;
			X_buffer_next <= X_temp;
			read_next <= '1';
			state_one_counter_next <= DECIMATION -1;
		end if;
	
	when s1 =>
		
		if (empty_in = '0') then
			X_buffer_next(state_one_counter) <= x_in;
			if (state_one_counter = 0) then
				next_state <= s2;
				state_one_counter_next <= DECIMATION -1;
				read_next <= '0';
				state_two_counter_next <= 0;
				y_next <=  (others => '0');
				
			else
				next_state <= s1;
				state_one_counter_next <= state_one_counter -1;
				read_next <= '1';
				
			end if;
		else 
			next_state <= s1;
			read_next <= '1';
		end if; 
		
	when s2 =>
		y_next <= std_logic_vector(signed(y) + (signed(DEQUANTIZE_64(std_logic_vector(signed(coeff(Taps - state_two_counter - 1))*signed(X_buffer(state_two_counter))))))); --THIS IS PLACEHOLDER TO ADD IN ACTUAL DEQUANTIZE FUNCTION	
	if (state_two_counter < Taps - 1) then
		next_state <= s2;
		state_two_counter_next <= state_two_counter + 1;
		
	else 
		next_state <= s3;
		state_two_counter_next <= 0;
	end if;
	
	when s3 =>
	if(full_out = '0') then
		y_out_next <= y;
		write_next <= '1';
		next_state <= s0;
		state_zero_counter_next <= Taps - DECIMATION - 1;
	else 
		write_next <= '0';
		next_state <= s3;
	end if;
	when OTHERS =>
	next_state <= s0;

end case;


end process fir_fsm_process;

fir_reg_process : process(reset,clock)
begin
if (reset = '1') then
y <= (others => '0');
X_buffer <= (others => (others => '0'));
X_temp <= (others => (others => '0'));
state <= sI;
read_en <= '0';
write_en <= '0';
state_one_counter <= DECIMATION - 1;
state_two_counter <= 0;
state_zero_counter <= Taps - DECIMATION - 1;
y_out <= (others => '0');
ready <= '0';

elsif (rising_edge(clock)) then
ready <= '1';
state <= next_state;
y_out <= y_out_next;
y <= y_next;
read_en <= read_next;
write_en <= write_next;
X_buffer <= X_buffer_next; 
X_temp <= X_temp_next;
state_one_counter <= state_one_counter_next;
state_two_counter <= state_two_counter_next;
state_zero_counter <= state_zero_counter_next;
end if;
end process fir_reg_process;




end architecture behavior;