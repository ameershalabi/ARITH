--------------------------------------------------------------------------------
-- Title       : A simple accumulator block
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : accum.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Dec 28 01:55:10 2025
-- Last update : Fri Jan  2 12:58:39 2026
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: An accumulator block
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity accum is
  generic (
    w_data_g : integer := 16
  );
  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    accum : in std_logic; -- accumulate trigger
    load  : in std_logic; -- load trigger

    -- data_i:
    -- -- loaded into accumulate register when load is high
    -- -- added to accumulate register when load in low
    data_i : in  std_logic_vector(w_data_g-1 downto 0);
    data_o : out std_logic_vector(w_data_g-1 downto 0)
  );
end entity accum;

architecture arch of accum is

  -- register to store accumulated value
  signal accum_r : std_logic_vector(w_data_g-1 downto 0);

begin

  accum_proc : process (clk, rst)
    variable u_accum_v : unsigned(w_data_g-1 downto 0);
    variable u_datai_v : unsigned(w_data_g-1 downto 0);
  begin
    if (rst = '0') then
      accum_r <= (others => '0');
    elsif rising_edge(clk) then
      if (enb = '1') then
        u_datai_v := unsigned(data_i);
        u_accum_v := unsigned(accum_r);
        -- load data_i into register if load is high
        if (load = '1') then
          accum_r <= data_i;
        else -- otherwise add data_i into register
          accum_r <= std_logic_vector(u_accum_v + u_datai_v);
        end if;

        if (clr = '1') then
          accum_r <= (others => '0');
        end if;
      end if;
    end if;
  end process accum_proc;

  data_o <= accum_r;

end architecture arch;


