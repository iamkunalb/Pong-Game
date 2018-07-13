LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
LIBRARY lpm;
USE lpm.lpm_components.ALL;

PACKAGE de0core IS
	COMPONENT vga_sync
 		PORT(clock_25Mhz, red, green, blue	: IN	STD_LOGIC;
         	red_out, green_out, blue_out	: OUT 	STD_LOGIC;
			horiz_sync_out, vert_sync_out	: OUT 	STD_LOGIC;
			pixel_row, pixel_column			: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
	END COMPONENT;
END de0core;

-- Bouncing Ball Video 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_SIGNED.all;
LIBRARY work;
USE work.de0core.all;

--ball entity
ENTITY game IS
	Generic(ADDR_WIDTH: integer := 12; DATA_WIDTH: integer := 1);

		PORT(SIGNAL PB1, buttonExit, Clock, pause, gameOn, gameMode, arrow, signAngle, signAngle2, signAngle3: IN std_logic;
				Signal mouse_col : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
				signal ranNumX,ranAngle, ranNumX2, ranAngle2, ranNumX3,  ranAngle3: in integer range 0 to 511;
			  SIGNAL Red,Green,Blue 			: OUT std_logic;
			  SIGNAL Horiz_sync,Vert_sync		: OUT std_logic);		
END game;
--game architecture
architecture behavior of game is
	--getting char_rom component
	component char_rom
		PORT(
		character_address	:	IN STD_LOGIC_VECTOR (5 DOWNTO 0);
		font_row, font_col	:	IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		clock				: 	IN STD_LOGIC ;
		rom_mux_output		:	OUT STD_LOGIC);
	end component;
	
	--getting mouse component
	component mouse
		PORT( clock_25Mhz, reset 			: IN std_logic;
			SIGNAL mouse_data				: INOUT std_logic;
			SIGNAL mouse_clk 				: INOUT std_logic;
			SIGNAL left_button, right_button: OUT std_logic;
			SIGNAL mouse_cursor_row 		: OUT std_logic_vector(9 DOWNTO 0); 
			SIGNAL mouse_cursor_column 		: OUT std_logic_vector(9 DOWNTO 0));
	end component;
	
	-- Video Display Signals   
	SIGNAL Red_Data, Green_Data, Blue_Data, vert_sync_int, reset, Ball_on, Direction	: std_logic;
	SIGNAL Size 								: std_logic_vector(9 DOWNTO 0);  
	--ball 1 attributes
	SIGNAL Ball_Y_motion, Ball_X_motion : std_logic_vector(9 DOWNTO 0);
	SIGNAL Ball_Y_pos				: std_LOGIC_VECTOR(9 downto 0);
	SIGNAL Ball_X_pos				: std_logic_vector(11 DOWNTO 0);

	--ball 2 attributes
	SIGNAL Ball_Y_motion_2, Ball_X_motion_2 : std_logic_vector(9 DOWNTO 0);
	SIGNAL Ball_Y_pos_2				: std_LOGIC_VECTOR(9 downto 0);
	SIGNAL Ball_X_pos_2				: std_logic_vector(11 DOWNTO 0);
	SIGNAL ball_on_2 : std_logic;
	
	--ball 3 attributes
	SIGNAL Ball_Y_motion_3, Ball_X_motion_3 : std_logic_vector(9 DOWNTO 0);
	SIGNAL Ball_Y_pos_3				: std_LOGIC_VECTOR(9 downto 0);
	SIGNAL Ball_X_pos_3				: std_logic_vector(11 DOWNTO 0);
	SIGNAL ball_on_3 : std_logic;
	
	--bar attributes
	SIGNAL bar_Y_motion, bar_X_motion : std_logic_vector(9 DOWNTO 0);
	SIGNAL bar_Y_pos	: std_logic_vector(9 DOWNTO 0) := conv_STD_LOGIC_VECTOR(474, 10); --476 initially
	SIGNAL bar_X_pos : std_logic_vector(9 DOWNTO 0);
	signal mouseCol : std_logic_vector(3 DOWNTO 0);
	signal barOn : std_LOGIC;

	SIGNAL pixel_row, pixel_column: std_logic_vector(9 DOWNTO 0); 
	SIGNAL colour : STD_LOGIC;
	signal charAddress, titleAddress : STD_LOGIC_VECTOR (5 DOWNTO 0);
	signal charOn, titleOn : std_LOGIC;
	signal rom_mux_output, rom_mux_output2 : STD_LOGIC; 
	signal level1Passed, Level2Passed : STD_LOGIC := '0';
	signal score : integer range 0 to 90:= 0;
	signal level : integer range 0 to 63 := 49; 
	signal paddleSize : integer range 0 to 36 := 36;
	signal score_tens, score_ones : integer range 0 to 63 := 48;
	signal timerCount : integer range 0 to 120 := 0;
	signal sec_tens, sec_ones : integer range 0 to 63 := 48; 
	signal min_ones : integer range 0 to 63 := 50;
	signal counter : integer:= 0; 
	signal gameOver, youwin: std_LOGIC:= '0';
	constant level2Score : integer range 0 to 30:= 30;
	constant level3Score : integer range 0 to 60:= 60;
	
	BEGIN 
		--VGA SYNC component
		SYNC: vga_sync PORT MAP(clock_25Mhz => clock, red => red_data, green => green_data, blue => blue_data,red_out => red, green_out => green,
			blue_out => blue,horiz_sync_out => horiz_sync, vert_sync_out => vert_sync_int, pixel_row => pixel_row, pixel_column => pixel_column);
		--Char rom component for 16x16 text
		char: char_rom PORT MAP(clock =>clock, font_row=>pixel_row(3 downto 1), font_col=>pixel_column(3 downto 1), character_address=>charAddress, 
			rom_mux_output => rom_mux_output);
		--Char rom component for 32x32 text	
		char2: char_rom PORT MAP(clock =>clock, font_row=>pixel_row(4 downto 2), font_col=>pixel_column(4 downto 2), character_address=>titleAddress, 
			rom_mux_output => rom_mux_output2);
		--size of the ball
		Size <= CONV_STD_LOGIC_VECTOR(6,10);
		vert_sync <= vert_sync_int;
		
		--color scheme for the game
		Red_Data <=  '0';
		Green_Data <=  ((Ball_on OR ball_on_2 or ball_on_3) or (charOn AND rom_mux_output) or (titleOn AND rom_mux_output2) or barOn);
		Blue_Data <=   ((Ball_on OR ball_on_2 or ball_on_3) or barOn);
		
		--timer process for the 2 minute countdown 
		timer: process(sec_ones, sec_tens, clock, pause, gameover, youwin, min_ones, counter, timerCount)
		begin
			if(rising_edge(clock) and pause = '0') then
				if(gameon = '0') then
					min_ones <= 50;
					sec_ones <= 48;
					sec_tens <= 48;
				elsif(gameon = '1' and youwin = '0' and pause = '0' and gameover = '0') then
					if (counter < 25000000) then
						counter <= counter + 1;
					end if;
					if(counter = 25000000) then
					timerCount <= timerCount +1;
						if (sec_ones > 48) then
							sec_ones <= sec_ones - 1;
						elsif (sec_ones = 48) then
							sec_ones <= 57;
							sec_tens <= sec_tens - 1;
							if (sec_tens = 48) then
								sec_tens <= 53;
								min_ones <= min_ones - 1;
							end if;
						end if;
						counter <= 0;
					elsE	
						timerCount <= 0;
					end if;
				else
					min_ones <= min_ones;
					sec_ones <= sec_ones;
					sec_tens <= sec_tens;
				end if;
			end if;
		end process;

	
		--process to display the ball on screen
		ballDisplay: process (Ball_X_pos, Ball_Y_pos, pixel_column, pixel_row, Size, gameOn, gameMode, gameOver, youWin, score, Ball_X_pos_2, Ball_Y_pos_2, Ball_X_pos_3, Ball_Y_pos_3)
		begin
			--displaying ball 1 regardless of the game mode
			if((((gameOn = '1' and (gameMode = '0' or gameMode = '1'))) and (gameOver = '0') and youwin = '0') and 
					((((ball_X_pos - ("00" & pixel_column))*(ball_X_pos - ("00" & pixel_column)) + (ball_Y_pos - pixel_row)*(ball_y_pos - pixel_row)) <= (size*size))))THEN 
				Ball_on <= '1';
			ELSE
				Ball_on <= '0';
			END IF;
			--displaying ball 2 if the user proceeds onto the second level
			if( score >= level2Score and (((gameOn = '1' and gameMode = '0')) and (gameOver = '0') and youwin = '0') and
					((((ball_X_pos_2 - ("00" & pixel_column))*(ball_X_pos_2 - ("00" & pixel_column)) + (ball_Y_pos_2 - pixel_row)*(ball_y_pos_2 - pixel_row)) <= (size*size))))then -- (((('0' & ball_X_pos - pixel_column)*('0' & ball_X_pos - pixel_column) + ('0' & ball_Y_pos - pixel_row)*('0' & ball_y_pos - pixel_row)) <= (size*size))))THEN 
				Ball_on_2 <= '1';
			ELSE
				Ball_on_2 <= '0';
			END IF;
			--displaying ball 3 if the user proceeds onto the third level
			if( score >= level3Score and (((gameOn = '1' and gameMode = '0')) and (gameOver = '0') and youwin = '0') and 
					((((ball_X_pos_3 - ("00" & pixel_column))*(ball_X_pos_3 - ("00" & pixel_column)) + (ball_Y_pos_3 - pixel_row)*(ball_y_pos_3 - pixel_row)) <= (size*size))))then -- (((('0' & ball_X_pos - pixel_column)*('0' & ball_X_pos - pixel_column) + ('0' & ball_Y_pos - pixel_row)*('0' & ball_y_pos - pixel_row)) <= (size*size))))THEN 
				Ball_on_3 <= '1';
			ELSE
				Ball_on_3 <= '0';
			END IF;
		end process;


		--process which checks if the game is over
		gameOverPro:process(gameOver, gameOn, gameMode, score, min_ones, sec_ones, sec_tens, timerCount, score_tens, score_ones)
		begin
			--set gameOver to '1' if gameMode is practice and the user collects 90 points
			if (gameon = '1' and gameMode = '1' and score = 90) then
				gameOver <= '1';
			--set game over to '1' when timers hits 0 and user hasnt collected 90 points and is in single player game mode
			elsif (gameon = '1' and ((min_ones = 48 and sec_ones = 48 and sec_tens = 48) and score < 90 and gamemode = '0')) then
				gameOver <= '1';
			else
				gameOver <= '0';
			end if;
		end process; 

		--process to check if user has won the game
		youWinPro:process(youWin, gameOn, gameMode, score, min_ones, sec_ones, sec_tens, timerCount, score_tens, score_ones)
		begin
			--set youWin to '1' if timer is greater than 0 and score is 90
			if (gameon = '1' and (timerCount <= 120 and score_tens = 57 and score_ones = 48 and gameMode = '0')) then
				youWin <= '1';
			else
				youwin <= '0';
			end if;
		end process; 

		--deciding the size of paddle depending on current level 
		paddleProcess: process(level1Passed, level2Passed)
		begin
			--decrease paddle size to 26 is user on level 2
			if (gameMode = '0' and level1Passed = '1' and level2Passed = '0') then
				paddleSize <= 26;
			--decrese paddle size to 16 if user on level 3
			elsIF (gameMode = '0' and level1Passed = '1' and level2Passed = '1') then
				paddleSize <= 16;
			--leave paddle size to 36 if still on level 1
			elsE
				paddleSize <= 36;
			end if;
		end process;

		--process to display the bar depending on game mode and the level
		barDisplay: Process (pixel_column, pixel_row, Size, gameover, gameMode, youWin, paddleSize, level1Passed, level2Passed, bar_X_pos, bar_Y_pos, gameOn)
		BEGIN
			--barOn to be set to 0 initially
			barOn <= '0';
			--diplay the bar depending on current level 
			if(gameOn = '1' and gameOver = '0' and youwin = '0') then
					IF ('0' & bar_X_pos <= '0' & pixel_column + paddleSize) AND ('0' & bar_X_pos + paddleSize >= '0' & pixel_column) AND
						('0' & bar_Y_pos <= '0' & pixel_row + 2) AND ('0' & bar_Y_pos + 2 >= '0' & pixel_row ) THEN
						barOn <= '1';
					ELSE
						barOn <= '0';
					END IF;
			end if;
		END process barDisplay;

		--check if the ball hits hte bar and increrase score if it does so and reset values if game is exited
		colisionDetection: process
		BEGIN
			WAIT UNTIL vert_sync_int'event and vert_sync_int = '1';
			if (gameon = '1' and pause = '0' and gameOver = '0' and youwin = '0') then
					--ball 1 collision and positioning
					IF (Ball_Y_pos) >= CONV_STD_LOGIC_VECTOR(480,10) - Size THEN
						Ball_Y_motion <= - CONV_STD_LOGIC_VECTOR(6,10);
					ELSIF Ball_Y_pos <= Size THEN
						Ball_Y_motion <= CONV_STD_LOGIC_VECTOR(6,10);
					END IF;
					
					IF (Ball_X_pos) >= CONV_STD_LOGIC_VECTOR(640,12) - ('0' & Size) THEN
						Ball_X_motion <= - CONV_STD_LOGIC_VECTOR(6,10);
					ELSIF(Ball_X_pos) <= ('0' & Size) THEN
						Ball_X_motion <= CONV_STD_LOGIC_VECTOR(6,10);
					END IF;
					
					Ball_X_pos <= Ball_X_pos + Ball_X_motion;
					Ball_Y_pos <= Ball_Y_pos + Ball_Y_motion;
					
					--ball 2 collision and positioning
					IF (Ball_Y_pos_2) >= CONV_STD_LOGIC_VECTOR(480,10) - Size THEN
						Ball_Y_motion_2 <= - CONV_STD_LOGIC_VECTOR(7,10);
					ELSIF Ball_Y_pos_2 <= Size THEN
						Ball_Y_motion_2 <= CONV_STD_LOGIC_VECTOR(7,10);
					END IF;
					
					IF (Ball_X_pos_2) >= CONV_STD_LOGIC_VECTOR(640,12) - ('0' & Size) THEN
						Ball_X_motion_2 <= - CONV_STD_LOGIC_VECTOR(7,10);
					ELSIF(Ball_X_pos_2) <= ('0' & Size) THEN
						Ball_X_motion_2 <= CONV_STD_LOGIC_VECTOR(7,10);
					END IF;
					
					Ball_X_pos_2 <= Ball_X_pos_2 + Ball_X_motion_2;
					Ball_Y_pos_2 <= Ball_Y_pos_2 + Ball_Y_motion_2;
					
					--ball 3 collision and positioning
					IF (Ball_Y_pos_3) >= CONV_STD_LOGIC_VECTOR(480,10) - Size THEN
						Ball_Y_motion_3 <= - CONV_STD_LOGIC_VECTOR(8,10);
					ELSIF Ball_Y_pos_3 <= Size THEn
						Ball_Y_motion_3 <= CONV_STD_LOGIC_VECTOR(8,10);
					END IF;
					
					IF (Ball_X_pos_3) >= CONV_STD_LOGIC_VECTOR(640,12) - ('0' & Size) THEN
						Ball_X_motion_3 <= - CONV_STD_LOGIC_VECTOR(8,10);
					ELSIF(Ball_X_pos_3) <= ('0' & Size) THEN
						Ball_X_motion_3 <= CONV_STD_LOGIC_VECTOR(8,10);
					END IF;					
					
					Ball_X_pos_3 <= Ball_X_pos_3 + Ball_X_motion_3;
					Ball_Y_pos_3 <= Ball_Y_pos_3 + Ball_Y_motion_3;
					
					--ball 1 collision with the bar
					if ((('0' & ball_Y_pos + size >= '0' & bar_Y_pos - 2) AND ('0' & ball_X_pos <= '0' & bar_X_pos + paddleSize) AND ('0' & ball_x_pos >= '0' & bar_X_pos - paddleSize))) then
						--relocate the ball to a random x position after collision with the bar
						ball_X_pos <= CONV_STD_LOGIC_VECTOR(ranNumX,12);
						ball_y_pos <= CONV_STD_LOGIC_VECTOR(0,10);
						--check if the motion of the ball is supposed to be negative or positive
						if(signAngle = '1') then
							Ball_X_motion <= - CONV_STD_LOGIC_VECTOR(ranAngle,10);
						else
							Ball_X_motion <= CONV_STD_LOGIC_VECTOR(ranAngle,10);
						end if;
						--add score when ball hits bar
						score <= score + 1;
						if(score_ones < 57)then --57 is 9
							score_ones <= score_ones + 1;
						elsif(score_ones = 57) then
							score_ones <= 48; -- 48 is 0
							score_tens <= score_tens + 1;
						end if;	
					end if;
					
					--ball 2 collision with the bar, in level 2
					if (gameMode = '0' and level1Passed = '1' and (('0' & ball_Y_pos_2 + size >= '0' & bar_Y_pos - 2) AND ('0' & ball_X_pos_2 <= '0' & bar_X_pos + paddleSize) AND ('0' & ball_x_pos_2 >= '0' & bar_X_pos - paddleSize)))	then
						--relocate the ball to a random x position after collision with the bar
						ball_X_pos_2 <= CONV_STD_LOGIC_VECTOR(ranNumX2,12);
						ball_y_pos_2 <= CONV_STD_LOGIC_VECTOR(0,10);	
						--check if the motion of the ball is supposed to be negative or positive
						if(signAngle2 = '1') then
							Ball_X_motion_2 <= - CONV_STD_LOGIC_VECTOR(ranAngle2,10); 
						else
							Ball_X_motion_2 <= CONV_STD_LOGIC_VECTOR(ranAngle2,10);
						end if;
						--add score when ball hits bar
						score <= score + 1;
						if(score_ones < 57)then --57 is 9
							score_ones <= score_ones + 1;
						elsif(score_ones = 57) then
							score_ones <= 48; -- 48 is 0
							score_tens <= score_tens + 1;
						end if;
					end if;
					
					--ball 3 collision with the bar, in level 3
					if ( gameMode = '0' and level2Passed = '1' and level1Passed = '1' and (('0' & ball_Y_pos_3 + size >= '0' & bar_Y_pos - 2) AND ('0' & ball_X_pos_3 <= '0' & bar_X_pos + paddleSize) AND ('0' & ball_x_pos_3 >= '0' & bar_X_pos - paddleSize)))	then
						--relocate the ball to a random x position after collision with the bar
						ball_X_pos_3 <= CONV_STD_LOGIC_VECTOR(ranNumX3,12);
						ball_y_pos_3 <= CONV_STD_LOGIC_VECTOR(0,10);	
						--check if the motion of the ball is supposed to be negative or positive
						if(signAngle3 = '1') then
							Ball_X_motion_3 <= - CONV_STD_LOGIC_VECTOR(ranAngle3,10);
						else
							Ball_X_motion_3 <= CONV_STD_LOGIC_VECTOR(ranAngle3,10);
						end if;
						--add score when ball hits bar
						score <= score + 1;
						if(score_ones < 57)then --57 is 9
							score_ones <= score_ones + 1;
						elsif(score_ones = 57) then
							score_ones <= 48; -- 48 is 0
							score_tens <= score_tens + 1;
						end if;
						
					end if;
					
					--set the bar's x position to the mouse's column position
					bar_X_pos <= mouse_col;	
					
					--check if user passes a level
					if(score = level2Score) then 
						level1Passed <= '1';
						level <= 50; --2
					elsif(score = level3Score) then
						level2Passed <= '1';
						level <= 51; --3
					end if;
			end if;
			
			--reset all values to initial after game has finished
			if(gameon = '0') then
				--randomly locate the X position of the ball at the top of the screen for next game
				ball_y_pos <= CONV_STD_LOGIC_VECTOR(0,10);	
				ball_y_pos_2 <= CONV_STD_LOGIC_VECTOR(0,10);	
				ball_y_pos_3 <= CONV_STD_LOGIC_VECTOR(0,10);	
				ball_x_pos <= CONV_STD_LOGIC_VECTOR(ranNumX,12);	
				ball_x_pos_2 <= CONV_STD_LOGIC_VECTOR(ranNumX2,12);	
				ball_x_pos_3 <= CONV_STD_LOGIC_VECTOR(ranNumX3,12);	
				
				level1Passed <= '0';
				level2Passed <= '0';
				score <= 0;
				score_ones <= 48;
				score_tens <= 48;
				level <= 49;
			end if;
		END process colisionDetection;

		--display all text required for the game
		textDisplay:Process(pixel_column, pixel_row, gameOn, gameOver, youwin, gameMode, pause, charAddress, titleAddress, titleOn, score_tens,  score_ones, min_ones, sec_ones, sec_tens, level, arrow)
		begin
			charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
			charOn <= '0';
			titleAddress <= CONV_STD_LOGIC_VECTOR(32,6);
			titleOn <= '0';
			--displays score text, time text and the levels text, by characters 
			if(gameOn = '1') then
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(0,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
					--score
					--s
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(0,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(15,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--c
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(16,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(31,10))then
						charAddress <= CONV_STD_LOGIC_VECTOR(03,6); 
						charOn <= '1';
					--o	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(32,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(47,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--r	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(48,10)) AND (pixel_column <= conV_STD_LOGIC_VECTOR(63,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
						charOn <= '1';
					--e	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(64,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(79,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(5,6);
						charOn <= '1';
					--space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(80,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(97,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					-- score_tens
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(96,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(111,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(score_tens,6);
						charOn <= '1';
					--score_ones
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(112,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(127,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(score_ones,6);
						charOn <= '1';
					--timer
					--min_ones
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(288,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(303,10)) and gameMode = '0' ) then
						charAddress <= CONV_STD_LOGIC_VECTOR(min_ones,6);
						charOn <= '1'; -- is this part of scores? nah id say you can do thi
					--colon
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(304,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(319,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(46,6);
						charOn <= '1';
					--secT
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(320,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(335,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(sec_tens,6);
						charOn <= '1';
					--secO
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(336,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(351,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(sec_ones,6);
						charOn <= '1';
					--levels
					--l
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(480,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(495,10)) and gameMode = '0' ) then
						charAddress <= CONV_STD_LOGIC_VECTOR(12,6);
						charOn <= '1'; -- is this part of scores? nah id say you can do thi
					--e
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(496,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(511,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--v
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(512,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(527,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(22,6);
						charOn <= '1';
					--e
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(528,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(543,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--l
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(544,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(559,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(12,6);
						charOn <= '1';
					--colon
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(560,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(575,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(46,6);
						charOn <= '1';
					--levelten
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(576,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(591,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(48,6);
						charOn <= '1';
					--levelones
					elsif((pixel_column >= CONV_STD_LOGIC_VECTOR(592,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(607,10) and gameMode = '0' )) then
						charAddress <= CONV_STD_LOGIC_VECTOR(level,6);
						charOn <= '1';
					else
						charOn <= '0';-- 
					end if;
				else
					charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
					charOn <= '0';
				end if;
			end if;

			--displays pause screen when the user pauses the game
			if (pause = '1' and gameon = '1') then
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(255,10)) then
					--paused
					--p
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(255,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(16,6);
						charOn <= '1';
					--a
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(272,10))then
						charAddress <= CONV_STD_LOGIC_VECTOR(01,6);
						charOn <= '1';
					--u	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(273,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(288,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(21,6);
						charOn <= '1';
					--s	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(289,10)) AND (pixel_column <= conV_STD_LOGIC_VECTOR(304,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--e	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(305,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(320,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--d   
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(321,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(336,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(04,6);
						charOn <= '1';
					else
						charOn <= '0';
					end if;
				else
					charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
					charOn <= '0';
				end if;
			end if;

			--displays win screen when users wins the game
			if (youWin = '1') then	
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(255,10)) then
					--you win
					--Y
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(255,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(25,6);
						charOn <= '1';
					--o
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(272,10))then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--u	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(273,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(288,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(21,6);
						charOn <= '1';
					-- space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(289,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(304,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--w	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(305,10)) AND (pixel_column <= conV_STD_LOGIC_VECTOR(320,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(23,6);
						charOn <= '1';
					--i	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(321,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(336,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(09,6);
						charOn <= '1';
					--n
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(337,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(352,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(14,6);
						charOn <= '1';
					elSE
						charOn <= '0'; 
					end if;
				elsif(pixel_row >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(271,10)) then
					--p
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(144,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(159,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(16,6);
						charOn <= '1';
					--r
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(160,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(175,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
						charOn <= '1';
					--e
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(176,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(191,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--s
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(192,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(207,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--s
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(208,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(223,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(224,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(239,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--b
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(255,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(02,6);
						charOn <= '1';
					--u
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(271,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(21,6);
						charOn <= '1';
					--t
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(272,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(287,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--t
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(288,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(303,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--o
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(304,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(319,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--n
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(320,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(335,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(14,6);
						charOn <= '1';
					--0
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(336,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(351,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(48,6);
						charOn <= '1';
					--space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(352,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(367,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--t	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(368,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(383,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--o
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(384,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(399,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--space	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(400,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(415,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--e	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(416,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(431,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--x	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(432,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(447,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(24,6);
						charOn <= '1';
					--i	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(448,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(463,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(09,6);
						charOn <= '1';
					--t	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(464,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(479,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					else
						charOn <= '0';
					end if;
				else
					charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
					charOn <= '0';
				end if;
			end if;	
			
			--displays game over screen when users loses the game
			if (gameOver = '1') then
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(255,10)) then
					--game over
					--g
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(255,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(07,6);
						charOn <= '1';
					--a
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(272,10))then
						charAddress <= CONV_STD_LOGIC_VECTOR(01,6);
						charOn <= '1';
					--m	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(273,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(288,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(13,6);
						charOn <= '1';
					--e	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(289,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(304,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					-- space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(305,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(320,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--o	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(321,10)) AND (pixel_column <= conV_STD_LOGIC_VECTOR(336,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--v	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(337,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(352,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(22,6);
						charOn <= '1';
					--e
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(353,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(368,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--r	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(369,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(384,10)) then 
						charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
						charOn <= '1'; 
					else
						charOn <= '0';
					end if;
			elsif(pixel_row >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(271,10)) then
					--p
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(144,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(159,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(16,6);
						charOn <= '1';
					--r
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(160,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(175,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
						charOn <= '1';
					--e
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(176,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(191,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--s
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(192,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(207,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--s
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(208,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(223,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(224,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(239,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--b
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(255,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(02,6);
						charOn <= '1';
					--u
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(271,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(21,6);
						charOn <= '1';
					--t
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(272,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(287,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--t
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(288,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(303,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--o
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(304,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(319,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--n
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(320,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(335,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(14,6);
						charOn <= '1';
					--0
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(336,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(351,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(48,6);
						charOn <= '1';
					--space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(352,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(367,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--t	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(368,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(383,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--o
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(384,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(399,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						charOn <= '1';
					--space	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(400,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(415,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--e	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(416,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(431,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--x	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(432,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(447,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(24,6);
						charOn <= '1';
					--i	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(448,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(463,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(09,6);
						charOn <= '1';
					--t	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(464,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(479,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					else
						charOn <= '0';
					end if;
				else
					charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
					charOn <= '0';
				end if;
			end if;
			
			--displayes the main menu screen
			if (gameOn = '0') then
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(240,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(255,10)) then
					--practice
					--p
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(0,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(15,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(16,6);
						charOn <= '1';
					--r
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(16,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(31,10))then
						charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
						charOn <= '1';
					--a	
					 elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(32,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(47,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(01,6);
						charOn <= '1';
					--c	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(48,10)) AND (pixel_column <= conV_STD_LOGIC_VECTOR(63,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(03,6);
						charOn <= '1';
					--t	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(64,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(79,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(20,6);
						charOn <= '1';
					--i
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(80,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(97,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(09,6);
						charOn <= '1';
					--c
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(96,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(111,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(03,6);
						charOn <= '1';
					--e
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(112,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(127,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--arrow	
					elsif (arrow = '1' and pixel_column >= CONV_STD_LOGIC_VECTOR(128,10) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(143,10))) then
						charAddress <= CONV_STD_LOGIC_VECTOR(31,6);
						charOn <= '1';
					else
						charOn <= '0';
					end if;
				end if;
					
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(270,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(285,10)) then
					--single player
					--s
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(0,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(15,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
						charOn <= '1';
					--i
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(16,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(31,10))then
						charAddress <= CONV_STD_LOGIC_VECTOR(09,6);
						charOn <= '1';
					--n	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(32,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(47,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(14,6);
						charOn <= '1';
					--g	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(48,10)) AND (pixel_column <= conV_STD_LOGIC_VECTOR(63,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(07,6);
						charOn <= '1';
					--l	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(64,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(79,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(12,6);
						charOn <= '1';
					--e
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(80,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(95,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--space
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(96,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(111,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
						charOn <= '1';
					--p
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(112,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(127,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(16,6);
						charOn <= '1';
					--l	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(128,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(143,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(12,6);
						charOn <= '1';
					--a
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(144,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(159,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(01,6);
						charOn <= '1';
					--y	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(160,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(175,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(25,6);
						charOn <= '1';
					--e	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(176,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(191,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(05,6);
						charOn <= '1';
					--r	
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(192,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(207,10)) then
						charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
						charOn <= '1';		
					--	arrow
					elsif (arrow = '0' and pixel_column >= CONV_STD_LOGIC_VECTOR(208,10) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(223,10))) then
						charAddress <= CONV_STD_LOGIC_VECTOR(31,6);
						charOn <= '1';
					else
						charOn <= '0';
					end if;
				end if;
					
							
				if(pixel_row >= CONV_STD_LOGIC_VECTOR(31,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(62,10)) then
					--pong (title)
					--P
					if(pixel_column >= CONV_STD_LOGIC_VECTOR(256,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(287,10)) then
						titleAddress <= CONV_STD_LOGIC_VECTOR(16,6);
						titleOn <= '1';
					--o
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(288,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(319,10)) then
						titleAddress <= CONV_STD_LOGIC_VECTOR(15,6);
						titleOn <= '1';
					--n
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(320,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(351,10)) then
						titleAddress <= CONV_STD_LOGIC_VECTOR(14,6);
						titleOn <= '1';
					--g
					elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(352,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(383,10)) then
						titleAddress <= CONV_STD_LOGIC_VECTOR(07,6);
						titleOn <= '1';
					else 
						titleOn <= '0';
					end if;
				else 
					titleAddress <= CONV_STD_LOGIC_VECTOR(32,6);
					titleOn <= '0';
				end if;	
		end if;
		end process textDisplay;
END behavior;
