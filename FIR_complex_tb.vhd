library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity FIR_complex_tb is
generic
(
 -- constant IN_NAME : string (14 downto 1) := "test_data.pcap";
 -- constant OUT_NAME : string (10 downto 1) := "output.txt"; -- need to make an output file
  constant CLOCK_PERIOD : time := 10 ns
);
end entity FIR_complex_tb;

architecture behavior of FIR_complex_tb is
--clock, reset signals
signal clock : std_logic:= '1';
signal reset : std_logic:= '0';

--memory ports
signal din_im: std_logic_vector(31 downto 0);
signal dout_im: std_logic_vector(31 downto 0);
signal din_real: std_logic_vector(31 downto 0);
signal dout_real: std_logic_vector(31 downto 0);
signal full : std_logic;
signal empty : std_logic;
signal wr_en : std_logic;
signal rd_en : std_logic;

--process sync signals
signal hold_clock: std_logic:= '0';
signal errors: integer := 0;
signal write_done: std_logic := '0';
signal read_done: std_logic := '0';


-- Component Instantiation -- need to input new wrapper ports
component FIR_complex_top is
	port(
	  signal clock : in std_logic;
	  signal reset : in std_logic;
	  signal output_rd_en : in std_logic;
	  signal input_wr_en : in std_logic;
	  signal input_fifo_full : out std_logic;
	  signal output_fifo_empty : out std_logic;
	  signal input_im_fifo_din : in std_logic_vector(31 downto 0);
	  signal output_im_fifo_dout : out std_logic_vector(31 downto 0);
	  signal input_real_fifo_din : in std_logic_vector(31 downto 0);
	  signal output_real_fifo_dout : out std_logic_vector(31 downto 0)
	);
end component FIR_complex_top;


begin
 FIR_complex_top_inst: FIR_complex_top
  port map(
	  clock => clock,
	  reset => reset,
	  output_rd_en => rd_en,
	  input_wr_en => wr_en,
	  input_fifo_full => full,
	  output_fifo_empty => empty,
	  input_im_fifo_din => din_im,
	  output_im_fifo_dout => dout_im,
	  input_real_fifo_din => din_real,
	  output_real_fifo_dout => dout_real
  );


  clock_process: process
  begin
    clock <= '1';
    wait for (CLOCK_PERIOD / 2);
    clock <= '0';
    wait for (CLOCK_PERIOD / 2);
    if ( hold_clock= '1' ) then
      wait;
    end if;
  end process clock_process;

  reset_process: process
  begin
    reset <= '0';
    wait until  (clock = '0');
    wait until  (clock = '1');
    reset <= '1';
    wait until  (clock = '0');
    wait until  (clock = '1');
    reset <= '0';
    wait;
  end process reset_process;


	file_read_process : process
		--type raw_file is file of character;
		--file mem_in_file : raw_file open read_mode is IN_NAME; --Need to make sure this is how file name is referred to
		variable char : character;
		variable ln1 : line;
		variable count : integer := 0;

		begin
			wait until (reset = '1');
			wait until (reset = '0');
			wr_en <= '0';
			while ( count < 100) loop
				--read( mem_in_file, char );
				din_im <= x"FFFFEC00";
				din_real <= x"FFFFD800";
				wait until ( (clock = '0') and (full = '0'));
				wr_en <= '1';
				wait until (clock = '1');
				wr_en <= '0';
				din_im <= x"FFFFD800";
				din_real <= x"FFFFE800";
				wait until ( (clock = '0') and (full = '0'));
				wr_en <= '1';
				wait until (clock = '1');
				wr_en <= '0';
				din_im <= x"FFFFD000";
				din_real <= x"00000000";
				wait until ( (clock = '0') and (full = '0'));
				wr_en <= '1';
				wait until (clock = '1');
				wr_en <= '0';
			end loop;
			--file_close( mem_in_file );
			read_done <= '1';
			wait;
	end process file_read_process;

	file_write_process : process
		file out_file : text;
		variable ln1, ln2 : line;
		--type raw_file is file of character;
		--file mem_out_file : raw_file open write_mode is OUT_NAME; --need to create output file and input name
		variable errors : integer := 0;
		variable data_cmp : std_logic_vector(31 downto 0);
		variable data_read : std_logic_vector(31 downto 0);
		variable z : integer := 0;
		variable ln3 : line;
		variable char : std_logic_vector(31 downto 0);
		
		begin
			--file_open( out_file, OUT_NAME, read_mode);
			wait until (reset = '1');
			wait until (reset = '0');

			write( ln1, string'("@ ") );
			write( ln1, NOW );
			write( ln1, string'(": Comparing file ") );
			--write( ln1, OUT_NAME );
			--writeline( output, ln1 );
			while (z < 500) loop
				rd_en <= '0';
				-- read in baseline value
				if (empty = '0') then
					--readline(out_file, ln3 );
					--hread( ln3, char);
					--data_cmp:= std_logic_vector(char);
					--hwrite( ln2, data_cmp );
					--writeline( output, ln2 );
					rd_en <= '1';
					-- do we need to wait for clock to go to 1 here?
					data_read := dout_im;
				-- if baseline and computed values are not same, trigger error
				else
				rd_en <= '0';
				end if;
				z := z + 1;
				wait until (clock = '1');
				wait until (clock = '0');
			end loop;
			rd_en <= '0';
			file_close( out_file );
			write_done <= '1';
			wait;
	end process file_write_process;


      tb_process: process
          variable start_time:  time ;
          variable end_time:  time ;
          variable ln1, ln2, ln3, ln4 : line;
		  begin
			  wait until  (reset = '1');
			  wait until  (reset = '0');
			  wait until  (clock = '0');
			  wait until  (clock = '1');
			  start_time:= NOW;
			  write( ln1, string'("@ ") );
			  write( ln1, start_time);
			  write( ln1, string'(": Beginning simulation...") );
			  writeline( output, ln1 );
			  wait until  (write_done = '1' and read_done = '1');
			  end_time:= NOW;
			  write( ln2, string'("@ ") );
			  write( ln2, end_time);
			  write( ln2, string'(": Simulation completed.") );
			  writeline( output, ln2 );
			  write( ln3, string'("Total simulation cycle count: ") );
			  write( ln3, (end_time-start_time) / CLOCK_PERIOD );
			  writeline( output, ln3 );
			  write( ln4, string'("Total error count: ") );
			  write( ln4, errors );
			  writeline( output, ln4 );
			  hold_clock<= '1';
			  wait;
        end process tb_process;
	end architecture behavior;
