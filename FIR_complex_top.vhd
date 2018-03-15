library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.CoArray_pkg.all;

entity FIR_complex_top is
port (
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
end entity  FIR_complex_top;




architecture structural of FIR_complex_top is
  component fifo is
  generic
  (
  	constant FIFO_DATA_WIDTH : integer := 32;
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

  component FIR_decimation_complex is
	generic(
	constant DECIMATION : integer := 1;
	constant QUANT_VAL : integer := 10;
	constant Taps : integer := 20;
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
  end component FIR_decimation_complex;

	signal FIR_wr_en : std_logic;
	signal FIR_real_din : std_logic_vector(31 downto 0);
	signal FIR_im_din : std_logic_vector(31 downto 0);
	signal FIR_empty : std_logic;
	signal FIR_full : std_logic;
	signal FIR_real_dout : std_logic_vector(31 downto 0);
	signal FIR_im_dout : std_logic_vector(31 downto 0);
	signal FIR_rd_en : std_logic;
	
	
begin

  input_im_fifo : fifo generic map(
  FIFO_DATA_WIDTH => 32,
  FIFO_BUFFER_SIZE => 32
  )
  port map(
  rd_clk => clock,
  wr_clk  => clock,
  reset => reset,
  rd_en => FIR_rd_en,
  wr_en => input_wr_en,
  din => input_im_fifo_din,
  dout => FIR_im_din,
  full => input_fifo_full,
  empty => FIR_empty
  );
  
  input_real_fifo : fifo generic map(
  FIFO_DATA_WIDTH => 32,
  FIFO_BUFFER_SIZE => 32
  )
  port map(
  rd_clk => clock,
  wr_clk  => clock,
  reset => reset,
  rd_en => FIR_rd_en,
  wr_en => input_wr_en,
  din => input_real_fifo_din,
  dout => FIR_real_din
  );


  output_im_fifo : fifo generic map(
  FIFO_DATA_WIDTH => 32,
  FIFO_BUFFER_SIZE => 32
  )
  port map(
  rd_clk => clock,
  wr_clk => clock,
  reset => reset,
  wr_en => FIR_wr_en,
  rd_en => output_rd_en,
  din => FIR_im_dout,
  dout => output_im_fifo_dout,
  full => FIR_full,
  empty => output_fifo_empty
  );
  
  output_real_fifo : fifo generic map(
  FIFO_DATA_WIDTH => 32,
  FIFO_BUFFER_SIZE => 32
  )
  port map(
  rd_clk => clock,
  wr_clk => clock,
  reset => reset,
  wr_en => FIR_wr_en,
  rd_en => output_rd_en,
  din => FIR_real_dout,
  dout => output_real_fifo_dout,
  full => FIR_full,
  empty => output_fifo_empty
  );

  FIR_complex_unit : FIR_decimation_complex generic map(
		DECIMATION => 1,
		QUANT_VAL => 10,
		Taps => 20,
		ValSize => 32,
		Im_Coeff => (x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", 
	x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", 
	x"00000000", x"00000000", x"00000000", x"00000000",x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", 
	x"00000000", x"00000000", x"00000000", x"00000000"),
	
		Real_Coeff => (x"00000001", x"00000008", x"fffffff3", x"00000009", x"0000000b", x"ffffffd3", x"00000045", x"ffffffd3", 
	x"ffffffb1", x"00000257", x"00000257", x"ffffffb1", x"ffffffd3", x"00000045", x"ffffffd3", x"0000000b", 
	x"00000009", x"fffffff3", x"00000008", x"00000001",x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", x"00000000", 
	x"00000000", x"00000000", x"00000000", x"00000000")
	)
	port map(
		clock => clock,
		reset => reset,
		empty_in => FIR_empty,
		full_out => FIR_full,
		x_real_in => FIR_real_din,
		x_im_in => FIR_im_din,
		y_real_out => FIR_real_dout,
		y_im_out => FIR_im_dout,
		read_en => FIR_rd_en,
		write_en => FIR_wr_en
	);

end architecture structural;
