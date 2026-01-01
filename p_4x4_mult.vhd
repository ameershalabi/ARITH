--------------------------------------------------------------------------------
-- Title       : Parallel Binary Multiplier of look-ahead carry adders
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : p_4x4_mult.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Feb 29 13:12:12 2024
-- Last update : Thu Jan  1 11:02:58 2026
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: 
-- -- rvh_fifo component can be found in the misc_hdl repo here :
-- https://github.com/ameershalabi/misc_hdl/tree/main/rvh_blks
--------------------------------------------------------------------------------
-- Revisions:  
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity p_4x4_mult is
  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    ready_i : in  std_logic;
    ready_o : out std_logic;

    valid_i : in  std_logic;
    valid_o : out std_logic;

    mult_a_i : in std_logic_vector(3 downto 0);
    mult_b_i : in std_logic_vector(3 downto 0);

    mult_p_o : out std_logic_vector(7 downto 0)

  );

end entity p_4x4_mult;

architecture arch of p_4x4_mult is

  signal clr_r : std_logic;
  signal enb_r : std_logic;

  signal mult_a_r : std_logic_vector(3 downto 0);
  signal mult_b_r : std_logic_vector(3 downto 0);

  type mult_i_data_t is array (0 to 1) of std_logic_vector(3 downto 0);
  signal a_arr : mult_i_data_t;
  signal b_arr : mult_i_data_t;
  type sum_o_data_t is array (0 to 3) of std_logic_vector(7 downto 0);

  -- adder chain I/O signals
  signal a0_a : std_logic_vector(3 downto 0);
  signal a0_b : std_logic_vector(3 downto 0);
  signal a0_s : std_logic_vector(3 downto 0);
  signal a0_c : std_logic;

  signal a1_a : std_logic_vector(3 downto 0);
  signal a1_b : std_logic_vector(3 downto 0);
  signal a1_s : std_logic_vector(3 downto 0);
  signal a1_c : std_logic;

  signal a2_a : std_logic_vector(3 downto 0);
  signal a2_b : std_logic_vector(3 downto 0);
  signal a2_s : std_logic_vector(3 downto 0);
  signal a2_c : std_logic;

  -- input FIFO
  signal in_fifo_valid_i : std_logic;
  signal in_fifo_ready_i : std_logic;
  signal in_fifo_data_i  : std_logic_vector(7 downto 0);
  signal in_fifo_full_o  : std_logic;
  signal in_fifo_empty_o : std_logic;
  signal in_fifo_valid_o : std_logic;
  signal in_fifo_ready_o : std_logic;
  signal in_fifo_data_o  : std_logic_vector(7 downto 0);

  -- internal valid register
  signal valid_ring_r : std_logic_vector(2 downto 0);

  -- output FIFO
  signal out_fifo_valid_i : std_logic;
  signal out_fifo_ready_i : std_logic;
  signal out_fifo_data_i  : std_logic_vector(7 downto 0);
  signal out_fifo_full_o  : std_logic;
  signal out_fifo_empty_o : std_logic;
  signal out_fifo_valid_o : std_logic;
  signal out_fifo_ready_o : std_logic;
  signal out_fifo_data_o  : std_logic_vector(7 downto 0);

  -- sum registers
  signal sum_0 : std_logic;
  signal sum_1 : std_logic_vector(1 downto 0);
  signal sum_2 : std_logic_vector(2 downto 0);

begin

  top_ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      enb_r <= '0';
      clr_r <= '0';
    elsif rising_edge(clk) then
      enb_r <= enb;
      clr_r <= clr;
    end if;
  end process top_ctrl_proc;

  -- combine input data from ports to a single large vector
  in_fifo_data_i <= mult_a_i & mult_b_i;
  -- get the valid signal from port
  in_fifo_valid_i <= valid_i;

  -- block is not ready to read input FIFO when 
  -- the valid ring is full and output fifo is full
  -- otherwise, block is ready to read from input FIFO
  in_fifo_ready_i <= ((valid_ring_r(2) and valid_ring_r(1)) and valid_ring_r(0)) nand out_fifo_full_o;

  -- input FIFO to store valid input data
  i_in_FIFO : entity work.rvh_fifo
    generic map (
      w_data_in_g => 8,
      d_FIFO_g    => 3
    )
    port map (
      clk     => clk,
      rst     => rst,
      clr     => clr_r,
      enb     => enb_r,
      valid_i => in_fifo_valid_i,
      ready_i => in_fifo_ready_i,
      data_i  => in_fifo_data_i,
      full_o  => in_fifo_full_o,
      empty_o => in_fifo_empty_o,
      valid_o => in_fifo_valid_o,
      ready_o => in_fifo_ready_o,
      data_o  => in_fifo_data_o
    );

  -- extract input data from FIFO output
  mult_a_r <= in_fifo_data_o(3 downto 0);
  mult_b_r <= in_fifo_data_o(7 downto 4);

  -- shift register (ring register) to hold the data valid
  -- signals
  valid_data_ring_regs_proc : process (clk, rst)
  begin
    if (rst = '0') then
      valid_ring_r <= (others => '0');
      a_arr        <= (others => (others => '0'));
      b_arr        <= (others => (others => '0'));
      sum_0        <= '0';
      sum_1        <= (others => '0');
      sum_2        <= (others => '0');

    elsif rising_edge(clk) then
      -- always when enabled, shift valid signal
      if (enb_r = '1') then
        valid_ring_r(0) <= in_fifo_valid_o;
        valid_ring_r(1) <= valid_ring_r(0);
        valid_ring_r(2) <= valid_ring_r(1);

        -- if first stage valid bit is high, 
        -- get the output of FIFO into data arrays
        if (in_fifo_valid_o = '1') then
          a_arr(0) <= mult_a_r;                    -- assign A to first stage
          b_arr(0) <= mult_b_r;                    -- assign B to first stage
          sum_0    <= mult_b_r(0) and mult_a_r(0); -- generate the LSB sum bit
        end if;

        -- if second stage valid bit is high, 
        -- pass first stage A and B to second stage.
        if (valid_ring_r(0) = '1') then
          a_arr(1) <= a_arr(0);        -- assign A to second stage
          b_arr(1) <= b_arr(0);        -- assign B to second stage
          sum_1    <= a0_s(0) & sum_0; -- get the second bit for sum
        end if;

        -- if third stage valid bit is high, 
        -- get last bit of sum
        if (valid_ring_r(1) = '1') then
          sum_2 <= a1_s(0) & sum_1;
        end if;

        if (clr_r = '1') then
          valid_ring_r <= (others => '0');
          a_arr        <= (others => (others => '0'));
          b_arr        <= (others => (others => '0'));
          sum_0        <= '0';
          sum_1        <= (others => '0');
          sum_2        <= (others => '0');

        end if;
      end if;
    end if;
  end process valid_data_ring_regs_proc;

  -- generate a0_adder input
  a0_b <= mult_b_r(1)&mult_b_r(1)&mult_b_r(1)&mult_b_r(1) and mult_a_r;
  a0_a <= mult_b_r(0)&mult_b_r(0)&mult_b_r(0)&mult_b_r(0) and '0'&mult_a_r(3 downto 1);

  a0_adder : entity work.carry_adder_4b
    generic map (
      gen_in_reg_g => '0'
    )
    port map (
      clk => clk,
      rst => rst,
      clr => clr_r,
      enb => enb_r,
      a_i => a0_a,
      b_i => a0_b,
      c_i => '0',
      s_o => a0_s,
      c_o => a0_c
    );


  -- generate a1_adder input
  a1_b <= b_arr(0)(2)&b_arr(0)(2)&b_arr(0)(2)&b_arr(0)(2) and a_arr(0);
  a1_a <= a0_c&a0_s(3 downto 1);

  a1_adder : entity work.carry_adder_4b
    generic map (
      gen_in_reg_g => '0'
    )
    port map (
      clk => clk,
      rst => rst,
      clr => clr_r,
      enb => enb_r,
      a_i => a1_a,
      b_i => a1_b,
      c_i => '0',
      s_o => a1_s,
      c_o => a1_c
    );

  -- generate a2_adder input
  a2_b <= b_arr(1)(3)&b_arr(1)(3)&b_arr(1)(3)&b_arr(1)(3) and a_arr(1);
  a2_a <= a1_c&a1_s(3 downto 1);

  a2_adder : entity work.carry_adder_4b
    generic map (
      gen_in_reg_g => '0'
    )
    port map (
      clk => clk,
      rst => rst,
      clr => clr_r,
      enb => enb_r,
      a_i => a2_a,
      b_i => a2_b,
      c_i => '0',
      s_o => a2_s,
      c_o => a2_c
    );

  -- store the sum and carry into the output register
  out_fifo_valid_i <= valid_ring_r(2);
  out_fifo_ready_i <= ready_i;
  out_fifo_data_i  <= a2_c & a2_s & sum_2;

  i_out_FIFO : entity work.rvh_fifo
    generic map (
      w_data_in_g => 8,
      d_FIFO_g    => 3
    )
    port map (
      clk     => clk,
      rst     => rst,
      clr     => clr_r,
      enb     => enb_r,
      valid_i => out_fifo_valid_i,
      ready_i => out_fifo_ready_i,
      data_i  => out_fifo_data_i,
      full_o  => out_fifo_full_o,
      empty_o => out_fifo_empty_o,
      valid_o => out_fifo_valid_o,
      ready_o => out_fifo_ready_o,
      data_o  => out_fifo_data_o
    );

  -- read out output when reciever is ready
  ready_o  <= in_fifo_ready_o;
  valid_o  <= out_fifo_valid_o;
  mult_p_o <= out_fifo_data_o;

end arch;