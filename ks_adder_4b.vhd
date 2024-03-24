--------------------------------------------------------------------------------
-- Title       : Kogge-Stone Adder
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : ks_adder_4b.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Wed Mar 20 07:38:54 2024
-- Last update : Sun Mar 24 16:53:45 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A 4b Kogge-Stone Adder with O(Log2N) delay.
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

entity ks_adder_4b is
  generic (
    gen_in_reg_g  : std_logic := '0';
    gen_out_reg_g : std_logic := '0'
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
end entity ks_adder_4b;

architecture arch of ks_adder_4b is
  -- control registers
  signal clr_r : std_logic;
  signal enb_r : std_logic;

  -- input registers
  signal a_r   : std_logic_vector(3 downto 0);
  signal b_r   : std_logic_vector(3 downto 0);
  signal c_i_r : std_logic;

  -- carry signal
  signal p_g_c : std_logic_vector(4 downto 0);

  -- output signals and registers
  signal sum   : std_logic_vector(3 downto 0);
  signal sum_r : std_logic_vector(3 downto 0);
  signal c_o_r : std_logic_vector(3 downto 0);

  -- hold the generate and propogate of each bit pair
  -- store p(x)
  signal p : std_logic_vector(3 downto 0);
  -- store g(x)
  signal g : std_logic_vector(3 downto 0);

  -- hold the generate and propogate groups from
  -- the first dot product
  -- store p(x:x+1)
  signal p_0_1 : std_logic;
  signal p_1_2 : std_logic;
  signal p_2_3 : std_logic;
  -- store g(x:x+1)
  signal g_0_1 : std_logic;
  signal g_1_2 : std_logic;
  signal g_2_3 : std_logic;

  -- hold the generate and propogate groups from
  -- the second dot product
  -- store p(0:x)
  signal p_0_2 : std_logic;
  signal p_0_3 : std_logic;
  -- store g(0:x)
  signal g_0_2 : std_logic;
  signal g_0_3 : std_logic;

begin

  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r <= '0';
      enb_r <= '0';
    elsif rising_edge(clk) then
      clr_r <= clr;
      enb_r <= enb;
    end if;
  end process ctrl_proc;

  -- generate input registers
  gen_in_reg : if (gen_in_reg_g = '1') generate
    ctrl_proc : process (clk, rst)
    begin
      if (rst = '0') then
        a_r   <= (others => '0');
        b_r   <= (others => '0');
        c_i_r <= '0';
      elsif rising_edge(clk) then
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

  end generate gen_in_reg;

  -- generate output registers
  gen_out_reg : if (gen_out_reg_g = '1') generate
    ctrl_proc : process (clk, rst)
    begin
      if (rst = '0') then
        sum_r <= (others => '0');
        c_o_r <= (others => '0');
      elsif rising_edge(clk) then
        if enb_r = '1' then
          sum_r <= sum;
          c_o_r <= p_g_c(4 downto 1);
          if clr_r = '1' then
            sum_r <= (others => '0');
            c_o_r <= (others => '0');
          end if;
        end if;
      end if;
    end process ctrl_proc;

  end generate gen_out_reg;

  -- no input registers
  gen_no_in_reg : if (gen_in_reg_g = '0') generate
    a_r   <= a_i;
    b_r   <= b_i;
    c_i_r <= c_i;

  end generate gen_no_in_reg;

  -- no output registers
  gen_no_out_reg : if (gen_out_reg_g = '0') generate
    sum_r <= sum;
    c_o_r <= p_g_c(4 downto 1);

  end generate gen_no_out_reg;


  --ctrl_proc : process (clk, rst)
  --begin
  --  if (rst = '0') then
  --    clr_r <= '0';
  --    enb_r <= '0';
  --    a_r   <= (others => '0');
  --    b_r   <= (others => '0');
  --    c_i_r <= '0';
  --  elsif rising_edge(clk) then
  --    clr_r <= clr;
  --    enb_r <= enb;
  --    if enb_r = '1' then
  --      a_r   <= a_i;
  --      b_r   <= b_i;
  --      c_i_r <= c_i;
  --      if clr_r = '1' then
  --        a_r   <= (others => '0');
  --        b_r   <= (others => '0');
  --        c_i_r <= '0';
  --      end if;
  --    end if;
  --  end if;
  --end process ctrl_proc;

  -- p(x) = a(x) xor b(x)
  p(0) <= a_r(0) xor b_r(0);
  p(1) <= a_r(1) xor b_r(1);
  p(2) <= a_r(2) xor b_r(2);
  p(3) <= a_r(3) xor b_r(3);

  -- g(x) = a(x) and b(x)
  g(0) <= a_r(0) and b_r(0);
  g(1) <= a_r(1) and b_r(1);
  g(2) <= a_r(2) and b_r(2);
  g(3) <= a_r(3) and b_r(3);

  p_0_1 <= p(0) and p(1);
  p_1_2 <= p(1) and p(2);
  p_2_3 <= p(2) and p(3);

  g_0_1 <= (g(0) and p(1)) or g(1);
  g_1_2 <= (g(1) and p(2)) or g(2);
  g_2_3 <= (g(2) and p(3)) or g(3);

  p_0_2 <= p(0) and p_1_2;
  p_0_3 <= p_0_1 and p_2_3;

  g_0_2 <= (g(0) and p_1_2) or g_1_2;
  g_0_3 <= (g_0_1 and p_2_3) or g_2_3;

  p_g_c(0) <= c_i_r;
  p_g_c(1) <= (c_i_r and p(0)) or g(0);
  p_g_c(2) <= (c_i_r and p_0_1) or g_0_1;
  p_g_c(3) <= (c_i_r and p_0_2) or g_0_2;
  p_g_c(4) <= (c_i_r and p_0_3) or g_0_3;

  gen_sum_proc : process (a_r,b_r,p_g_c)
  begin
    gen_sum_loop : for s in 0 to 3 loop
      -- sum = a_i xor b_i xor c_i
      sum(s) <= a_r(s) xor b_r(s) xor p_g_c(s);
    end loop gen_sum_loop;
  end process gen_sum_proc;

  --out_proc : process (clk, rst)
  --begin
  --  if (rst = '0') then
  --    sum_r <= (others => '0');
  --    c_o_r <= (others => '0');
  --  elsif rising_edge(clk) then
  --    if enb_r = '1' then
  --      sum_r <= sum;
  --      c_o_r <= p_g_c(4 downto 1);
  --      if clr_r = '1' then
  --        sum_r <= (others => '0');
  --        c_o_r <= (others => '0');
  --      end if;
  --    end if;
  --  end if;
  --end process out_proc;

  s_o <= sum_r;
  c_o <= c_o_r(3);

end architecture arch;