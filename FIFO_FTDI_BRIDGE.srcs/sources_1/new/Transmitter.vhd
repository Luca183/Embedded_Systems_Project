library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

-- questo è il modulo di trasmissione da FPGA a FTDI.
-- nel datasheet dell'FTDI (FT232H) i segnali da considerare sono quelli del TX (FPGA -> FTDI), e sono: TXEn, WRn
-- dall'FPGA voglio ricevere i dati (da inviare all'FTDI) tramite AXI4 da una FIFO.

-- implemento il protocollo AXI tramite una FSM

entity Transmitter is
	Generic(
	   DATA_WIDTH : integer := 8
	);
	Port(
		reset : in std_logic;
		clk : in std_logic;
		
		-- segnali AXI che arrivano dalla FIFO
		s_axis_tdata : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s_axis_tvalid : in std_logic;
		s_axis_tready : out std_logic;
		
		--interfaccia con controller
		EN_TX : in std_logic; -- la parte transmitter funziona quando EN_TX = 1 
		data_OUT_ftdi : out std_logic_vector(DATA_WIDTH-1 downto 0);
		
		
		-- interfaccia con FTDI
		TXEn_ftdi : in std_logic;
		WRn_ftdi : out std_logic:='1'
		
	);
end Transmitter;

architecture Behavioral of Transmitter is


	type state_type is (IDLE, SEND_DATA, WAIT_FIFO);
	signal state : state_type := IDLE;
	
	signal WRn_ftdi_int : std_logic := '1';
	signal s_axis_tready_int : std_logic := '0';
	signal data_OUT_ftdi_int : std_logic_vector(DATA_WIDTH-1 downto 0):= (others => '0');

	signal s_axis_tvalid_prec : std_logic := '0';
	signal EN_TX_prec : std_logic := '0';

begin



 data_OUT_ftdi <= data_OUT_ftdi_int;

 WRn_ftdi <= WRn_ftdi_int; 
 s_axis_tready <= s_axis_tready_int;



	--  con queste condizioni sto facendo questo:
	-- se TXEn = 1 (EN_TX = 0) allora lascia s_ready = 0 e WRn = 1 (tutto fermo).
	-- se TXEn = 0 ma non ho segnali validi in ingresso (s_valid = 0), allora non posso fare nulla, non voglio mettere WRn a 0 per inviare dati.. allora lascio WRn = 1 e s_axis_tready = 0.
	-- se TXEn = 0 e s_valid = 1 (segnali validi in input), allora metto immediatamente WRn = 0 e s_ready = 1.
	-- al clock entro nell'if dello stato di IDLE: mando i dati all'ftdi e mi vengono aggiornati i dati in input.
	-- se TXEn va a 1 (EN_TX = 0) allora torno in IDLE (cioè metto subito s_ready = 0 e WRn = 1). se ho dei dati validi in ingresso non li perdo perchè ho messo s_ready = 0, quindi la fifo non può aggiornare i dati.
	-- se invece TXEn rimane a 0 (EN_TX = 1) ma la vivo non ha dati da inviare o comunque non sono validi (s_valid = 0), allora metto subito WRn = 1 così blocco la trasmissione all'ftdi, e metto anche s_ready = 0. (è importante mettere il ready a 0, se no poi ai prossimi dati validi che mi arrivano dovrei perdere il primo dato)
	-- in questa situazione comunque vorremmo trasmettere dati (l'ftdi li "richiede"), però non ne abbiamo.. allora entriamo nello stato di WAIT_FIFO.
	-- in questo stato se la fifo mi mette dei dati validi io metto subito WRn = 0 e s_ready = 1. al clock successivo quindi mi vengono aggiornati i dati in input e invio i dati che sono stati al clock precedente.
	-- in ogni caso se TXEn va a 1 devo stoppare la trasmissione e torno a IDLE. se ci sono dei dati validi in input, non li perdo (perchè metto s_ready = 0).
	
	
		
s_axis_tready_int <= not TXEn_ftdi and s_axis_tvalid and reset; -- and not WRn_ftdi_int

WRn_ftdi_int <= TXEn_ftdi or (not s_axis_tvalid and not EN_TX_prec) or not s_axis_tvalid_prec;

-- possono sembrare logiche complesse, però mi permettono di non perdere nessun dato in nessun caso: FIFO empty, FTDI full
-- per farle ho dovuto aggiungere i segnali "buffer" s_axis_tvalid_prec e EN_TX_prec che tengono in memoria quello che è successo al clock precedente, così capisco quale transizione sta avvenendo e quindi capisco se la fifo è vuota o se l'ftdi è piena

-- se è necessario che ci sia un tot di delay tra il falling edge del TXEn e del WRn, allora aggiungere un ODELAY. non posso far variare WRn al clock successivo, se no in qualche condizione perdo un dato.

process(clk)
begin

	if reset = '0' then
	
		data_OUT_ftdi_int <= (others => '0');
		state <= IDLE;
		s_axis_tvalid_prec <= '0';
		EN_TX_prec <= '0';
	
	
	elsif rising_edge(clk)then
		
		
		s_axis_tvalid_prec <= s_axis_tvalid;
		EN_TX_prec <= EN_TX;

		case state is


		when IDLE => 
		
			if EN_TX = '1' and s_axis_tvalid = '1' then
	
				state <= SEND_DATA;
				data_OUT_ftdi_int <= s_axis_tdata;

			end if;
			
			
		
		
		when SEND_DATA =>
		
			if EN_TX = '0' then
			
				state <= IDLE;
				
			elsif EN_TX = '1' and s_axis_tvalid = '1' then
			
				data_OUT_ftdi_int <= s_axis_tdata;

			elsif EN_TX = '1' and s_axis_tvalid = '0' then
			
				state <= WAIT_FIFO;
				
			end if;
		
			
		
		
		when WAIT_FIFO =>
		
			if EN_TX = '0' then
				
				state <= IDLE;
			
			elsif s_axis_tvalid = '1' then	
				
				state <= SEND_DATA;
				data_OUT_ftdi_int <= s_axis_tdata;
				
			end if;
			
			
		
		end case;
	
		
	
	end if;

end process;


end Behavioral;