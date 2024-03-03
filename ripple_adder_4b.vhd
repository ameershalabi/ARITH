--------------------------------------------------------------------------------
-- Title       : A 4 bit ripple carry adder
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : ripple_adder_4b.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Fri Mar  1 10:26:17 2024
-- Last update : Sun Mar  3 01:32:45 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ripple_adder_4b is
  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    a_i : in std_logic_vector(3 downto 0);
    b_i : in std_logic_vector(3 downto 0);
    c_i : in std_logic;

    s_o : out std_logic_vector(3 downto 0);
    c_o : out std_logic
  );
end entity ripple_adder_4b;

architecture arch of ripple_adder_4b is
  signal clr_r        : std_logic;
  signal enb_r        : std_logic;
  signal a_r          : std_logic_vector(3 downto 0);
  signal b_r          : std_logic_vector(3 downto 0);
  signal carry_o_bits : std_logic_vector(4 downto 0);
  signal sum          : std_logic_vector(3 downto 0);
  signal sum_r        : std_logic_vector(3 downto 0);
  signal c_o_r        : std_logic;
  signal c_i_r        : std_logic;

begin


  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r <= '0';
      enb_r <= '0';
      a_r   <= (others => '0');
      b_r   <= (others => '0');
      c_i_r <= '0';
      sum_r <= (others => '0');
      c_o_r <= '0';
    elsif rising_edge(clk) then
      clr_r <= clr;
      enb_r <= enb;
      if enb_r = '1' then
        a_r   <= a_i;
        b_r   <= b_i;
        c_i_r <= c_i;
        sum_r <= sum;
        c_o_r <= carry_o_bits(4);
        if clr_r = '1' then
          a_r   <= (others => '0');
          b_r   <= (others => '0');
          c_i_r <= '0';
          sum_r <= (others => '0');
          c_o_r <= '0';
        end if;
      end if;
    end if;
  end process ctrl_proc;

  -- assign the first carry in as carry out from previous
  -- block
  carry_o_bits(0) <= c_i_r;
  i_fa : entity work.fa
    port map (
      a_i => a_r(0),
      b_i => b_r(0),
      c_i => carry_o_bits(0),
      s_o => sum(0),
      c_o => carry_o_bits(1)
    );
  gen_adders : for full_adder in 1 to 3 generate
    i_fa : entity work.fa
      port map (
        a_i => a_r(full_adder),
        b_i => b_r(full_adder),
        c_i => carry_o_bits(full_adder),
        s_o => sum(full_adder),
        c_o => carry_o_bits(full_adder+1)
      );
  end generate gen_adders;

  s_o <= sum_r;
  c_o <= c_o_r;

end architecture arch;