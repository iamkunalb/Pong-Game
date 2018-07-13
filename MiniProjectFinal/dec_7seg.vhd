library ieee;
use ieee.std_logic_1164.all;

entity dec_7seg is 
	port (
		bcd: in std_logic_vector (3 downto 0);
		digitvalue: out std_logic_vector (6 downto 0) -- boolean values to trigger the 7 segments on display
		);
end entity dec_7seg;

architecture behaviour of dec_7seg is
begin

	process(bcd)
	begin
		case bcd is -- Active high       6543210
			when "0000" => digitvalue <= "1000000"; -- '0'
			when "0001" => digitvalue <= "1111001"; -- '1'
			when "0010" => digitvalue <= "0100100"; -- '2'
			when "0011" => digitvalue <= "0110000"; -- '3'
			when "0100" => digitvalue <= "0011001"; -- '4'
			when "0101" => digitvalue <= "0010010"; -- '5'
			when "0110" => digitvalue <= "0000010"; -- '6'
			when "0111" => digitvalue <= "1111000"; -- '7'
			when "1000" => digitvalue <= "0000000"; -- '8'
			when "1001" => digitvalue <= "0011000"; -- '9'
		   when "1010" => digitvalue <= "0001000"; -- A
		   when "1011" => digitvalue <= "0000011"; -- B
		   when "1100" => digitvalue <= "1000110"; -- C
		   when "1101" => digitvalue <= "0100001"; -- D
		   when "1110" => digitvalue <= "0000110"; -- E
		   when "1111" => digitvalue <= "0001110"; -- F
		end case;
	end process;
end architecture;