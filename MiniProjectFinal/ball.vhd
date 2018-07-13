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

		PORT(SIGNAL PB1, PB2, Clock, pause 			: IN std_logic;
				Signal mouse_col : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			  SIGNAL Red,Green,Blue 			: OUT std_logic;
			  SIGNAL Horiz_sync,Vert_sync		: OUT std_logic);		
	END game;

--ball architecture
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
	
	--get random number thing
	component rand_num
		Port( clock : in STD_LOGIC;
       Q_x, Q_y : out integer);
	end component;

	-- Video Display Signals   
	SIGNAL Red_Data, Green_Data, Blue_Data, vert_sync_int, reset, Ball_on, Direction	: std_logic;
	SIGNAL Size 								: std_logic_vector(9 DOWNTO 0);  
	SIGNAL Ball_Y_motion, Ball_X_motion : std_logic_vector(9 DOWNTO 0);
	SIGNAL Ball_Y_pos, Ball_X_pos				: std_logic_vector(9 DOWNTO 0);

	SIGNAL bar_Y_motion, bar_X_motion : std_logic_vector(9 DOWNTO 0);
	SIGNAL bar_Y_pos	: std_logic_vector(9 DOWNTO 0) := conv_STD_LOGIC_VECTOR(475, 10);
	SIGNAL bar_X_pos	: std_logic_vector(9 DOWNTO 0);
	signal mouseCol : std_logic_vector(3 DOWNTO 0);
	signal barOn : std_LOGIC;

	SIGNAL pixel_row, pixel_column: std_logic_vector(9 DOWNTO 0); 
	SIGNAL colour : STD_LOGIC;
	signal charAddress : STD_LOGIC_VECTOR (5 DOWNTO 0);
	signal charOn : std_LOGIC;
	signal rom_mux_output : STD_LOGIC;

	signal score_tens, score_ones : integer := 48;

	
	
	signal random_num_x, random_num_y : integer;
	
	
	
	BEGIN 
		SYNC: vga_sync PORT MAP(clock_25Mhz => clock, red => red_data, green => green_data, blue => blue_data,red_out => red, green_out => green, blue_out => blue,horiz_sync_out => horiz_sync, vert_sync_out => vert_sync_int,
					pixel_row => pixel_row, pixel_column => pixel_column);
				
		char: char_rom PORT MAP(clock =>clock, font_row=>pixel_row(3 downto 1), font_col=>pixel_column(3 downto 1), character_address=>charAddress, rom_mux_output => rom_mux_output);
		
		random: rand_num PORT MAP(clock => clock, Q_x => random_num_x, Q_Y => random_num_y );
		
		
	Size <= CONV_STD_LOGIC_VECTOR(4,10);
	vert_sync <= vert_sync_int;

	Red_Data <=  '1';
	-- Turn off Green and Blue when displaying ball
	Green_Data <= NOT (Ball_on OR (charOn AND rom_mux_output) or barOn);
	--Blue_Data <=  NOT (barOn);
	Blue_Data <=  NOT (Ball_on or barOn);


	RGB_Display: Process (Ball_X_pos, Ball_Y_pos, pixel_column, pixel_row, Size)
	BEGIN
--	
--	if(pixel_column >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(15,10)) AND
--		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(19,6);
--		charOn <= '1';
--	
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(16,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(30,10)) AND
--	(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(03,6);
--		charOn <= '1';
--		
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(31,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(45,10)) AND
--		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(15,6);
--		charOn <= '1';
--		
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(46,10)) AND (pixel_column <= V_STD_LOGIC_VECTOR(60,10)) AND
--		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(18,6);
--		charOn <= '1';
--		
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(61,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(75,10)) AND
--		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(5,6);
--		charOn <= '1';
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(76,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(90,10)) AND
--		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(32,6);
--		charOn <= '1';
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(91,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(105,10)) AND
--		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(score_tens,6);
--		charOn <= '1';
--	
--	elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(106,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(120,10)) AND
--	(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
--		charAddress <= CONV_STD_LOGIC_VECTOR(score_ones,6);
--		charOn <= '1';
--	else
--			charOn <= '0';
--	end if;

		if(pixel_column >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(15,10)) AND
			(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
			charAddress <= CONV_STD_LOGIC_VECTOR(score_tens,6);
			charOn <= '1';
		
		elsif(pixel_column >= CONV_STD_LOGIC_VECTOR(16,10)) AND (pixel_column <= CONV_STD_LOGIC_VECTOR(30,10)) AND
		(pixel_row >= CONV_STD_LOGIC_VECTOR(1,10)) AND (pixel_row <= CONV_STD_LOGIC_VECTOR(15,10)) then
			charAddress <= CONV_STD_LOGIC_VECTOR(score_ones,6);
			charOn <= '1';
		else
				charOn <= '0';
		end if;

-- Bar dispay
	 IF ('0' & bar_X_pos <= '0' & pixel_column + 36) AND ('0' & bar_X_pos + 36 >= '0' & pixel_column) AND
		('0' & bar_Y_pos <= '0' & pixel_row + 2) AND ('0' & bar_Y_pos + 2 >= '0' & pixel_row ) THEN
			barOn <= '1';
		ELSE
			barOn <= '0';
	END IF;


-- Set Ball_on ='1' to display ball
	 IF ('0' & Ball_X_pos <= '0' & pixel_column + Size) AND ('0' & Ball_X_pos + Size >= '0' & pixel_column) AND
		('0' & Ball_Y_pos <= '0' & pixel_row + Size) AND ('0' & Ball_Y_pos + Size >= '0' & pixel_row ) THEN
			Ball_on <= '1';
		ELSE
			Ball_on <= '0';
	END IF;
END process RGB_Display;

Move_Ball: process
BEGIN
	WAIT UNTIL vert_sync_int'event and vert_sync_int = '1';
	
	if (pause = '1') then
			-- Bounce off top or bottom of screen
			IF ('0' & Ball_Y_pos) >= CONV_STD_LOGIC_VECTOR(480,10) - Size THEN
				Ball_Y_motion <= - CONV_STD_LOGIC_VECTOR(3,10);
			ELSIF Ball_Y_pos <= Size THEN
				Ball_Y_motion <= CONV_STD_LOGIC_VECTOR(3,10);
			END IF;
			
			IF ('0' & Ball_X_pos) >= CONV_STD_LOGIC_VECTOR(640,11) - Size THEN
				Ball_X_motion <= - CONV_STD_LOGIC_VECTOR(3,10);
			ELSIF('0' & Ball_X_pos) <= Size THEN
				Ball_X_motion <= CONV_STD_LOGIC_VECTOR(3,10);
			END IF;
		
			-- Compute next ball Y position
			Ball_X_pos <= Ball_X_pos + Ball_X_motion;
			
			-- Compute next ball Y position
			Ball_Y_pos <= Ball_Y_pos + Ball_Y_motion;	
			
			--if it hits the bar then relocate
			if(ball_Y_pos + Size >= bar_y_pos-2) and ((ball_x_pos <= mouse_col + 36) and (ball_X_pos >= mouse_col - 36)) then
				
				
				Ball_X_pos <= CONV_STD_LOGIC_VECTOR(random_num_x,10);
				Ball_y_pos <= CONV_STD_LOGIC_VECTOR(random_num_y,10);
				
				
				
				if(score_ones < 57)then
					score_ones <= score_ones + 1;
				elsif(score_ones = 57) then
					score_ones <= 48;
					score_tens <= score_tens + 1;
				end if;	
			end if;	
			bar_X_pos <= mouse_col;
	end if;
END process Move_Ball;
END behavior;
