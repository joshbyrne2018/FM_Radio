library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity demodulation_tb is
end entity demodulation_tb;

architecture behavioral of demodulation_tb is

  component demodulation is
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
  end component demodulation;

begin
  



end architecture behavioral;
