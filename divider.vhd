library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.divider_const.all;

--Additional standard or custom libraries go here



entity divider is
	generic (
		DIVIDEND_WIDTH : integer := 32;
		DIVISOR_WIDTH : integer := 32
	);
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
		divider_done : out std_logic;
		);

end entity divider;

architecture fsm_behavior of divider is
	type STATE_TYPE is (idle, init, divisor_1, main_loop, display);
	signal state			: STATE_TYPE := idle;
	signal next_state		: STATE_TYPE := idle;

	signal dividend_c		: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (Others => '0');
	signal divisor_c		: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (Others => '0');

	signal temp_dividend 	: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (Others => '0');
	signal temp_divisor		: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (Others => '0');

	signal temp_quotient 	: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (Others => '0');
	signal temp_remainder		: std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (Others => '0');
	signal quotient_c 	: std_logic_vector (DIVIDEND_WIDTH - 1 downto 0) := (Others => '0');
	signal remainder_c		: std_logic_vector (DIVISOR_WIDTH - 1 downto 0) := (Others => '0');
	signal overflow_c, temp_overflow : std_logic;
	signal divider_done_c : std_logic;
--	----- get_msb_pos using for-loop alternate ---
--	function get_msb_pos(signal input_vector: std_logic_vector;size: integer)
--	  return integer is
--	begin
--	  for i in size - 1 downto 0 loop
--			if input_vector(i) = '1' then
--			  return i;
--			end if;
--	  end loop;
--	  return -1;
--	end function get_msb_pos;

	--- get_msb_pos using recursion ---
	function get_msb_pos(input_vector: std_logic_vector; size: integer)
	  return integer is
	  variable left_child, right_child: integer;
	  variable half_length: integer;
	  variable left_in, right_in : std_logic_vector(DIVIDEND_WIDTH -1 downto 0);
	begin
	  -- Base Case --
	  if size = 2 then
		 case input_vector(1 downto 0) is
			when "00" => return -1;
			when "01" => return 0;
			when "10" => return 1;
			when "11" => return 1;
			when others => return -1;
		 end case;
	  else
		 half_length := to_integer(to_signed(size, 8) SRL 1);
		 left_in(half_length - 1 downto 0) := input_vector(size - 1 downto half_length);
		 right_in(half_length - 1 downto 0) := input_vector(half_length-1 downto 0);

		 left_child := get_msb_pos(left_in, half_length);
		 right_child := get_msb_pos(right_in, half_length);

		 if left_child >= 0 then
			return left_child + half_length;
		 elsif right_child >= 0 then
			return right_child;
		 else
			return -1;
		 end if;
	  end if;

	end function get_msb_pos;

begin

	clocked_process: process(clk, reset, start)
	begin
		if (reset = '1') then
			temp_divisor <= (others => '0');
			temp_dividend <= (others => '0');
			temp_quotient <= (others => '0');
			temp_remainder <= (others => '0');
			temp_overflow <= '0';
			state <= idle;
			divider_done <= '0';
		elsif (start = '1') then
				temp_divisor <= (others => '0');
				temp_dividend <= (others => '0');
				temp_quotient <= (others => '0');
				temp_remainder <= (others => '0');
				temp_overflow <= '0';
				state <= init;
				divider_done <= '0';

		elsif (rising_edge(clk)) then
				temp_dividend <= dividend_c;
				temp_divisor <= divisor_c;
				temp_quotient <= quotient_c;
				temp_overflow <= overflow_c;
				temp_remainder <= remainder_c;
				state <= next_state;
				divider_done <= divider_done_c;
		end if;
			quotient <= temp_quotient;
			remainder <= temp_remainder;
			overflow <= temp_overflow;
	end process;

	comb_process: process(state, temp_dividend, temp_divisor, dividend, divisor, temp_quotient, temp_remainder, temp_overflow)
	variable var_divisor : natural;
	variable var_dividend : natural;
	variable p 		: integer;
	variable sign 	: std_logic;

	begin
		next_state <= state;
		dividend_c <= temp_dividend;
		divisor_c <= temp_divisor;
		quotient_c <= temp_quotient;
		remainder_c <= temp_remainder;
		overflow_c <= temp_overflow;
		divider_done_c <= divider_done;
		var_dividend := to_integer(unsigned(temp_dividend));
		var_divisor := to_integer(unsigned(temp_divisor));

		case state is
			when idle =>
					next_state <= idle;

			when init =>
					dividend_c <= std_logic_vector(abs(signed(dividend)));
					divisor_c <= std_logic_vector(resize(abs(signed(divisor)), DIVIDEND_WIDTH));
					var_divisor := to_integer(unsigned(divisor));

					if (var_divisor = 1) then
						next_state <= divisor_1;
					else
						next_state <= main_loop;
					end if;

			when divisor_1 =>
					quotient_c <= temp_dividend;
					dividend_c <= (others => '0');
					next_state <= display;

			when main_loop =>
				if (var_dividend >= var_divisor) and (var_divisor > 0) then
					p := get_msb_pos(temp_dividend, DIVIDEND_WIDTH) - get_msb_pos(temp_divisor, DIVISOR_WIDTH);

					if to_integer(unsigned(temp_divisor) SLL p) > to_integer(unsigned(temp_dividend)) then
						p := p-1;
					end if;

					quotient_c(p) <= '1';
					dividend_c <= std_logic_vector(to_unsigned(var_dividend - to_integer(unsigned(temp_divisor) SLL p), DIVIDEND_WIDTH));
					next_state <= main_loop;
				else
					next_state <= display;
				end if;


			when display =>
					if var_divisor = 0 then
						overflow_c <= '1';
						remainder_c <= (others => '0');
						quotient_c <= (others => '0');
					else
						overflow_c <= '0';
						sign := dividend(DIVIDEND_WIDTH-1) xor divisor(DIVISOR_WIDTH-1);

						if sign = '0' then
							quotient_c <= temp_quotient;
						else
							quotient_c <= std_logic_vector(-(signed(temp_quotient)));
						end if;

						if dividend(DIVIDEND_WIDTH-1) = '1' then
							remainder_c <= std_logic_vector(-(signed(temp_dividend(DIVISOR_WIDTH-1 downto 0))));
						else
							remainder_c <= temp_dividend(DIVISOR_WIDTH-1 downto 0);
						end if;
					end if;
					divider_done_c <= '1';

					next_state <= idle;

		end case;
	end process;

end architecture fsm_behavior;
