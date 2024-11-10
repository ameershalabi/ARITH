--------------------------------------------------------------------------------
-- Title       : Kogge-Stone Adder
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : ks_adder_16b.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Sun Mar 24 11:54:10 2024
-- Last update : Sun Mar 31 13:25:15 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A 16b Kogge-Stone Adder with O(Log2N) delay.
--  carry_p(x) = a(x) xor b(x)
--  carry_g(x) = a(x) b(x)
--  p(0:x) = p(x) p(x-1) ... p(0)
--  g(0:x) = g(x) + (p(x) g(x-1)) + (p(x) p(x-1) g(x-2)) + ... + 
--           (p(x) p(x-1) ... g(0))
--  p(y:x) = p(y:z) dot p(z+1:x) = p(y:z) p(z+1:x)
--  g(y:x) = g(y:z) dot g(z+1:x) = g(z+1:x) + p(z+1:x) g(y:z)
--  carry_(x) = g(0:x) or ( p(0:x) and carry_in)
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity ks_adder_16b is
  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    a_i : in std_logic_vector(15 downto 0);
    b_i : in std_logic_vector(15 downto 0);
    c_i : in std_logic;

    s_o : out std_logic_vector(15 downto 0);
    c_o : out std_logic
  );
end entity ks_adder_16b;

architecture arch of ks_adder_16b is
  -- control registers
  signal clr_r : std_logic;
  signal enb_r : std_logic;

  -- input registers
  signal a_r   : std_logic_vector(15 downto 0);
  signal b_r   : std_logic_vector(15 downto 0);
  signal c_i_r : std_logic;

  -- carry signal
  signal p_g_c : std_logic_vector(16 downto 0);

  -- output signals and registers
  signal sum   : std_logic_vector(15 downto 0);
  signal sum_r : std_logic_vector(15 downto 0);
  signal c_o_r : std_logic_vector(15 downto 0);

  -- hold the generate and propogate of each bit pair
  -- store p(x)
  signal p : std_logic_vector(15 downto 0);
  -- store g(x)
  signal g : std_logic_vector(15 downto 0);

  -- hold the generate and propogate groups from
  -- the first dot product
  -- store p(x:x+1)
  signal p_0_1   : std_logic; signal p_1_2 : std_logic; signal p_2_3 : std_logic;
  signal p_3_4   : std_logic; signal p_4_5 : std_logic; signal p_5_6 : std_logic;
  signal p_6_7   : std_logic; signal p_7_8 : std_logic; signal p_8_9 : std_logic;
  signal p_9_10  : std_logic; signal p_10_11 : std_logic; signal p_11_12 : std_logic;
  signal p_12_13 : std_logic; signal p_13_14 : std_logic; signal p_14_15 : std_logic;

  -- store g(x:x+1)
  signal g_0_1   : std_logic; signal g_1_2 : std_logic; signal g_2_3 : std_logic;
  signal g_3_4   : std_logic; signal g_4_5 : std_logic; signal g_5_6 : std_logic;
  signal g_6_7   : std_logic; signal g_7_8 : std_logic; signal g_8_9 : std_logic;
  signal g_9_10  : std_logic; signal g_10_11 : std_logic; signal g_11_12 : std_logic;
  signal g_12_13 : std_logic; signal g_13_14 : std_logic; signal g_14_15 : std_logic;

  -- hold the generate and propogate groups from
  -- the second dot product
  -- store p(0:x)
  signal p_0_2   : std_logic; signal p_0_3 : std_logic; signal p_1_4 : std_logic;
  signal p_2_5   : std_logic; signal p_3_6 : std_logic; signal p_4_7 : std_logic;
  signal p_5_8   : std_logic; signal p_6_9 : std_logic; signal p_7_10 : std_logic;
  signal p_8_11  : std_logic; signal p_9_12 : std_logic; signal p_10_13 : std_logic;
  signal p_11_14 : std_logic; signal p_12_15 : std_logic;

  -- store g(0:x)
  signal g_0_2   : std_logic; signal g_0_3 : std_logic; signal g_1_4 : std_logic;
  signal g_2_5   : std_logic; signal g_3_6 : std_logic; signal g_4_7 : std_logic;
  signal g_5_8   : std_logic; signal g_6_9 : std_logic; signal g_7_10 : std_logic;
  signal g_8_11  : std_logic; signal g_9_12 : std_logic; signal g_10_13 : std_logic;
  signal g_11_14 : std_logic; signal g_12_15 : std_logic;


  -- hold the generate and propogate groups from
  -- the third dot product 
  signal p_0_4  : std_logic; signal p_0_5 : std_logic; signal p_0_6 : std_logic;
  signal p_0_7  : std_logic; signal p_1_8 : std_logic; signal p_2_9 : std_logic;
  signal p_3_10 : std_logic; signal p_4_11 : std_logic; signal p_5_12 : std_logic;
  signal p_6_13 : std_logic; signal p_7_14 : std_logic; signal p_8_15 : std_logic;

  signal g_0_4  : std_logic; signal g_0_5 : std_logic; signal g_0_6 : std_logic;
  signal g_0_7  : std_logic; signal g_1_8 : std_logic; signal g_2_9 : std_logic;
  signal g_3_10 : std_logic; signal g_4_11 : std_logic; signal g_5_12 : std_logic;
  signal g_6_13 : std_logic; signal g_7_14 : std_logic; signal g_8_15 : std_logic;

  -- hold the generate and propogate groups from
  -- the fourth dot product 
  signal p_0_8  : std_logic; signal p_0_9 : std_logic; signal p_0_10 : std_logic;
  signal p_0_11 : std_logic; signal p_0_12 : std_logic; signal p_0_13 : std_logic;
  signal p_0_14 : std_logic; signal p_0_15 : std_logic;

  signal g_0_8  : std_logic; signal g_0_9 : std_logic; signal g_0_10 : std_logic;
  signal g_0_11 : std_logic; signal g_0_12 : std_logic; signal g_0_13 : std_logic;
  signal g_0_14 : std_logic; signal g_0_15 : std_logic;

begin
  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r <= '0';
      enb_r <= '0';
      a_r   <= (others => '0');
      b_r   <= (others => '0');
      c_i_r <= '0';
    elsif rising_edge(clk) then
      clr_r <= clr;
      enb_r <= enb;
      if enb_r = '1' then
        a_r   <= a_i;
        b_r   <= b_i;
        c_i_r <= c_i;
        if clr_r = '1' then
          a_r   <= (others => '0');
          b_r   <= (others => '0');
          c_i_r <= '0';
        end if;
      end if;
    end if;
  end process ctrl_proc;


  p_g_proc : process (a_r,b_r)
  begin
    create_p_g_loop : for bit_idx in 0 to 15 loop
      -- p(x) = a(x) xor b(x)
      p(bit_idx) <= a_r(bit_idx) xor b_r(bit_idx);
      -- g(x) = a(x) and b(x)
      g(bit_idx) <= a_r(bit_idx) and b_r(bit_idx);
    end loop create_p_g_loop;
  end process p_g_proc;

  -- the first dot product

  p_0_1   <= p(0) and p(1);
  p_1_2   <= p(1) and p(2);
  p_2_3   <= p(2) and p(3);
  p_3_4   <= p(3) and p(4);
  p_4_5   <= p(4) and p(5);
  p_5_6   <= p(5) and p(6);
  p_6_7   <= p(6) and p(7);
  p_7_8   <= p(7) and p(8);
  p_8_9   <= p(8) and p(9);
  p_9_10  <= p(9) and p(10);
  p_10_11 <= p(10) and p(11);
  p_11_12 <= p(11) and p(12);
  p_12_13 <= p(12) and p(13);
  p_13_14 <= p(13) and p(14);
  p_14_15 <= p(14) and p(15);

  g_0_1   <= (g(0) and p(1)) or g(1);
  g_1_2   <= (g(1) and p(2)) or g(2);
  g_2_3   <= (g(2) and p(3)) or g(3);
  g_3_4   <= (g(3) and p(4)) or g(4);
  g_4_5   <= (g(4) and p(5)) or g(5);
  g_5_6   <= (g(5) and p(6)) or g(6);
  g_6_7   <= (g(6) and p(7)) or g(7);
  g_7_8   <= (g(7) and p(8)) or g(8);
  g_8_9   <= (g(8) and p(9)) or g(9);
  g_9_10  <= (g(9) and p(10)) or g(10);
  g_10_11 <= (g(10) and p(11)) or g(11);
  g_11_12 <= (g(11) and p(12)) or g(12);
  g_12_13 <= (g(12) and p(13)) or g(13);
  g_13_14 <= (g(13) and p(14)) or g(14);
  g_14_15 <= (g(14) and p(15)) or g(15);

  -- the second dot product

  p_0_2   <= p(0) and p_1_2;
  p_0_3   <= p_0_1 and p_2_3;
  p_1_4   <= p_1_2 and p_3_4;
  p_2_5   <= p_2_3 and p_4_5;
  p_3_6   <= p_3_4 and p_5_6;
  p_4_7   <= p_4_5 and p_6_7;
  p_5_8   <= p_5_6 and p_7_8;
  p_6_9   <= p_6_7 and p_8_9;
  p_7_10  <= p_7_8 and p_9_10;
  p_8_11  <= p_8_9 and p_10_11;
  p_9_12  <= p_9_10 and p_11_12;
  p_10_13 <= p_10_11 and p_12_13;
  p_11_14 <= p_11_12 and p_13_14;
  p_12_15 <= p_12_13 and p_14_15;

  g_0_2   <= (g(0) and p_1_2) or g_1_2;
  g_0_3   <= (g_0_1 and p_2_3) or g_2_3;
  g_1_4   <= (g_1_2 and p_3_4) or g_3_4;
  g_2_5   <= (g_2_3 and p_4_5) or g_4_5;
  g_3_6   <= (g_3_4 and p_5_6) or g_5_6;
  g_4_7   <= (g_4_5 and p_6_7) or g_6_7;
  g_5_8   <= (g_5_6 and p_7_8) or g_7_8;
  g_6_9   <= (g_6_7 and p_8_9) or g_8_9;
  g_7_10  <= (g_7_8 and p_9_10) or g_9_10;
  g_8_11  <= (g_8_9 and p_10_11) or g_10_11;
  g_9_12  <= (g_9_10 and p_11_12) or g_11_12;
  g_10_13 <= (g_10_11 and p_12_13) or g_12_13;
  g_11_14 <= (g_11_12 and p_13_14) or g_13_14;
  g_12_15 <= (g_12_13 and p_14_15) or g_14_15;

  -- the third dot product

  p_0_4  <= p(0) and p_1_4;
  p_0_5  <= p_0_1 and p_2_5;
  p_0_6  <= p_0_2 and p_3_6;
  p_0_7  <= p_0_3 and p_4_7;
  p_1_8  <= p_1_4 and p_5_8;
  p_2_9  <= p_2_5 and p_6_9;
  p_3_10 <= p_3_6 and p_7_10;
  p_4_11 <= p_4_7 and p_8_11;
  p_5_12 <= p_5_8 and p_9_12 ;
  p_6_13 <= p_6_9 and p_10_13;
  p_7_14 <= p_7_10 and p_11_14;
  p_8_15 <= p_8_11 and p_12_15;

  g_0_4  <= (g(0) and p_1_4) or g_1_4;
  g_0_5  <= (g_0_1 and p_2_5) or g_2_5;
  g_0_6  <= (g_0_2 and p_3_6) or g_3_6;
  g_0_7  <= (g_0_3 and p_4_7) or g_4_7;
  g_1_8  <= (g_1_4 and p_5_8 ) or g_5_8;
  g_2_9  <= (g_2_5 and p_6_9 ) or g_6_9;
  g_3_10 <= (g_3_6 and p_7_10) or g_7_10;
  g_4_11 <= (g_4_7 and p_8_11) or g_8_11;
  g_5_12 <= (g_5_8 and p_9_12 ) or g_9_12;
  g_6_13 <= (g_6_9 and p_10_13 ) or g_10_13;
  g_7_14 <= (g_7_10 and p_11_14 ) or g_11_14;
  g_8_15 <= (g_8_11 and p_12_15 ) or g_12_15;

  -- the fourth dot product

  p_0_8  <= p(0) and p_1_8;
  p_0_9  <= p_0_1 and p_2_9;
  p_0_10 <= p_0_2 and p_3_10;
  p_0_11 <= p_0_3 and p_4_11;
  p_0_12 <= p_0_4 and p_5_12;
  p_0_13 <= p_0_5 and p_6_13;
  p_0_14 <= p_0_6 and p_7_14;
  p_0_15 <= p_0_7 and p_8_15;

  g_0_8  <= (g(0) and p_1_8) or g_1_8;
  g_0_9  <= (p_0_1 and p_2_9) or g_2_9;
  g_0_10 <= (p_0_2 and p_3_10) or g_3_10;
  g_0_11 <= (p_0_3 and p_4_11) or g_4_11;
  g_0_12 <= (p_0_4 and p_5_12) or g_5_12;
  g_0_13 <= (p_0_5 and p_6_13) or g_6_13;
  g_0_14 <= (p_0_6 and p_7_14) or g_7_14;
  g_0_15 <= (p_0_7 and p_8_15) or g_8_15;

  -- generated and propogated carry bits
  p_g_c(0)  <= c_i_r;
  p_g_c(1)  <= (c_i_r and p(0)) or g(0);
  p_g_c(2)  <= (c_i_r and p_0_1) or g_0_1;
  p_g_c(3)  <= (c_i_r and p_0_2) or g_0_2;
  p_g_c(4)  <= (c_i_r and p_0_3) or g_0_3;
  p_g_c(5)  <= (c_i_r and p_0_4) or g_0_4;
  p_g_c(6)  <= (c_i_r and p_0_5) or g_0_5;
  p_g_c(7)  <= (c_i_r and p_0_6) or g_0_6;
  p_g_c(8)  <= (c_i_r and p_0_7) or g_0_7;
  p_g_c(9)  <= (c_i_r and p_0_8) or g_0_8;
  p_g_c(10) <= (c_i_r and p_0_9) or g_0_9;
  p_g_c(11) <= (c_i_r and p_0_10) or g_0_10;
  p_g_c(12) <= (c_i_r and p_0_11) or g_0_11;
  p_g_c(13) <= (c_i_r and p_0_12) or g_0_12;
  p_g_c(14) <= (c_i_r and p_0_13) or g_0_13;
  p_g_c(15) <= (c_i_r and p_0_14) or g_0_14;
  p_g_c(16) <= (c_i_r and p_0_15) or g_0_15;


  gen_sum_proc : process (a_r,b_r,p_g_c)
  begin
    gen_sum_loop : for s in 0 to 15 loop
      -- sum = a_i xor b_i xor c_i
      sum(s) <= a_r(s) xor b_r(s) xor p_g_c(s);
    end loop gen_sum_loop;
  end process gen_sum_proc;

  out_proc : process (clk, rst)
  begin
    if (rst = '0') then
      sum_r <= (others => '0');
      c_o_r <= (others => '0');
    elsif rising_edge(clk) then
      if enb_r = '1' then
        sum_r <= sum;
        c_o_r <= p_g_c(16 downto 1);
        if clr_r = '1' then
          sum_r <= (others => '0');
          c_o_r <= (others => '0');
        end if;
      end if;
    end if;
  end process out_proc;

  s_o <= sum_r;
  c_o <= c_o_r(15);

end architecture arch;