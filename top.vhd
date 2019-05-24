----------------------------------------------------------------------------------
-- Company: FEKT VUT BRNO
-- Author: Vojtech Barta 203188, Roman Vomela 203375
-- 
-- Create Date:    	 
-- Design Name:	 
-- Module Name:    top - Behavioral 
-- Project Name: 	 Stopwatch project - VHDL
-- Target Devices: 
-- Tool versions:  ISE Project Navigator 14.7
-- Description: 
--
-- Dependencies:  coolrunner.ucf
--
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;					

entity top is
port (
	clk_i : in std_logic; -- clock signal freq = 10 kHz
	RST : in std_logic; -- RST button
	BTN : in std_logic; -- START/STOP button
	
	disp_sseg_o : out std_logic_vector(7 downto 0); -- defines segment of 7 seg. display
	disp_digit_o : out std_logic_vector(3 downto 0) -- defines digit
);
end top;

architecture Behavioral of top is

--insert definition of signals for entity top
	signal segments : std_logic_vector(6 downto 0) := (others => '0');
	signal digit : std_logic_vector(3 downto 0) := (others => '0');
	signal seg_refresh_cnt : std_logic_vector(4 downto 0) := (others => '0');
	signal seg_refresh : std_logic := '0'; -- one period of signal to refresh the LED
	signal centis_cnt : std_logic_vector(6 downto 0) := (others => '0');
	signal centis : std_logic := '0'; -- one period of signal to calculate the number of centiseconds
	signal segment1, segment2, segment3, segment4 : integer := 0; --for the 4 segments on the seven-segment display
	signal PS, NS : std_logic := '0'; --present state, next state
	signal ss1, ss2, en : std_logic := '0';
	signal digit1, digit2 : std_logic_vector(1 downto 0) := (others => '0'); -- stands for one of 4 segments on 7seg. display
	

begin

	-- generates signal with new freq = 450 Hz
	clk_450: process(clk_i, RST)
	begin
		if(RST = '1') then
			seg_refresh_cnt <= (others => '0');
		elsif rising_edge(clk_i) then
			if (seg_refresh_cnt = "10110") then -- counts to 22, 450Hz * 22 ~ 10kHz (not exactly because of inaccuracy)
				seg_refresh <= '1';
				seg_refresh_cnt <= (others => '0');
			else
				seg_refresh <= '0';
			end if;
			seg_refresh_cnt <= seg_refresh_cnt + 1;
		end if;
	end process clk_450;
	
	-- generates signal which counts centiseconds (ms/100)
	clk_centi: process(clk_i, RST)
	begin
		if(RST = '1') then
			centis_cnt <= (others => '0');
		elsif rising_edge(clk_i) then
			if (centis_cnt = "1100100") then -- counts to 100
				centis <= '1';
				centis_cnt <= (others => '0');
			else
				centis <= '0';
			end if;
			centis_cnt <= centis_cnt + 1;
		end if;
	end process clk_centi;
	
	--process handling transition to the next state of final state machine (states are: clockwatch stopped / clockwatch running)
	fsm: process(clk_i)
	begin
		if(rising_edge(clk_i)) then
			PS <= NS;
		end if;
	end process fsm;
	
	-- process of adding the centiseconds, if there is an overflow, sets the higher value +1
	adding: process(BTN, RST, centis, PS, NS, en, ss1, ss2, segment1, segment2, segment3, segment4)
	begin
		if RST = '1' then --if reset is "high" then the clock will display all zeros
			segment1 <= 0;
			segment2 <= 0;
			segment3 <= 0;
			segment4 <= 0;
		else
			if (rising_edge(centis)) then
				if BTN = '1' then --to detect "risingedge" for the button
					ss1 <= '1';
				elsif BTN = '0' then
					ss1 <= '0';
				end if;
				ss2 <= ss1;
				
				if ss2 = '0' and ss1 = '1' then
					en <= not en;
				end if;
				
				case (PS) is
					when '1' => -- when the clock is running
						if en = '1' then
							NS <= '1';
							segment4 <= segment4 + 1; --code to have the stopwatch actually count
							if segment4 = 9 then
								segment3 <= segment3 + 1;
								segment4 <= 0;
								if segment3 = 9 then
									segment2 <= segment2 + 1;
									segment3 <= 0;
									if segment2 = 9 then
										segment1 <= segment1 + 1;
										segment2 <= 0;
										if segment1 = 9 then --rolls over when it gets to 99.99
											segment1 <= 0;
											segment2 <= 0;
											segment3 <= 0;
											segment4 <= 0;
										end if;
									end if;
								end if;
							end if;
						elsif en = '0' then
							NS <= '0';
						end if;
					when '0' => --when the stopwatch is stopped
						if en = '0' then
							NS <= '0';
							segment1 <= segment1;
							segment2 <= segment2;
							segment3 <= segment3;
							segment4 <= segment4;
						elsif en = '1' then
							NS <= '1';
						end if;
					when others => -- NEVER HAPPENS
						if en = '0' then
							NS <= '0';
							segment1 <= segment1;
							segment2 <= segment2;
							segment3 <= segment3;
							segment4 <= segment4;
						elsif en = '1' then
							NS <= '1';
						end if;
				end case;
			end if;
		end if;
	end process adding;
	
	-- displaying the values on sevensegment display
	display: process(seg_refresh)
	begin
		if (rising_edge(seg_refresh)) then
			-- process goes through all of the digits
			case (digit1) is
				when "00" =>
					disp_digit_o <= "0111";
				when "01" =>
					disp_digit_o <= "1011";
				when "10" =>
					disp_digit_o <= "1101";
				when "11" =>
					disp_digit_o <= "1110";
				when others =>
					disp_digit_o <= "0111";
			end case;
			
			case (digit2) is
				when "00" =>
					case (segment1) is
						when 0 =>
							disp_sseg_o <= "00000011";
						when 1 =>
							disp_sseg_o <= "10011111";
						when 2 =>
							disp_sseg_o <= "00100101";
						when 3 =>
							disp_sseg_o <= "00001101";
						when 4 =>
							disp_sseg_o <= "10011001";
						when 5 =>
							disp_sseg_o <= "01001001";
						when 6 =>
							disp_sseg_o <= "01000001";
						when 7 =>
							disp_sseg_o <= "00011111";
						when 8 =>
							disp_sseg_o <= "00000001";
						when 9 =>
							disp_sseg_o <= "00011001";
						when others =>
							disp_sseg_o <= "11111111";
					end case;
			
				when "01" =>
					case (segment2) is
						when 0 =>
							disp_sseg_o <= "00000010";
						when 1 =>
							disp_sseg_o <= "10011110";
						when 2 =>
							disp_sseg_o <= "00100100";
						when 3 =>
							disp_sseg_o <= "00001100";
						when 4 =>
							disp_sseg_o <= "10011000";
						when 5 =>
							disp_sseg_o <= "01001000";
						when 6 =>
							disp_sseg_o <= "01000000";
						when 7 =>
							disp_sseg_o <= "00011110";
						when 8 =>
							disp_sseg_o <= "00000000";
						when 9 =>
							disp_sseg_o <= "00011000";
						when others =>
							disp_sseg_o <= "11111110";
					end case;
			
				when "10" =>
					case (segment3) is
						when 0 =>
							disp_sseg_o <= "00000011";
						when 1 =>
							disp_sseg_o <= "10011111";
						when 2 =>
							disp_sseg_o <= "00100101";
						when 3 =>
							disp_sseg_o <= "00001101";
						when 4 =>
							disp_sseg_o <= "10011001";
						when 5 =>
							disp_sseg_o <= "01001001";
						when 6 =>
							disp_sseg_o <= "01000001";
						when 7 =>
							disp_sseg_o <= "00011111";
						when 8 =>
							disp_sseg_o <= "00000001";
						when 9 =>
							disp_sseg_o <= "00011001";
						when others =>
							disp_sseg_o <= "11111111";
					end case;
					
				when "11" =>
					case (segment4) is
						when 0 =>
							disp_sseg_o <= "00000011";
						when 1 =>
							disp_sseg_o <= "10011111";
						when 2 =>
							disp_sseg_o <= "00100101";
						when 3 =>
							disp_sseg_o <= "00001101";
						when 4 =>
							disp_sseg_o <= "10011001";
						when 5 =>
							disp_sseg_o <= "01001001";
						when 6 =>
							disp_sseg_o <= "01000001";
						when 7 =>
							disp_sseg_o <= "00011111";
						when 8 =>
							disp_sseg_o <= "00000001";
						when 9 =>
							disp_sseg_o <= "00011001";
						when others =>
							disp_sseg_o <= "11111111";
					end case;
				when others =>
					digit1 <= digit1;
					digit2 <= digit2;					
			end case;
			digit1 <= digit1 + 1;
			digit2 <= digit2 + 1;
		end if;
	end process display;
	
end Behavioral;

