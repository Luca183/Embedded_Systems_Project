----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.09.2021 10:50:37
-- Design Name: 
-- Module Name: tb_fifo_ftdi_bridge_2 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity tb_TX is
--  Port ( );
end tb_TX;

architecture Behavioral of tb_TX is


	--------- Timing -----------
	constant	CLK_PERIOD 	:	TIME	:= 10 ns;
	constant	RESET_WND	:	TIME	:= 10*CLK_PERIOD;
	----------------------------

	--- TB Initialiazzations ---
	constant	TB_CLK_INIT		:	STD_LOGIC	:= '1';
	constant	TB_RESET_INIT 	:	std_logic_vector(0 to 0)	:= (others => '1');
	----------------------------


	------- Clock/Reset  -------
	signal	reset	:	std_logic_vector(0 to 0)	:= TB_RESET_INIT;
	signal	clk		:	STD_LOGIC	:= '1';
	----------------------------
	
	--signal count : unsigned(7 downto 0) := (others => '0');
	
	
	signal OEn_ftdi : STD_LOGIC;
	signal RDn_ftdi : STD_LOGIC;
	signal RXFn_ftdi : STD_LOGIC := '1';
	signal TXEn_ftdi : STD_LOGIC := '1';
	signal WRn_ftdi : STD_LOGIC;
	signal data_INOUT_ftdi : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
--	signal data_IN_ftdi : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
--	signal data_OUT_ftdi : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
	signal m_axis_tdata : STD_LOGIC_VECTOR ( 7 downto 0 );
	signal m_axis_tready : STD_LOGIC := '0';
	signal m_axis_tvalid : STD_LOGIC;
	signal s_axis_tdata : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
	signal s_axis_tready : STD_LOGIC;
	signal s_axis_tvalid : STD_LOGIC := '0';
	
	
	signal s_axis_tdata_int : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
	
	type state_type is (FIFO_EMPTY, FIFO_FULL, FTDI_EMPTY, FTDI_FULL);
	constant TB: state_type := FTDI_EMPTY; -- cambiare per selezionare il TB
	
	
	
	
	
	component fifo_ftdi_bridge_wrapper is
		port (
			OEn_ftdi_0 : out STD_LOGIC;
			Op1_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
			RDn_ftdi_0 : out STD_LOGIC;
			RXFn_ftdi_0 : in STD_LOGIC;
			TXEn_ftdi_0 : in STD_LOGIC;
			WRn_ftdi_0 : out STD_LOGIC;
			clk_in1_0 : in STD_LOGIC;
			data_INOUT_ftdi_0 : inout STD_LOGIC_VECTOR ( 7 downto 0 );
--			data_IN_ftdi_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
--			data_OUT_ftdi_0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
			m_axis_0_tdata : out STD_LOGIC_VECTOR ( 7 downto 0 );
			m_axis_0_tready : in STD_LOGIC;
			m_axis_0_tvalid : out STD_LOGIC;
			s_axis_0_tdata : in STD_LOGIC_VECTOR ( 7 downto 0 );
			s_axis_0_tready : out STD_LOGIC;
			s_axis_0_tvalid : in STD_LOGIC
		 );	
	end component;


begin

dut_fifo_ftdi_bridge : fifo_ftdi_bridge_wrapper

		Port Map( 
		
		
			OEn_ftdi_0 => OEn_ftdi,
			Op1_0 => reset,
			RDn_ftdi_0 => RDn_ftdi,
			RXFn_ftdi_0 => RXFn_ftdi,
			TXEn_ftdi_0 => TXEn_ftdi,
			WRn_ftdi_0 => WRn_ftdi,
			clk_in1_0 => clk,
			data_INOUT_ftdi_0 => data_INOUT_ftdi,
--			data_IN_ftdi_0 => data_IN_ftdi,
--			data_OUT_ftdi_0 => data_OUT_ftdi,
			m_axis_0_tdata => m_axis_tdata,
			m_axis_0_tready => m_axis_tready,
			m_axis_0_tvalid => m_axis_tvalid,
			s_axis_0_tdata => s_axis_tdata,
			s_axis_0_tready => s_axis_tready,
			s_axis_0_tvalid => s_axis_tvalid
			
		
		);


clk <= not clk after CLK_PERIOD/2;

s_axis_tdata <= s_axis_tdata_int;

	----- Reset Process --------
	reset_wave :process
	begin
		reset <= TB_RESET_INIT;
		wait for RESET_WND;
		
		reset <= not reset;
		wait;
    end process;	
	----------------------------
	 
	 
	FT232H_proc: process
	begin
	
	wait for RESET_WND;
	
		--TXEn_ftdi <= '0';
		--wait until rising_edge(clk);
	
	wait;
	end process;
	
	

	
	
	
	
	
   ------ Stimulus process -------
	
    stim_proc: process--(clk)
        variable count : integer := 0;
    begin		
		wait for RESET_WND;	
--		if rising_edge(clk) then
		
--			if s_axis_tvalid = '0' then
--				s_axis_tdata_int <= x"ab";
--				s_axis_tvalid <= '1';
--			elsif count > 50 then
--				if s_axis_tready = '1' then
--					s_axis_tvalid <= '0';
--				end if;
--			elsif s_axis_tready = '1' then
--				s_axis_tdata_int <= std_logic_vector(to_unsigned(count,8));
--				s_axis_tvalid <= '1';
--				count := count + 1;
--			end if;
--		end if;
		if TB = FIFO_EMPTY then
		
			TXEn_ftdi <= '0';
			s_axis_tdata_int <= x"ab";
			s_axis_tvalid <= '1';
			wait until rising_edge(clk);
			
			for count in 0 to 50 loop
				if s_axis_tready = '1' then
					s_axis_tdata_int <= std_logic_vector(to_unsigned(count,8));
					s_axis_tvalid <= '1';
					wait until rising_edge(clk);
				else
					wait until rising_edge(clk);
				end if;
			end loop;
			
			while s_axis_tready = '0' loop
				wait until rising_edge(clk);
			end loop;
			
			s_axis_tvalid <= '0';
		
			for count in 50 to 60 loop
				wait until rising_edge(clk);
			end loop;
			
			s_axis_tdata_int <= x"ab";
			s_axis_tvalid <= '1';
			wait until rising_edge(clk);
			
			for count in 60 to 100 loop
				if s_axis_tready = '1' then
					s_axis_tdata_int <= std_logic_vector(to_unsigned(count,8));
					s_axis_tvalid <= '1';
					wait until rising_edge(clk);
				else
					wait until rising_edge(clk);
				end if;
			end loop;
			
			while s_axis_tready = '0' loop
				wait until rising_edge(clk);
			end loop;
			
			s_axis_tvalid <= '0';


	
	elsif TB = FTDI_FULL then
		
		TXEn_ftdi <= '0';
		s_axis_tdata_int <= x"ab";
		s_axis_tvalid <= '1';
		wait until rising_edge(clk);
		
		for count in 0 to 50 loop
		
			if count = 25 then
				TXEn_ftdi <= '1';
			elsif count = 40 then
				TXEn_ftdi <= '0';
			end if;
			
				if s_axis_tready = '1' then
					s_axis_tdata_int <= std_logic_vector(to_unsigned(count,8));
					s_axis_tvalid <= '1';
					wait until rising_edge(clk);
				else
					wait until rising_edge(clk);
				end if;
				
		end loop;
			
			while s_axis_tready = '0' loop
				wait until rising_edge(clk);
			end loop;
			
			s_axis_tvalid <= '0';
	
	
	
	
	elsif TB = FIFO_FULL then
	
		RXFn_ftdi <= '0';
		m_axis_tready <= '1';
		wait until rising_edge(clk);
		
		for count in 0 to 50 loop
		
			if count = 25 then
				m_axis_tready <= '0';
			elsif count = 40 then
				m_axis_tready <= '1';
			end if;
		
			if RDn_ftdi = '0' and OEn_ftdi = '0' then
				data_INOUT_ftdi <= std_logic_vector(to_unsigned(count,8));
			end if;
			
			wait until rising_edge(clk);
			
		end loop;
	
	
	
	elsif TB = FTDI_EMPTY then
		
		
		RXFn_ftdi <= '0';
		m_axis_tready <= '1';
		wait until rising_edge(clk);
		
		while RDn_ftdi = '1' or OEn_ftdi = '1' loop
			wait until rising_edge(clk);
		end loop;
		data_INOUT_ftdi <= x"ab";
		wait until rising_edge(clk);
		
		for count in 0 to 50 loop
		
		
			if RDn_ftdi = '0' and OEn_ftdi = '0' then
				data_INOUT_ftdi <= std_logic_vector(to_unsigned(count,8));
			end if;
			
			wait until rising_edge(clk);
			
		end loop;
		
		RXFn_ftdi <= '1';
		wait until rising_edge(clk);
		
		for count in 50 to 60 loop
		
			wait until rising_edge(clk);
			
		end loop;
		
		
		RXFn_ftdi <= '0';
		wait until rising_edge(clk);
		
		for count in 60 to 80 loop
		
		
			if RDn_ftdi = '0' and OEn_ftdi = '0' then
				data_INOUT_ftdi <= std_logic_vector(to_unsigned(count,8));
			end if;
			
			wait until rising_edge(clk);
			
		end loop;
		
		RXFn_ftdi <= '1';
	
	end if;
	
      wait;
    end process;
	----------------------------


end Behavioral;
