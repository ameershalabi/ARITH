--------------------------------------------------------------------------------
-- Title       : Serial Binary Multiplier of ripple carry adders
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : s_mult.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Mar  4 16:46:02 2024
-- Last update : Fri Jan  2 12:59:02 2026
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: module that performs multiplication sequentially
--                  -------------------
--               /--| multiplicand (b)|
--               |  -------------------      
--               |      ---------     
--               \----->| ADDER |          ----------            
-- /------------------->| a + b |<---------| add_en |<-------------\
-- |                    ---------          ----------              | 
-- |           /------------|                                      |  
-- | ------------    ------------------    -----------------       |
-- | | carry (c) | >> | accumulator (a)| >> | multplier (r) |--lsb--/
-- | ------------    ------------------    -----------------    
-- \------------------------|                    |
--                   --------------------- ---------------------
--                   | result upper half | | result lower half |
--                   --------------------- ---------------------
--------------------------------------------------------------------------------
-- Revisions:  
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity s_mult is
  generic (
    w_data_g : integer := 16
  );

  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    mult_i : in std_logic; -- multiplication trigger

    -- input data
    mult_a_i : in std_logic_vector(w_data_g-1 downto 0);
    mult_b_i : in std_logic_vector(w_data_g-1 downto 0);

    busy_o : out std_logic; -- busy flag
    done_o : out std_logic; -- done flag

    -- mult result
    mult_p_o : out std_logic_vector(2*w_data_g-1 downto 0)

  );

end entity s_mult;

architecture arch of s_mult is

  -- data registers
  signal multiplicand_r : std_logic_vector(w_data_g-1 downto 0);
  signal multiplier_r   : std_logic_vector(w_data_g-1 downto 0);
  signal accum_r        : std_logic_vector(w_data_g-1 downto 0);

  -- The Product vector holds all the produced data during the
  -- multiplcation. At each multiplication stage, the product
  -- vector is shifted to the right untill all mult stages are done
  -- Assuming 8 bit multiplier, the Product vector is is constructed
  -- as following:
  -- caaaaaaaarrrrrrrr
  -- c: carry bit from addition, a: accumulator, r: multiplier
  signal prod_vector_r : std_logic_vector(2*w_data_g downto 0);

  -- control signals
  signal mult_en_r : std_logic;
  signal done_r    : std_logic;
  signal mult_init     : std_logic;
  signal internal_busy : std_logic;
  signal mult_done     : std_logic;

  -- adder signals
  signal add_en    : std_logic;
  signal add_res   : std_logic_vector(w_data_g-1 downto 0);
  signal add_carry : std_logic;


  signal stage_counter_r : std_logic_vector(w_data_g-1 downto 0);

begin

  -- multiplication is initialised when mult_i is high and
  -- multiplication is not busy
  mult_init <= '1' when mult_i = '1' and internal_busy = '0' else '0';

  -- mark last stage of multiplication as mult is done
  mult_done <= stage_counter_r(0);

  -- busy when multiplication is enabled or when
  -- result is available (done_r)
  internal_busy <= mult_en_r or done_r;

  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      mult_en_r <= '0';
      done_r    <= '0';
    elsif rising_edge(clk) then

      if (enb = '1') then
        if (mult_init = '1') then
          -- enable multiplication when initialisation is done
          mult_en_r <= '1';
        end if;

        -- mark done when multiplication is done
        done_r <= mult_done;

        -- if multiplication is done, disable multiplication
        if (mult_done = '1') then
          mult_en_r <= '0';
        end if;

        if (clr = '1') then
          -- only clear control signals
          mult_en_r <= '0';
          done_r    <= '0';

        end if;
      end if;
    end if;
  end process ctrl_proc;

  stage_counter_proc : process (clk, rst)
  begin
    if (rst = '0') then
      -- initiate counter woth '1' at MSB. this '1' bit will
      -- be shifted w_data_g time counting the number of 
      -- multiplication stages needed before multiplication
      -- is over
      stage_counter_r             <= (others => '0');
      stage_counter_r(w_data_g-1) <= '1';

    elsif rising_edge(clk) then
      if (enb = '1') then

        -- shift right when multiplication is enabled
        if (mult_en_r = '1') then
          stage_counter_r <= '0'&stage_counter_r(w_data_g-1 downto 1);
        end if;

        -- clear the stage counter when clr is high or when
        -- multiplication is done
        if (clr = '1' or mult_done = '1') then
          stage_counter_r             <= (others => '0');
          stage_counter_r(w_data_g-1) <= '1';
        end if;
      end if;
    end if;
  end process stage_counter_proc;


  -- enable addition flag is active only when mult is enabled
  add_en <= prod_vector_r(0) and mult_en_r;

  addition_proc : process (
      add_en,
      accum_r,
      multiplicand_r
    )
    variable add_accum_v        : unsigned(w_data_g downto 0);
    variable add_multiplicand_v : unsigned(w_data_g downto 0);
    variable add_res_u          : unsigned(w_data_g downto 0);
  begin
    -- create addition inputs (resized for 1 bit larger to accomodate carry)
    add_accum_v        := resize(unsigned(accum_r),w_data_g+1);
    add_multiplicand_v := resize(unsigned(multiplicand_r),w_data_g+1);

    -- if addition is enabled, add accum to multiplicand
    if (add_en = '1') then
      add_res_u := add_accum_v + add_multiplicand_v;
    else -- otherwise, return accum value only
      add_res_u := add_accum_v;
    end if;

    -- get the addition result for output
    add_res   <= std_logic_vector(add_res_u(w_data_g-1 downto 0));
    -- get MSB as carry
    add_carry <= add_res_u(w_data_g);
  end process addition_proc;

  multiply_proc : process (clk, rst)
    variable prod_vector_v  : std_logic_vector(2*w_data_g downto 0);
    variable accum_v        : std_logic_vector(w_data_g - 1 downto 0);
    variable multiplier_v   : std_logic_vector(w_data_g - 1 downto 0);
    variable multiplicand_v : std_logic_vector(w_data_g - 1 downto 0);
    variable enb_add        : std_logic;
  begin
    if (rst = '0') then
      multiplicand_r <= (others => '0');
      multiplier_r   <= (others => '0');
      accum_r        <= (others => '0');
      prod_vector_r  <= (others => '0');
    elsif rising_edge(clk) then
      if (enb = '1') then
        -- get data for next stage:
        -- prod_vector stores both accumulator value and multiplier
        multiplicand_v := multiplicand_r;
        prod_vector_v  := prod_vector_r;
        multiplier_v   := prod_vector_v(w_data_g-1 downto 0);
        accum_v        := prod_vector_v(2*w_data_g-1 downto w_data_g);

        -- during mult initialisation, store input data and reset accumulator
        if (mult_init = '1') then
          -- get the input vectors 
          multiplicand_v := mult_a_i;
          multiplier_v   := mult_b_i;
          accum_v        := (others => '0');

          -- initial prod_vector value is set as initial
          -- values of accum and multiplier preceded with '0'
          -- for the carry bit
          prod_vector_v := '0' & accum_v & multiplier_v;
        else -- if multiplication is not in initialisation
          if (mult_en_r = '1') then
          -- accumulator value comes from addition
            accum_v       := add_res;
            -- multiplier value is same
            multiplier_v  := multiplier_r;
            -- create product vector using carry bit from adder
            prod_vector_v := add_carry & accum_v & multiplier_v;
            -- right shift the entier product vector
            prod_vector_v := std_logic_vector(shift_right(unsigned(prod_vector_v),1));
            -- get new values of multiplier and accumulator
            multiplier_v  := prod_vector_v(w_data_g-1 downto 0);
            accum_v       := prod_vector_v(2*w_data_g-1 downto w_data_g);
          end if;
        end if;

        -- store final stage results for use next stage
        prod_vector_r  <= prod_vector_v;
        multiplicand_r <= multiplicand_v;
        multiplier_r   <= multiplier_v;
        accum_r        <= accum_v;

        if (clr = '1') then
        end if;
      end if;
    end if;
  end process multiply_proc;


  done_o   <= done_r;
  busy_o   <= internal_busy;
  mult_p_o <= prod_vector_r(2*w_data_g-1 downto 0) when done_r = '1' else (others => '0');

end arch;