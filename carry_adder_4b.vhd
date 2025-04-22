--------------------------------------------------------------------------------
-- Title       : Carry look-ahead 4 bit adder
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : carry_adder_4b.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Sat Mar  2 17:18:10 2024
-- Last update : Sun Apr 13 20:15:11 2025
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity carry_adder_4b is
  generic (
    gen_in_reg_g : std_logic := '1'
  );
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
end entity carry_adder_4b;

architecture arch of carry_adder_4b is
  signal clr_r        : std_logic;
  signal enb_r        : std_logic;
  signal a_r          : std_logic_vector(3 downto 0);
  signal b_r          : std_logic_vector(3 downto 0);
  signal c_i_r        : std_logic;
  signal sum          : std_logic_vector(3 downto 0);
  signal sum_r        : std_logic_vector(3 downto 0);
  signal c_o_r        : std_logic;
  signal c_out        : std_logic;

begin

  gen_in_reg : if (gen_in_reg_g = '1') generate

    ctrl_proc : process (clk, rst)
    begin
      if (rst = '0') then
        clr_r <= '0';
        enb_r <= '0';
        a_r   <= (others => '0');
        b_r   <= (others => '0');
        sum_r <= (others => '0');
        c_o_r <= '0';
        c_i_r <= '0';
      elsif rising_edge(clk) then
        clr_r <= clr;
        enb_r <= enb;
        if enb_r = '1' then
          a_r   <= a_i;
          b_r   <= b_i;
          c_i_r <= c_i;
          sum_r <= sum;
          c_o_r <= c_out;
          if clr_r = '1' then
            a_r   <= (others => '0');
            b_r   <= (others => '0');
            sum_r <= (others => '0');
            c_o_r <= '0';
            c_i_r <= '0';
          end if;
        end if;
      end if;
    end process ctrl_proc;

  end generate gen_in_reg;

  gen_no_in_reg : if (gen_in_reg_g = '0') generate

    ctrl_proc : process (clk, rst)
    begin
      if (rst = '0') then
        clr_r <= '0';
        enb_r <= '0';
        sum_r <= (others => '0');
        c_o_r <= '0';
      elsif rising_edge(clk) then
        clr_r <= clr;
        enb_r <= enb;
        if enb_r = '1' then
          sum_r <= sum;
          c_o_r <= c_out;
          if clr_r = '1' then
            sum_r <= (others => '0');
            c_o_r <= '0';
          end if;
        end if;
      end if;
    end process ctrl_proc;
    a_r   <= a_i;
    b_r   <= b_i;
    c_i_r <= c_i;

  end generate gen_no_in_reg;

  carry_look_ahead_proc : process (a_r,b_r,c_i_r)
    variable g_bit : std_logic_vector(3 downto 0);
    variable p_bit : std_logic_vector(3 downto 0);
    variable s_bit : std_logic_vector(3 downto 0);
    variable c_bit : std_logic_vector(4 downto 0);
  begin
    -- generate the propegate and generate bits and sum bits
    c_bit(0) := c_i_r;
    gen_p_g_s_bits_loop : for b in 0 to 3 loop
      p_bit(b)   := a_r(b) xor b_r(b);
      g_bit(b)   := a_r(b) and b_r(b);
      s_bit(b)   := p_bit(b) xor c_bit(b);
      c_bit(b+1) := g_bit(b) or (p_bit(b) and c_bit(b));
    end loop gen_p_g_s_bits_loop;
    sum   <= s_bit;
    c_out <= c_bit(4);
  end process carry_look_ahead_proc;

  s_o <= sum_r;
  c_o <= c_o_r;

end architecture arch;