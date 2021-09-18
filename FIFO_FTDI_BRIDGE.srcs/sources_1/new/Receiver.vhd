library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- questo è il modulo di ricezione da FTDI a FPGA.
-- nel datasheet dell'FTDI (FT232H) i segnali da considerare sono quelli dell'RX (FTDI -> FPGA), e sono: RXFn, OEn, RDn
-- dall'FPGA voglio poi inviare i dati tramite AXI4 ad una FIFO.

-- implemento il protocollo AXI tramite una FSM

entity Receiver is
	Generic(
	   DATA_WIDTH : integer := 8
	);
	Port(
		reset : in std_logic;
		clk : in std_logic; -- il clock viene fornito dall'FTDI ed è a 60MHz
		
		-- segnali di interfaccia con l'FTDI
		RXFn_ftdi : in std_logic;
	    RDn_ftdi : out std_logic;
		
		-- segnali di interfaccia con il controller
		data_IN_ftdi : in std_logic_vector(DATA_WIDTH-1 downto 0);
		EN_RX : in std_logic; -- questo segnale mi serve per controllare la FSM : se RXFn = 1 allora OEn = 1 e WRn = 0 (parte transmitter abilitata)
		                   --                                                  se RXFn = 0 allora OEn = 0 e WRn = 1 (parte transmitter disabilitata) e EN = 1 (al prossimo clock metto RDn = 0, non posso metterlo subito, devo aspettare un clock da datasheet)
		full_fifo_rx : out std_logic;
		
		-- segnali AXI che vanno alla FIFO
		m_axis_tdata : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m_axis_tvalid : out std_logic;
		m_axis_tready : in std_logic
		
	);
end Receiver;

architecture Behavioral of Receiver is


	type state_type is (IDLE, ENABLE_RX, DUMMY, RECEIVE_DATA, WAIT_FIFO);
	signal state : state_type := IDLE;

	signal RDn_ftdi_int : std_logic := '1';
	signal full_fifo_rx_int : std_logic := '0';
	signal m_axis_tdata_int : std_logic_vector(DATA_WIDTH-1 downto 0):= (others => '0');
	signal m_axis_tvalid_int : std_logic := '0';

	signal dummy_sig : std_logic := '1';

begin

	full_fifo_rx <= full_fifo_rx_int;
	m_axis_tvalid <= m_axis_tvalid_int;
	RDn_ftdi <= RDn_ftdi_int;
	m_axis_tdata <= m_axis_tdata_int;

	with state select m_axis_tvalid_int <=
		'0' when IDLE,
		'0' when ENABLE_RX,
		'0' when DUMMY,     -- questo stato è praticamente uguale a RECEIVE_DATA, mi serve solo per non perdere dati. in pratica se sono entrato nello stato WAIT_FIFO allora non devo passare dallo stato DUMMY, se invece è l'inizio della trasmissione ci devo passare, se no campionerei anche i dati che sono sul bus di default ma non sono corretti, non sono quelli che mi ha inviato.
		'1' when RECEIVE_DATA,
		'1' when WAIT_FIFO; -- se la fifo è piena mi arriva m_ready = 0, quindi tengo m_valid = 1 e non aggiorno i dati
		
	with state select RDn_ftdi_int <=
		'1' when IDLE,
		'0' when ENABLE_RX,
		'0' when DUMMY,
		'0' when RECEIVE_DATA,
		'1' when WAIT_FIFO;  -- alzo RDn e quando leggo m_ready = 1 allora avrò anche OEn = 0 e quindi al clock vado nello stato ENABLE_RX (così abbasso RDn 1 ck dopo OEn).
							 -- notare che in questo clock sono stati campionati dalla fifo gli ultimi dati che avevo messo in output (validi ma non ancora campionati).
							 -- inoltre in questo clock metto m_valid = 0 (posso farlo perchè m_ready = 1) e lo faccio perchè ho bisogno di 1 clock di latenza prima di mandare avanti i dati successivi.




full_fifo_rx_int <= not m_axis_tready; -- se la fifo è piena segnalalo al controller (che metterà OEn = 1 e EN_RX lo terrà a 1)




process(clk)
begin

	if reset = '0' then
	
		m_axis_tdata_int <= (others => '0');
		state <= IDLE;
	
	
	elsif rising_edge(clk)then
	
		case state is


		when IDLE =>
			
			dummy_sig <= '1';
			
			if EN_RX = '1' then
				state <= ENABLE_RX;
			end if;
			
			
			
		when ENABLE_RX =>
		
			if RXFn_ftdi = '1' then
				state <= IDLE;
			
			else
				
				m_axis_tdata_int <= data_IN_ftdi; -- il m_valid era 0, quindi non devo controllare il m_ready
				
				if dummy_sig = '1' then
					state <= DUMMY;
				else
					state <= RECEIVE_DATA;
				end if;
				
			end if;
		
		
		
		when DUMMY =>
		
			if EN_RX = '0' and m_axis_tready = '1' then
				
				state <= IDLE;
					
			elsif m_axis_tready = '1' then
			
				m_axis_tdata_int <= data_IN_ftdi;
				state <= RECEIVE_DATA;
			
			elsif m_axis_tready = '0' then
			
				state <= WAIT_FIFO;
				-- qui l'ftdi potrebbe mandarmi il dato, perchè il rising edge del RDn_ftdi potrebbe non essere visto. in tal caso devo salvare il dato in un buffer e mandarlo dopo.
			end if;
		
		
		
		
		when RECEIVE_DATA =>
		
			if EN_RX = '0' and m_axis_tready = '1' then
				
				state <= IDLE;
					
			elsif m_axis_tready = '1' then
			
				m_axis_tdata_int <= data_IN_ftdi;
			
			elsif m_axis_tready = '0' then
			
				state <= WAIT_FIFO;
				-- qui l'ftdi potrebbe mandarmi il dato, perchè il rising edge del RDn_ftdi potrebbe non essere visto. in tal caso devo salvare il dato in un buffer e mandarlo dopo.
			end if;
		
		
		
		when WAIT_FIFO =>
			
			if EN_RX = '0' and m_axis_tready = '1' then
				
				state <= IDLE;
	
			elsif m_axis_tready = '1' then
			
				state <= ENABLE_RX;
				dummy_sig <= '0';
			
			end if;

		end case;
	
		
	
	end if;

end process;


end Behavioral;