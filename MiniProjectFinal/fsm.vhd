library ieee;
use ieee.std_logic_1164.all;

entity fsm is 
	port( clock : in std_logic;
			button, buttonExit: in std_logic;
			mode : in std_logic;
			GameOn: out std_logic;
			GameMode : out std_logic
		);
end entity fsm;

architecture behaviour of fsm is 
	type state is (menu, singlePlayer, practice);
	signal currentState, nextState: state := menu;
	
	begin
		--check the current state of the game and decide the next state depending on gam eoconditions
		process(currentState, button, clock, nextState)
		begin 
		if(rising_edge(clock)) then
			case currentState is
				when menu =>
					--if practice mode selected
					if(mode = '1' and button = '0') then
						nextState <= practice;
						GameMode <= '1';
						gameon <= '1';
					--if single player selected
					elsif(mode = '0' and button = '0') then 
						nextState <= singlePlayer;
						GameMode <= '0';
						gameon <= '1';
					else 
						nextState <= menu;
						gameon <= '0';
					end if;
				when singlePlayer =>
					--exit to main menu
					if(buttonExit = '0') then
						nextState <= menu;
						gameon <= '0';
					else 
						nextState <= singlePlayer;
						gameon <= '1';
					end if;
				when practice =>
					--exit to main menu
					if(buttonExit = '0') then
						nextState <= menu;
						gameon <= '0';
					else 
						nextState <= practice;
						gameon <= '1'; 
					end if;
			end case;
		end if; 
		currentState <= nextState;
		end process;			
end architecture behaviour;			

