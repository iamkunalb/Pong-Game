library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity rand_num is
Port ( clock : in STD_LOGIC;
       Q_x, Q_y : out integer);
end rand_num;

architecture Behavioral of rand_num is
signal Qt_x, Qt_y: STD_LOGIC_VECTOR(7 downto 0) := "00000001"; 
begin

PROCESS(clock)
variable tmp_x, tmp_y : STD_LOGIC := '0';
BEGIN

IF rising_edge(clock) THEN
		tmp_x := Qt_x(4) XOR Qt_x(3) XOR Qt_x(2) XOR Qt_x(0);
		Qt_x <= tmp_x & Qt_x(7 downto 1);
		IF(Qt_x(7) = '0' AND Qt_x <= "1010000000") then
			Q_x <= to_integer(signed(Qt_x));
			--reckon this is fine? try it waiit 
		end if;
				
		tmp_y := Qt_y(4) XOR Qt_y(3) XOR Qt_y(2) XOR Qt_y(0);
		Qt_y <= tmp_y & Qt_y(7 downto 1);
		IF(Qt_y(7) = '0' AND Qt_y <= "0001100100") then
			Q_y <= to_integer(signed(Qt_y));
			--reckon this is fine? try it waiit 
		end if;
		
end if;
END PROCESS;
end architecture Behavioral;
-- how do we convert to int>? i think we did it in ball
--