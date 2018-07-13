library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
--
--entity LSFR is
--Port ( clock : in STD_LOGIC;
--       Q_x, q_y : out integer);
--end LSFR;
--
--architecture Behavioral of LSFR is
--signal Qt_x, Qt_y: STD_LOGIC_VECTOR(9 downto 0) := "0000000001"; 
--begin
--
--PROCESS(clock)
--variable tmp_x, tmp_y : STD_LOGIC := '0';
--variable Qt_xInt, Qt_yInt: integer;
--BEGIN
--
--IF rising_edge(clock) THEN
--		tmp_x := Qt_x(4) XOR Qt_x(3) XOR Qt_x(2) XOR Qt_x(0);
--		Qt_x <= tmp_x & Qt_x(9 downto 1);
--		Qt_xInt := to_integer(unsigned(Qt_x));
--		IF(Qt_x(9) = '0' AND (Qt_xint <= 640)) then
--			Q_x <= to_integer(signed(Qt_x));
--			--reckon this is fine? try it waiit 
--		end if;
--		
--		tmp_y := Qt_x(4) XOR Qt_x(3) XOR Qt_x(2) XOR Qt_x(0);
--		Qt_y <= tmp_x & Qt_x(9 downto 1);
--		Qt_yInt := to_integer(unsigned(Qt_y));
--		IF(Qt_y(9) = '0' AND (Qt_yint <= 480)) then
--			Q_y <= to_integer(signed(Qt_x));
--			--reckon this is fine? try it waiit 
--		end if;
--				
----		tmp_y := Qt_y(4) XOR Qt_y(3) XOR Qt_y(2) XOR Qt_y(0);
----		Qt_y <= tmp_y & Qt_y(7 downto 1);
----		IF(Qt_y(7) = '0' AND Qt_y <= "0001100100") then
----			Q_y <= to_integer(signed(Qt_y));
----			--reckon this is fine? try it waiit 
----		end if;
--		
--end if;
--END PROCESS;
--end architecture Behavioral;

--
--library ieee;
--    use ieee.std_logic_1164.all;

entity lsfr is
  port (q_x   :out integer;
		clock    :in  std_logic);
end entity;

architecture rtl of lsfr is
    signal count : std_logic_vector (9 downto 0) := "0000110100"; --Initial value --

begin
    process (clock) 
	begin
      if rising_edge(clock) then
                count <= count(8) & (not(count(7) xor count(3)) & not(count(5) xor count(1)) & count(5)
						  & not(count(3) xor count(8)) & count(3) & count(2) & (count(4) xor count(6))
						  & count(0) & count(9));
       end if;
    end process;
	
    q_x <= to_integer(unsigned(count(8 downto 0)));
end architecture;
















