library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.CoArray_pkg.all;


entity FIR_decimation_complex is
generic(
constant DECIMATION : integer := 1;
constant QUANT_VAL : integer := 10;
constant Taps : integer := 8;
constant ValSize : integer := 32;
constant Im_Coeff : CoArray(0 to 31);
constant Real_Coeff : CoArray(0 to 31)

);
port(
signal clock : in std_logic;
signal reset : in std_logic;
signal empty_in : in std_logic;
signal full_out : in std_logic;
signal x_real_in : in std_logic_vector(ValSize-1 downto 0);
signal x_im_in : in std_logic_vector(ValSize-1 downto 0);
signal y_real_out : out std_logic_vector(ValSize-1 downto 0);
signal y_im_out : out std_logic_vector(ValSize-1 downto 0);
signal read_en : out std_logic;
signal write_en : out std_logic
);
end FIR_decimation_complex;

architecture behavior of FIR_decimation_complex is
type states is (s0,s1,s2,s3,sI);
signal state, next_state : states := sI;
type Buff is array (Taps-1 downto 0) of std_logic_vector(ValSize - 1 downto 0);
signal X_im_buffer, X_im_temp, X_im_buffer_next,X_im_temp_next, X_real_buffer, X_real_temp, X_real_buffer_next,X_real_temp_next : Buff;
signal y_im,y_real, y_im_next,y_real_next,y_im_out_next, y_real_out_next : std_logic_vector (ValSize-1 downto 0);
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

fir_fsm_process : process(empty_in, state, full_out, y_real, y_im, X_im_buffer, X_im_temp,X_real_buffer,X_real_temp, 
						state_one_counter,state_two_counter,state_zero_counter)


begin

next_state <= state;
X_im_buffer_next <= X_im_buffer;
X_im_temp_next <= X_im_temp;
X_real_buffer_next <= X_real_buffer;
X_real_temp_next <= X_real_temp;
state_one_counter_next <= state_one_counter;
state_two_counter_next <= state_two_counter;
state_zero_counter_next <= state_zero_counter;
y_im_next <= y_im;
y_real_next <= y_real;

case (state) is
	when sI => 
		state_one_counter_next <= DECIMATION - 1;
		X_im_buffer_next <= (others => (others => '0'));
		X_im_temp_next <= (others => (others => '0'));
		X_real_buffer_next <= (others => (others => '0'));
		X_real_temp_next <= (others => (others => '0'));
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
			X_im_temp_next(state_zero_counter + DECIMATION) <= X_im_buffer(state_zero_counter);
			X_real_temp_next(state_zero_counter + DECIMATION) <= X_real_buffer(state_zero_counter);
			next_state <= s0;
			state_zero_counter_next <= state_zero_counter - 1;
			X_im_buffer_next <= X_im_buffer;
			X_real_buffer_next <= X_real_buffer;
			if(state_zero_counter > (Taps - DECIMATION - 1 - (DECIMATION -1 ))) then
				read_next <= '1';
			else
				read_next <= '0';
			end if;
		else
			next_state <= s1;
			state_zero_counter_next <= Taps - DECIMATION - 1;
			X_im_buffer_next <= X_im_temp;
			X_real_buffer_next <= X_real_temp;
			read_next <= '1';
			state_one_counter_next <= DECIMATION -1;
		end if;
	
	when s1 =>
		
		if (empty_in = '0') then
			X_im_buffer_next(state_one_counter) <= x_im_in;
			X_real_buffer_next(state_one_counter) <= x_real_in;
			if (state_one_counter = 0) then
				next_state <= s2;
				state_one_counter_next <= DECIMATION -1;
				read_next <= '0';
				state_two_counter_next <= 0;
				y_im_next <=  (others => '0');
				y_real_next <=  (others => '0');
				
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
	
		y_real_next <= std_logic_vector(signed(y_real) + signed(DEQUANTIZE_64(std_logic_vector(signed(Real_Coeff(state_two_counter))*signed(X_real_buffer(state_two_counter))
		- signed(Im_Coeff(state_two_counter))*signed(X_im_buffer(state_two_counter))))));
		
		y_im_next <= std_logic_vector(signed(y_im) + signed(DEQUANTIZE_64(std_logic_vector(signed(Real_Coeff(state_two_counter))*signed(X_im_buffer(state_two_counter))
		- signed(Im_Coeff(state_two_counter))*signed(X_real_buffer(state_two_counter))))));
		
	if (state_two_counter < Taps-1) then
		next_state <= s2;
		state_two_counter_next <= state_two_counter + 1;
		
	else 
		next_state <= s3;
		state_two_counter_next <= 0;
	end if;
	
	when s3 =>
	state_zero_counter_next <= Taps - DECIMATION - 1;
	if(full_out = '0') then
		y_im_out_next <= y_im;
		y_real_out_next <= y_real;
		write_next <= '1';
		next_state <= s0;
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
y_im <= (others => '0');
y_real <= (others => '0');
X_im_buffer <= (others => (others => '0'));
X_im_temp <= (others => (others => '0'));
X_real_buffer <= (others => (others => '0'));
X_real_temp <= (others => (others => '0'));
state <= sI;
read_en <= '0';
write_en <= '0';
state_one_counter <= DECIMATION - 1;
state_two_counter <= 0;
state_zero_counter <= Taps - DECIMATION - 1;
y_im_out <= (others => '0');
y_real_out <= (others => '0');
ready <= '0';

elsif (rising_edge(clock)) then
ready <= '1';
state <= next_state;
y_im_out <= y_im_out_next;
y_im <= y_im_next;
y_real_out <= y_real_out_next;
y_real <= y_real_next;
read_en <= read_next;
write_en <= write_next;
X_im_buffer <= X_im_buffer_next; 
X_im_temp <= X_im_temp_next;
X_real_buffer <= X_real_buffer_next; 
X_real_temp <= X_real_temp_next;
state_one_counter <= state_one_counter_next;
state_two_counter <= state_two_counter_next;
state_zero_counter <= state_zero_counter_next;
end if;
end process fir_reg_process;




end architecture behavior;