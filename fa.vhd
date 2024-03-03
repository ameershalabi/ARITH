--------------------------------------------------------------------------------
-- Title       : A simple full adder
-- Project     : hdl_arith
--------------------------------------------------------------------------------
-- File        : fa.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 27 00:00:00 2020
-- Last update : Sun Mar  3 01:16:43 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A simple full adder
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fa is
	port (
		a_i : in std_logic;
		b_i : in std_logic;
		c_i : in std_logic;

		s_o : out std_logic;
		c_o : out std_logic
	);
end entity fa;

architecture arch of fa is
begin
	s_o <= a_i xor b_i xor c_i;
	c_o <= (a_i and b_i) or (a_i and c_i) or (b_i and c_i);
end architecture arch;


