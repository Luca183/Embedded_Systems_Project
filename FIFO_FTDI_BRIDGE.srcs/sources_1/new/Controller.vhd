library IEEE;
Library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use UNISIM.vcomponents.all;

   

  
   



entity Controller is
    Generic(
	   DATA_WIDTH : integer := 8
	);
	Port(
		reset : in std_logic;
		clk : in std_logic;
		
		
		-- interfaccia con FTDI
		RXFn_ftdi : in std_logic;
		TXEn_ftdi : in std_logic;
		OEn_ftdi : out std_logic;
		data_INOUT_ftdi : inout std_logic_vector(DATA_WIDTH-1 downto 0);
		
		-- interfaccia TX, RX
		EN_RX : out std_logic;
		EN_TX : out std_logic;
		full_fifo_rx : in std_logic; -- se la fifo dell'fpga è piena metto OEn = 1 (stoppo la ricezione)
		data_IN_ftdi : out std_logic_vector(DATA_WIDTH-1 downto 0); -- da FTDI a questo blocco al RX (out)
		data_OUT_ftdi : in std_logic_vector(DATA_WIDTH-1 downto 0)  -- da TX a questo blocco (in) a ftdi
		
		
	);
end Controller;



-------------------------------------------------------------------
-- ALGORITMO:
-- leggo i segnali RXFn e TXEn 
-- se TXEn = RXFn = 1 nè TX nè Rx funzionano. metto quindi WRn = 1, OEn = 1, EN_RX = 0, EN_TX = 0 (non voglio nè trasmettere e nè ricevere)
-- RICEZIONE: parto da OEn = 1, EN_RX = 0 (RDn = 1), WRn = 0 o 1
-- quando RXFn = 0 metto OEn = 0 e WRn = 1 e EN_RX = 1 e EN_TX = 0(tutto senza clock)
-- se l'FTDI non vuole più mandare dati e io ho la FIFO ancora non piena allora avrò di default OEn = 0, RDn = 0 (EN_RX = 1), però il segnale RXFn va a 1 e allora io porto OEn = 1, EN_RX = 0
-- se l'FTDI ha ancora dati da mandare ma io ho riempito la FIFO: nel blocco RX metto RDn = 1 (vedo se implementare un segnale "full_fifo" che va al controller...). poi quando la fifo si svuota RDn torna a 0 e continua a leggere (in tutto questo potrei tenere EN_RX = 1 e OEn = 0)
-- TRASMISSIONE: parto da OEn = 1 (ok), EN_TX = 0, RDn = 0 o 1
-- quando TXEn = 0 tengo OEn = 1, EN_TX = 1 (EN_RX = 0), WRn = 0. (RDn andrà a 0 nella RX)
-- se l'FTDI non accetta altri dati (full fifo) allora porterà TXEn = 1. se ho altri dati da mandare non è un problema perchè blocco il flusso di dati. posso mettere EN_TX = 0 e bloccare la stream direttamente nel TX (s_ready = 0)
-- se l'FTDI non è piena (TXEn = 0) ma io ho finito i dati da inviare: questa cosa viene gestita dal trasmitter che mette WRn = '1' e stoppa la trasmissione




architecture Behavioral of Controller is


signal tristate_int : std_logic := '1';
signal EN_RX_int : std_logic := '0';
signal EN_TX_int : std_logic := '0';
signal OEn_ftdi_int : std_logic := '1';
signal data_IN_ftdi_int : std_logic_vector(DATA_WIDTH-1 downto 0);


begin


-- metto un IOBUF per ogni linea del bus "data_INOUT_ftdi"
IOBUF_BUS:
   for j in 0 to DATA_WIDTH-1 generate
      begin
      
	   IOBUF_inst : IOBUF
	   generic map (
		  DRIVE => 12,
		  IOSTANDARD => "DEFAULT", -- LVCMOS33 if needed
		  SLEW => "SLOW")
	   port map (
		  O => data_IN_ftdi_int(j),     -- Buffer output
		  IO => data_INOUT_ftdi(j),   -- Buffer inout port (connect directly to top-level port)  -- forse va inserito un buffer (?)
		  I => data_OUT_ftdi(j),     -- Buffer input
		  T => tristate_int      -- 3-state enable input, high=input, low=output 
	   );
	   
   end generate;



EN_RX <= EN_RX_int;
EN_TX <= EN_TX_int;
OEn_ftdi <= OEn_ftdi_int;
data_IN_ftdi <= data_IN_ftdi_int;


------ abilitazione blocco TX se e solo se TXEn = 0		 
EN_TX_int <= '1' when TXEn_ftdi = '0' and RXFn_ftdi = '1' and reset = '1' else
		     '0';


------ abilitazione blocco RX se e solo se RXFn = 0
EN_RX_int <= '1' when RXFn_ftdi = '0' and TXEn_ftdi = '1' and full_fifo_rx = '0' and reset = '1' else 
		     '0'; -- se RXFn = 1 ovviamente EN_RX = 0, ma anche se sie RXFn e TXEn sono 0 metto EN_RX = 0, perchè probabilmente è un errore (posso solo o trasmettere o ricevere).



------ bus abilitato per ricevere dati se e solo se RXFn = 0
OEn_ftdi_int <= '0' when RXFn_ftdi = '0' and TXEn_ftdi = '1' and full_fifo_rx = '0' and reset = '1' else -- RX
			    '1'; -- TX


------ segnale tristate per mettere il buffer in configurazione I/O: notare che è praticamente il segnale OEn che decide questa cosa. 
tristate_int <= '1' when ((RXFn_ftdi = '0' and TXEn_ftdi = '1') or (RXFn_ftdi = '1' and TXEn_ftdi = '1')) or reset = '0' else-- default  -- RX (IBUF)
			    '0' when RXFn_ftdi = '1' and TXEn_ftdi = '0' ; --TX (OBUF)



end Behavioral;
