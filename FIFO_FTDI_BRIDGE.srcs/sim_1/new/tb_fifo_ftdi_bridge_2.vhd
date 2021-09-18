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

entity tb_fifo_ftdi_bridge_2 is
--  Port ( );
end tb_fifo_ftdi_bridge_2;

architecture Behavioral of tb_fifo_ftdi_bridge_2 is


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
	
	signal count : integer := 0;
	
	
	signal OEn_ftdi : STD_LOGIC;
	signal RDn_ftdi : STD_LOGIC;
	signal RXFn_ftdi : STD_LOGIC := '1';
	signal TXEn_ftdi : STD_LOGIC := '1';
	signal WRn_ftdi : STD_LOGIC;
	signal data_INOUT_ftdi : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
	signal m_axis_tdata : STD_LOGIC_VECTOR ( 7 downto 0 );
	signal m_axis_tready : STD_LOGIC := '0';
	signal m_axis_tvalid : STD_LOGIC;
	signal s_axis_tdata : STD_LOGIC_VECTOR ( 7 downto 0 ) := (others => '0');
	signal s_axis_tready : STD_LOGIC;
	signal s_axis_tvalid : STD_LOGIC := '0';
	
	
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
			m_axis_0_tdata => m_axis_tdata,
			m_axis_0_tready => m_axis_tready,
			m_axis_0_tvalid => m_axis_tvalid,
			s_axis_0_tdata => s_axis_tdata,
			s_axis_0_tready => s_axis_tready,
			s_axis_0_tvalid => s_axis_tvalid
			
		
		);


clk <= not clk after CLK_PERIOD/2;

	----- Reset Process --------
	reset_wave :process
	begin
		reset <= TB_RESET_INIT;
		wait for RESET_WND;
		
		reset <= not reset;
		wait;
    end process;	
	----------------------------
	 
	FT232H_proce: process
	begin
	
--	if rising_edge(clk) then
	
--		TXEn_ftdi <= '0';
		
--		count <= count + 1;
--		if count > 50 then
--			TXEn_ftdi <= '1';
--		end if;
		
--	end if;
	wait for 5*CLK_PERIOD;
	TXEn_ftdi <= '0';
	wait for 5*CLK_PERIOD;
	
	wait for 5*CLK_PERIOD;
	
	wait for CLK_PERIOD/2;
	TXEn_ftdi <= '1';
	wait for CLK_PERIOD/2;
	  
	wait for 10*CLK_PERIOD;
	TXEn_ftdi <= '0';
	wait for 5*CLK_PERIOD; --31
	TXEn_ftdi <= '1';
	
	
	RXFn_ftdi <= '0';
	wait for 9*CLK_PERIOD; --40
	
	m_axis_tready <= '1';
	wait for 5*CLK_PERIOD; --45
	
	m_axis_tready <= '0';
	wait for CLK_PERIOD; --46
	
	wait for 4*CLK_PERIOD; --50
	
	m_axis_tready <= '1';
	wait for 2*CLK_PERIOD; --52
	
	RXFn_ftdi <= '1';
	wait for 3*CLK_PERIOD;
	
	wait;
	end process;
	
	

	
	
	
	
	
   ------ Stimulus process -------
	
    stim_proc: process
    begin		
	
		
		-- waiting the reset wave
		
		wait for RESET_WND;	

			
		-- Start 
		
		-- TX  (simulo il funzionamento della FIFO: uso la s_axis: gestisco i dati e il valid)
		wait for 10*CLK_PERIOD;
		
		
		-- metto 3 dati, poi nulla per 2 clock (se ready = 1) e poi altri 3 dati
		-- il valid è 0 inizialmente, quindi posso mettere i dati.
		s_axis_tdata <= x"12";
		s_axis_tvalid <= '1';
		wait for CLK_PERIOD;
		
		while s_axis_tready = '0' loop
		
			wait for CLK_PERIOD;
			
		end loop;
		
		s_axis_tdata <= x"34";
		s_axis_tvalid <= '1';
		wait for CLK_PERIOD;
		
		while s_axis_tready = '0' loop
		
			wait for CLK_PERIOD;
			
		end loop;
		
		s_axis_tdata <= x"56";
		s_axis_tvalid <= '1';
		wait for CLK_PERIOD;
		
		while s_axis_tready = '0' loop
		
			wait for CLK_PERIOD;
			
		end loop;
		
		s_axis_tvalid <= '0';
		
		wait for 2*CLK_PERIOD; -- 15
		
		
		s_axis_tdata <= x"12";
		s_axis_tvalid <= '1';
		wait for CLK_PERIOD; --16
		
		while s_axis_tready = '0' loop
		
			wait for CLK_PERIOD;  --26
			
		end loop;
		
		s_axis_tdata <= x"34";
		s_axis_tvalid <= '1';
		wait for CLK_PERIOD; --27
		
		while s_axis_tready = '0' loop
		
			wait for CLK_PERIOD;
			
		end loop;
		
		s_axis_tdata <= x"56";
		s_axis_tvalid <= '1';
		wait for CLK_PERIOD; --28
		
		while s_axis_tready = '0' loop
		
			wait for CLK_PERIOD;
			
		end loop;
		
		s_axis_tvalid <= '0';
		
		wait for 3*CLK_PERIOD; --31
		
		-- RX
		data_INOUT_ftdi <= x"ab";
		wait for CLK_PERIOD; --32
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; --40
		end loop;
		
		data_INOUT_ftdi <= x"cd";
		wait for CLK_PERIOD; -- 41
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; 
		end loop;
		
		data_INOUT_ftdi <= x"ef";
		wait for CLK_PERIOD; -- 42
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; 
		end loop;
		
		data_INOUT_ftdi <= x"ab";
		wait for CLK_PERIOD; -- 43
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; 
		end loop;
		
		data_INOUT_ftdi <= x"cd";
		wait for CLK_PERIOD; -- 44
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; 
		end loop;
		
		data_INOUT_ftdi <= x"ef";
		wait for CLK_PERIOD; -- 45
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; 
		end loop;
		
		data_INOUT_ftdi <= x"ab";
		wait for CLK_PERIOD; -- 46
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD;  --50
		end loop;
		
		data_INOUT_ftdi <= x"12";
		wait for CLK_PERIOD; -- 51
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD;  
		end loop;
		
		data_INOUT_ftdi <= x"34";
		wait for CLK_PERIOD; -- 52
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD;  
		end loop;
		
		data_INOUT_ftdi <= x"56";
		wait for CLK_PERIOD; -- 53
		
		while OEn_ftdi = '1' or RDn_ftdi = '1' loop
			wait for CLK_PERIOD; --55 
		end loop;
		
		
		
	
        -- Stop
		wait;
		
		
		--------------------------

      wait;
    end process;
	----------------------------


end Behavioral;
