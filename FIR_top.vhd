library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.CoArray_pkg.all;

entity FIR_top is
port (
  signal clock : in std_logic;
  signal reset : in std_logic;
  signal input_fifo_din : in std_logic_vector(9 downto 0);
  signal input_wr_en : in std_logic;
  signal input_fifo_full : out std_logic;
  signal output_fifo_dout : out std_logic_vector(9 downto 0);
  signal output_fifo_empty : out std_logic;
  signal output_rd_en : in std_logic
);
end entity  FIR_top;




architecture structural of FIR_top is
  component fifo is
  generic
  (
  	constant FIFO_DATA_WIDTH : integer := 10;
  	constant FIFO_BUFFER_SIZE : integer := 32
  );
  port
  (
  	signal rd_clk : in std_logic;
  	signal wr_clk : in std_logic;
  	signal reset : in std_logic;
  	signal rd_en : in std_logic;
  	signal wr_en : in std_logic;
  	signal din : in std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
  	signal dout : out std_logic_vector ((FIFO_DATA_WIDTH - 1) downto 0);
  	signal full : out std_logic;
  	signal empty : out std_logic
  );
end component fifo;

component FIR_decimation is
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
  signal x_in : in std_logic_vector(9 downto 0);
  signal empty_in : in std_logic;
  signal read_en : out std_logic;
  signal y_out : out std_logic_vector(9 downto 0);
  signal full_out : in std_logic;
  signal write_en : out std_logic
  );
end component FIR_decimation;

signal FIR_wr_en : std_logic;
signal FIR_din : std_logic_vector(9 downto 0);
signal FIR_empty : std_logic;
signal FIR_full : std_logic;
signal FIR_dout : std_logic_vector(9 downto 0);
signal FIR_rd_en : std_logic;

begin

  input_fifo : fifo generic map(
  FIFO_DATA_WIDTH => 10,
  FIFO_BUFFER_SIZE => 10
  )
  port map(
  rd_clk => clock,
  wr_clk  => clock,
  reset => reset,
  rd_en => FIR_rd_en,
  wr_en => input_wr_en,
  din => input_fifo_din,
  dout => FIR_din,
  full => input_fifo_full,
  empty => FIR_empty
  );


  output_fifo : fifo generic map(
  FIFO_DATA_WIDTH => 10,
  FIFO_BUFFER_SIZE => 10
  )
  port map(
  rd_clk => clock,
  wr_clk => clock,
  reset => reset,
  wr_en => FIR_wr_en,
  rd_en => output_rd_en,
  din => FIR_dout,
  dout => output_fifo_dout,
  full => FIR_full,
  empty => output_fifo_empty
  );

  FIR_unit : FIR_decimation generic map(
	DECIMATION => 1,
	QUANT_VAL => 10,
	Taps => 8,
	ValSize  => 10,
	Coeff => (1,2,3,4,5,6,7,8)
  )
  port map(
  clock => clock,
  reset => reset,
  y_out => FIR_dout,
  empty_in => FIR_empty,
  read_en => FIR_rd_en,
  x_in => FIR_din,
  full_out => FIR_full,
  write_en => FIR_wr_en
  );

end architecture structural;
