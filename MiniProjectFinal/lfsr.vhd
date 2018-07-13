library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;

entity lfsr is 
	port (randomValue, randomAngle   :out integer range 0 to 511; 
			signAngle : out std_logic;
		clock    :in  std_logic);
end entity lfsr;

architecture rtl of lfsr is
	signal count : std_logic_vector (9 downto 0) := "0110101011"; --Initial value --

begin
   process (clock) 
	begin
		--create a random number using the LFSR method
		if rising_edge(clock) then
                count <= count(8) & (not(count(7) xor count(3)) & not(count(5) xor count(1)) & count(5)
						  & not(count(3) xor count(8)) & count(3) & count(2) & (count(4) xor count(6))
							& count(0) & count(9));
		end if;
   end process;
	--random value for X position of ball
	randomValue <= to_integer(unsigned(count(8 downto 0)));
	--random value for the angle of the motion of the ball
	randomAngle <= to_integer(unsigned(count(3 downto 0)));
	--assiginging random direction
	signAngle <= count(3);
end architecture;