

`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.12.2020 19:06:21
// Design Name: 
// Module Name: tb_memory_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_memory_test();


/******************* CONSTANTS *************************/


parameter HALF_CLK_PERIOD = 5; //  @ 100MHz
parameter VMEM_FILE_1 = "file_1.mem";
parameter VMEM_FILE_2 = "file.mem"; //"C:/EMBEDDED_SYSTEM/Project/lab4_ADC_LDR.dat";


/******************** SIGNALS ***************************/

logic clk;
logic rst = 1'b1;


logic [7:0] R_select_memory_c;  //used to store the 2 MSBs of the address in order to select the memory that I have to use
logic [7:0] W_select_memory_c;
logic [7:0] R_select_memory_s;
logic [7:0] W_select_memory_s;

logic [31:0] AW_addr_c;  //register buffer for the AW address
logic [31:0] W_data_c;   //register buffer for the W data
logic b_sent_c = 1'b0;
logic [31:0] AW_addr_s; 
logic [31:0] W_data_s;   
logic b_sent_s = 1'b0;

logic [31:0] AR_addr_c;
logic R_sent_c = 1'b0;
logic [31:0] AR_addr_s;
logic R_sent_s = 1'b0;

// MEMORY DESCRIPTION: DATA FROM "STM32F107RB" MICROCONTROLLER'S DATASHEET

/*

FLASH_1: 				 0X0000 0000 - 0X0003 FFFF  : 18 bit

FLASH_2: 				 0X0800 0000 - 0X0803 FFFF  : 18 bit

SYS MEM & OPTION BYTES : 0X1FFF B000 - 0X1FFF FFFF  : 15 bit

RAM: 					 0X2000 0000 - 0X2000 FFFF  : 16 BIT

PERIPHERALS: 			 0X4000 0000 - 0X4002 9FFF  : 18 BIT 

M3-REGISTERS: 			 0XE000 0000 - 0XE00F FFFF  : 20 BIT

*/

//logic [7:0] memTb_low [32'h00000000 : 32'h000FFFFF]; // memory lines have 8-bit width

logic [7:0] flash_1      [18'h00000 : 18'h3FFFF]; // if 2 MSBs = 00
logic [7:0] flash_2      [18'h00000 : 18'h3FFFF]; // if 2 MSBs = 08
logic [7:0] sys_mem      [15'hB000  : 15'hFFFF];  // if 2 MSBs = 1F
logic [7:0] ram 		 [17'h00000 : 17'h10002];  // if 2 MSBs = 20
logic [7:0] peripherals  [18'h00000 : 18'h29FFF]; // if 2 MSBs = 40
logic [7:0] m3_registers [20'h00000 : 20'hFFFFF]; // if 2 MSBs = E0





//AXI SIGNALS

//CODE

//AR: Address Read BUS -> memory = slave
logic [31:0] AR_s_axis_tdata_c;
logic AR_s_axis_tvalid_c;
logic AR_s_axis_tready_c = 1'b1;
logic [2:0] AR_s_axis_tprot_c;

//R: Read BUS -> memory = master
logic [31:0] R_m_axis_tdata_c;
logic R_m_axis_tvalid_c = 1'b0;
logic R_m_axis_tready_c;
logic [1:0] R_m_axis_tresp_c = 2'b00;



//AW: Address Write BUS -> memory = slave
logic [31:0] AW_s_axis_tdata_c;  
logic AW_s_axis_tvalid_c;
logic AW_s_axis_tready_c = 1'b0;
logic [2:0] AW_s_axis_tprot_c;

//W: Write BUS -> memory = slave
logic [31:0] W_s_axis_tdata_c;  
logic W_s_axis_tvalid_c;
logic W_s_axis_tready_c = 1'b0;
logic [3:0] W_s_axis_tstrb_c;

//B: Back BUS -> memory = master 
logic B_m_axis_tvalid_c = 1'b1;
logic B_m_axis_tready_c;
logic [1:0] B_m_axis_tresp_c = 2'b00;



//SYSTEM

//AR: Address Read BUS -> memory = slave
logic [31:0] AR_s_axis_tdata_s;
logic AR_s_axis_tvalid_s;
logic AR_s_axis_tready_s = 1'b1;
logic [2:0] AR_s_axis_tprot_s;

//R: Read BUS -> memory = master
logic [31:0] R_m_axis_tdata_s;
logic R_m_axis_tvalid_s = 1'b0;
logic R_m_axis_tready_s;
logic [1:0] R_m_axis_tresp_s = 2'b00;



//AW: Address Write BUS -> memory = slave
logic [31:0] AW_s_axis_tdata_s;  
logic AW_s_axis_tvalid_s;
logic AW_s_axis_tready_s = 1'b0;
logic [2:0] AW_s_axis_tprot_s;

//W: Write BUS -> memory = slave
logic [31:0] W_s_axis_tdata_s;  
logic W_s_axis_tvalid_s;
logic W_s_axis_tready_s = 1'b0;
logic [3:0] W_s_axis_tstrb_s;

//B: Back BUS -> memory = master 
logic B_m_axis_tvalid_s = 1'b1;
logic B_m_axis_tready_s;
logic [1:0] B_m_axis_tresp_s = 2'b00;



//clock
always #HALF_CLK_PERIOD clk =~ clk;


/******************** MEMORY INIT ***************************/

initial
begin
    
	clk <= 0;
	rst = 0;
	
	
	$readmemh(VMEM_FILE_1, flash_1);
	$readmemh(VMEM_FILE_2, flash_2); // copies hex values from hex text file to memory array
	
	
	
	//GPIOA_CRL reset value
	peripherals[18'h10800] = 8'h44;
	peripherals[18'h10801] = 8'h44;
	peripherals[18'h10802] = 8'h44;
	peripherals[18'h10803] = 8'h44;
	
	//AFIO_CRH reset value
	peripherals[18'h10004] = 8'h44;
	peripherals[18'h10005] = 8'h44;
	peripherals[18'h10006] = 8'h44;
	peripherals[18'h10007] = 8'h44;
	
	//RCC_CFGR reset value
	peripherals[18'h21004] = 8'h00;
	peripherals[18'h21005] = 8'h00;
	peripherals[18'h21006] = 8'h00;
	peripherals[18'h21007] = 8'h00;
	
	
	//RCC_APB1ENR reset value
	peripherals[18'h2101C] = 8'h00;
	peripherals[18'h2101D] = 8'h00;
	peripherals[18'h2101E] = 8'h00;
	peripherals[18'h2101F] = 8'h00;
	
	//RCC_APB2ENR reset value
	peripherals[18'h21018] = 8'h00;
	peripherals[18'h21019] = 8'h00;
	peripherals[18'h2101A] = 8'h00;
	peripherals[18'h2101B] = 8'h00;
	
	
	//FLASH MEMORY INTERFACE reset value
	peripherals[18'h22000] = 8'h00;
	peripherals[18'h22001] = 8'h00;
	peripherals[18'h22002] = 8'h00;
	peripherals[18'h22003] = 8'h00;
	
	//RCC_CR reset value
	peripherals[18'h21000] = 8'b10000011;
	peripherals[18'h21001] = 8'h00;
	peripherals[18'h21002] = 8'h00;
	peripherals[18'h21003] = 8'h00;
	
	repeat(100) @(posedge clk);
	

	
	rst <= 1;
	
	
	repeat(10) @(posedge clk);
	
	
end


/********************* CONNECTIONS *******************/

design_1_wrapper 
memory_test(

	.sys_clock(clk),
	.CLK_CODE_AXI(clk),
	.CLK_SYS_AXI(clk),
	.reset(rst),
	
	
	//READ CODE
	.CM3_CODE_AXI3_0_arprot(AR_s_axis_tprot_c),
	.CM3_CODE_AXI3_0_araddr(AR_s_axis_tdata_c),
	.CM3_CODE_AXI3_0_arready(AR_s_axis_tready_c),
	.CM3_CODE_AXI3_0_arvalid(AR_s_axis_tvalid_c),
	
	.CM3_CODE_AXI3_0_rresp(R_m_axis_tresp_c),
	.CM3_CODE_AXI3_0_rvalid(R_m_axis_tvalid_c),
	.CM3_CODE_AXI3_0_rready(R_m_axis_tready_c),
	.CM3_CODE_AXI3_0_rdata(R_m_axis_tdata_c),
	
	//WRITE CODE
	.CM3_CODE_AXI3_0_awready(AW_s_axis_tready_c),
	.CM3_CODE_AXI3_0_awprot(AW_s_axis_tprot_c),
	.CM3_CODE_AXI3_0_awvalid(AW_s_axis_tvalid_c),
	.CM3_CODE_AXI3_0_awaddr(AW_s_axis_tdata_c),
	
	.CM3_CODE_AXI3_0_wready(W_s_axis_tready_c),
	.CM3_CODE_AXI3_0_wstrb(W_s_axis_tstrb_c),
	.CM3_CODE_AXI3_0_wvalid(W_s_axis_tvalid_c),
	.CM3_CODE_AXI3_0_wdata(W_s_axis_tdata_c),
	
	.CM3_CODE_AXI3_0_bready(B_m_axis_tready_c),
	.CM3_CODE_AXI3_0_bresp(B_m_axis_tresp_c),
	.CM3_CODE_AXI3_0_bvalid(B_m_axis_tvalid_c),
	
	
	
	//READ SYSTEM
	.CM3_SYS_AXI3_0_arprot(AR_s_axis_tprot_s),
	.CM3_SYS_AXI3_0_araddr(AR_s_axis_tdata_s),
	.CM3_SYS_AXI3_0_arready(AR_s_axis_tready_s),
	.CM3_SYS_AXI3_0_arvalid(AR_s_axis_tvalid_s),
	
	.CM3_SYS_AXI3_0_rresp(R_m_axis_tresp_s),
	.CM3_SYS_AXI3_0_rvalid(R_m_axis_tvalid_s),
	.CM3_SYS_AXI3_0_rready(R_m_axis_tready_s),
	.CM3_SYS_AXI3_0_rdata(R_m_axis_tdata_s),
	
	//WRITE SYSTEM
	.CM3_SYS_AXI3_0_awready(AW_s_axis_tready_s),
	.CM3_SYS_AXI3_0_awprot(AW_s_axis_tprot_s),
	.CM3_SYS_AXI3_0_awvalid(AW_s_axis_tvalid_s),
	.CM3_SYS_AXI3_0_awaddr(AW_s_axis_tdata_s),

	.CM3_SYS_AXI3_0_wready(W_s_axis_tready_s),
	.CM3_SYS_AXI3_0_wstrb(W_s_axis_tstrb_s),
	.CM3_SYS_AXI3_0_wvalid(W_s_axis_tvalid_s),
	.CM3_SYS_AXI3_0_wdata(W_s_axis_tdata_s),

	.CM3_SYS_AXI3_0_bready(B_m_axis_tready_s),
	.CM3_SYS_AXI3_0_bresp(B_m_axis_tresp_s),
	.CM3_SYS_AXI3_0_bvalid(B_m_axis_tvalid_s)
	
);




/******************* IMPLEMENTATION ******************/


// AXI connection management


//READ CODE PART

//FSM read part

enum logic {R_WAIT_ADDR_C = 1'b0,
			R_SEND_DATA_C = 1'b1} state_read_c = R_WAIT_ADDR_C;

always@(posedge clk)
begin

if(rst == 1'b1)
begin

	case(state_read_c)
	
		(R_WAIT_ADDR_C): begin
			if (AR_s_axis_tvalid_c == 1'b1)
			begin
				AR_s_axis_tready_c <= 1'b1;
				AR_addr_c <= AR_s_axis_tdata_c;
				state_read_c <= R_SEND_DATA_C;
			end
		end
		
		(R_SEND_DATA_C):begin
			if( R_sent_c == 1'b1 && R_m_axis_tready_c == 1'b1)
			begin
				R_m_axis_tvalid_c <= 1'b0;
				R_sent_c <= 1'b0;
				state_read_c <= R_WAIT_ADDR_C;
			end
			
			else
			begin
                AR_s_axis_tready_c <= 1'b0;
                R_m_axis_tdata_c <= send_data_func(R_select_memory_c);
                R_m_axis_tresp_c <= send_R_resp(R_select_memory_c);
                R_m_axis_tvalid_c <= 1'b1;
                R_sent_c <= 1'b1;
			end
		end
	endcase		
end
end




//READ SYS PART

//FSM read part

enum logic {R_WAIT_ADDR_S = 1'b0,
			R_SEND_DATA_S = 1'b1} state_read_s = R_WAIT_ADDR_S;

always@(posedge clk)
begin

if(rst == 1'b1)
begin

	case(state_read_s)
	
		(R_WAIT_ADDR_S): begin
			if (AR_s_axis_tvalid_s == 1'b1)
			begin
				AR_s_axis_tready_s <= 1'b1;
				AR_addr_s <= AR_s_axis_tdata_s;
				state_read_s <= R_SEND_DATA_S;
			end
		end
		
		(R_SEND_DATA_S):begin
			if( R_sent_s == 1'b1 && R_m_axis_tready_s == 1'b1)
			begin
				R_m_axis_tvalid_s <= 1'b0;
				R_sent_s <= 1'b0;
				state_read_s <= R_WAIT_ADDR_S;
			end
			
			else
			begin
                AR_s_axis_tready_s <= 1'b0;
                R_m_axis_tdata_s <= send_data_func(R_select_memory_s);
                R_m_axis_tresp_s <= send_R_resp(R_select_memory_s);
                R_m_axis_tvalid_s <= 1'b1;
                R_sent_s <= 1'b1;
			end
		end
	endcase		
end
end





//WRITE CODE PART


enum logic {W_WAIT_ADDR_C = 1'b0,
			W_CHECK_C = 1'b1} state_write_c = W_WAIT_ADDR_C;
			
			

always@(posedge clk)
begin

if(rst == 1'b1)
begin
	
	case(state_write_c)
	
		W_WAIT_ADDR_C: begin
			if (AW_s_axis_tvalid_c == 1'b1 && W_s_axis_tvalid_c == 1'b1)
			begin
				W_s_axis_tready_c <= 1'b1;
				AW_s_axis_tready_c <= 1'b1;
				AW_addr_c <= AW_s_axis_tdata_c;
				W_data_c <= W_s_axis_tdata_c;
				state_write_c <= W_CHECK_C;
			end
		end		
		
		W_CHECK_C: begin
			W_s_axis_tready_c <= 1'b0;
			AW_s_axis_tready_c <= 1'b0;
			B_m_axis_tvalid_c <= 1'b1;
			
			if (b_sent_c == 1'b0)
			begin
				b_sent_c <= 1'b1;
				if (write_memory(W_select_memory_c))   //maybe I have to pass all the memories by reference, and also the W_data/AW_addr registers
					B_m_axis_tresp_c <= 2'b00;  //correct
				else
					B_m_axis_tresp_c <= 2'b10;  //not correct
				
			end
			
			else if (b_sent_c == 1'b1  && B_m_axis_tready_c == 1'b1)
			begin
				B_m_axis_tvalid_c <= 1'b0;
				state_write_c <= W_WAIT_ADDR_C;
				b_sent_c <= 1'b0;
			end
		end
	endcase
end

end


//WRITE SYS PART


enum logic {W_WAIT_ADDR_S = 1'b0,
			W_CHECK_S = 1'b1} state_write_s = W_WAIT_ADDR_S;
			
			

always@(posedge clk)
begin

if(rst == 1'b1)
begin
	
	case(state_write_s)
	
		W_WAIT_ADDR_S: begin
			if (AW_s_axis_tvalid_s == 1'b1 && W_s_axis_tvalid_s == 1'b1)
			begin
				W_s_axis_tready_s <= 1'b1;
				AW_s_axis_tready_s <= 1'b1;
				AW_addr_s <= AW_s_axis_tdata_s;
				W_data_s <= W_s_axis_tdata_s;
				state_write_s <= W_CHECK_S;
			end
		end		
		
		W_CHECK_S: begin
			W_s_axis_tready_s <= 1'b0;
			AW_s_axis_tready_s <= 1'b0;
			B_m_axis_tvalid_s <= 1'b1;
			
			if (b_sent_s == 1'b0)
			begin
				b_sent_s <= 1'b1;
				if (write_memory(W_select_memory_s))   //maybe I have to pass all the memories by reference, and also the W_data/AW_addr registers
					B_m_axis_tresp_s <= 2'b00;  //correct
				else
					B_m_axis_tresp_s <= 2'b10;  //not correct
				
			end
			
			else if (b_sent_s == 1'b1  && B_m_axis_tready_s == 1'b1)
			begin
				B_m_axis_tvalid_s <= 1'b0;
				state_write_s <= W_WAIT_ADDR_S;
				b_sent_s <= 1'b0;
			end
		end
	endcase
end

end



//always block used to set some signals
always@(*)
begin

if(rst == 1'b1)
begin

	R_select_memory_c = AR_s_axis_tdata_c[31:24];  //2 MSBs nibbles : allow me to select the memory that I have to use
	W_select_memory_c = AW_s_axis_tdata_c[31:24];
	
	R_select_memory_s = AR_s_axis_tdata_s[31:24];  //2 MSBs nibbles : allow me to select the memory that I have to use
	W_select_memory_s = AW_s_axis_tdata_s[31:24];
	
end

end





//Function that takes the 32bit data from the correct memory
function logic [31:0] send_data_func(input logic [7:0] select_memory);

	case(select_memory)
		
		8'h00 : return {flash_1[int'(AR_s_axis_tdata_c[18:0] + 3)], flash_1[int'(AR_s_axis_tdata_c[18:0]) + 2], flash_1[int'(AR_s_axis_tdata_c[18:0]) + 1], flash_1[int'(AR_s_axis_tdata_c[18:0])]};  //each address has 8 bit, so take data from 4 addresses
		
		8'h08 : return {flash_2[int'(AR_s_axis_tdata_c[18:0] + 3)], flash_2[int'(AR_s_axis_tdata_c[18:0]) + 2], flash_2[int'(AR_s_axis_tdata_c[18:0]) + 1], flash_2[int'(AR_s_axis_tdata_c[18:0])]};  //each address has 8 bit, so take data from 4 addresses
		
		8'h1F : return {sys_mem[int'(AR_s_axis_tdata_c[15:0] + 3)], sys_mem[int'(AR_s_axis_tdata_c[15:0]) + 2], sys_mem[int'(AR_s_axis_tdata_c[15:0]) + 1], sys_mem[int'(AR_s_axis_tdata_c[15:0])]};  //each address has 8 bit, so take data from 4 addresses
		
		8'h20 : return {ram[int'(AR_s_axis_tdata_s[17:0] + 3)], ram[int'(AR_s_axis_tdata_s[17:0]) + 2], ram[int'(AR_s_axis_tdata_s[17:0]) + 1], ram[int'(AR_s_axis_tdata_s[17:0])]};  //each address has 8 bit, so take data from 4 addresses
		
		8'h40 : return {peripherals[int'(AR_s_axis_tdata_s[18:0] + 3)], peripherals[int'(AR_s_axis_tdata_s[18:0]) + 2], peripherals[int'(AR_s_axis_tdata_s[18:0]) + 1], peripherals[int'(AR_s_axis_tdata_s[18:0])]};  //each address has 8 bit, so take data from 4 addresses
		
		8'hE0 : return {m3_registers[int'(AR_s_axis_tdata_s[20:0] + 3)], m3_registers[int'(AR_s_axis_tdata_s[20:0]) + 2], m3_registers[int'(AR_s_axis_tdata_s[20:0]) + 1], m3_registers[int'(AR_s_axis_tdata_s[20:0])]};  //each address has 8 bit, so take data from 4 addresses
		
		default: begin
		         end
	endcase
		

endfunction



//Function that produces the resp signal (check if the address requested is correct)
function logic [1:0] send_R_resp(input logic [7:0] select_memory);

	case(select_memory)
		//cambio AR_s_axis_tdata con un address buffer (addr) se uso la FSM
		
		8'h00 : begin  //Flash_1
					if(AR_s_axis_tdata_c >= 32'h00000000 && AR_s_axis_tdata_c <= 32'h0003FFFF)  //check if the address is in the correct range
						return 2'b00;  //correct
					else
						return 2'b10; //read error: not valid address
				end
				
		8'h08 : begin //Flash_2
					if(AR_s_axis_tdata_c >= 32'h08000000 && AR_s_axis_tdata_c <= 32'h0803FFFF)
						return 2'b00;
					else
						return 2'b10;
				end
				
		8'h1F : begin //sys_mem
					if(AR_s_axis_tdata_c >= 32'h1FFFB000 && AR_s_axis_tdata_c <= 32'h1FFFFFFF)
						return 2'b00;
					else
						return 2'b10;
				end
				
		8'h20 : begin  //ram
					if(AR_s_axis_tdata_s >= 32'h20000000 && AR_s_axis_tdata_s <= 32'h20010002)
						return 2'b00;
					else
						return 2'b10;
				end
				
		8'h40 : begin  //peripherals
					if(AR_s_axis_tdata_s >= 32'h40000000 && AR_s_axis_tdata_s <= 32'h40029FFF)
						return 2'b00;
					else
						return 2'b10;
				end
				
		8'hE0 : begin  //m3_registers
					if(AR_s_axis_tdata_s >= 32'hE0000000 && AR_s_axis_tdata_s <= 32'hE00FFFFF)
						return 2'b00;
					else
						return 2'b10;
				end
				
		default: begin
		         end
	endcase
		

endfunction










// function used to write directly to the correct memory (if the address is correct)
function logic write_memory (input logic [7:0] select_memory);
	case(select_memory)
		
		8'h00 : begin  //Flash_1
					if(AW_addr_c >= 32'h00000000 && AW_addr_c <= 32'h0003FFFF)  //check if the address is in the correct range
					begin
						flash_1[int'(AW_addr_c[18:0])] <= W_data_c[7:0];
						flash_1[int'(AW_addr_c[18:0])+1] <= W_data_c[15:8];
						flash_1[int'(AW_addr_c[18:0])+2] <= W_data_c[23:16];
						flash_1[int'(AW_addr_c[18:0])+3]   <= W_data_c[31:24];    
						return 1;
					end
					else
						return 0;
				end
				
		8'h08 : begin //Flash_2
					if(AW_addr_c >= 32'h08000000 && AW_addr_c <= 32'h0803FFFF)
					begin
						flash_2[int'(AW_addr_c[18:0])] <= W_data_c[7:0];
						flash_2[int'(AW_addr_c[18:0])+1] <= W_data_c[15:8];
						flash_2[int'(AW_addr_c[18:0])+2] <= W_data_c[23:16];
						flash_2[int'(AW_addr_c[18:0])+3]   <= W_data_c[31:24];
						return 1;
					end
					else
						return 0;
				end
				
		8'h1F : begin //sys_mem
					if(AW_addr_c >= 32'h1FFFB000 && AW_addr_c <= 32'h1FFFFFFF)
					begin
						sys_mem[int'(AW_addr_c[15:0])] <= W_data_c[7:0];
						sys_mem[int'(AW_addr_c[15:0])+1] <= W_data_c[15:8];
						sys_mem[int'(AW_addr_c[15:0])+2] <= W_data_c[23:16];
						sys_mem[int'(AW_addr_c[15:0])+3]   <= W_data_c[31:24];
						return 1;
					end
					else
						return 0;
				end
				
		8'h20 : begin  //ram 
					if(AW_addr_s >= 32'h20000000 && AW_addr_s <= 32'h2000FFFF)
					begin
						ram[int'(AW_addr_s[17:0])] <= W_data_s[7:0];
						ram[int'(AW_addr_s[17:0])+1] <= W_data_s[15:8];
						ram[int'(AW_addr_s[17:0])+2] <= W_data_s[23:16];
						ram[int'(AW_addr_s[17:0])+3]   <= W_data_s[31:24];
						return 1;
					end
					else
						return 0;
				end
				
		8'h40 : begin  //peripherals 
					if(AW_addr_s >= 32'h40000000 && AW_addr_s <= 32'h40029FFF)
					begin
						peripherals[int'(AW_addr_s[18:0])]   <= W_data_s[7:0];
						peripherals[int'(AW_addr_s[18:0])+1] <= W_data_s[15:8];
						peripherals[int'(AW_addr_s[18:0])+2] <= W_data_s[23:16];
						peripherals[int'(AW_addr_s[18:0])+3] <= W_data_s[31:24];
						return 1;
					end
					else
						return 0;
				end
				
		8'hE0 : begin  //m3_registers 
					if(AW_addr_s >= 32'hE0000000 && AW_addr_s <= 32'hE00FFFFF)
					begin
						m3_registers[int'(AW_addr_s[20:0])] <= W_data_s[7:0];
						m3_registers[int'(AW_addr_s[20:0])+1] <= W_data_s[15:8];
						m3_registers[int'(AW_addr_s[20:0])+2] <= W_data_s[23:16];
						m3_registers[int'(AW_addr_s[20:0])+3]   <= W_data_s[31:24];
						return 1;
					end
					else
						return 0;
				end
				
		default: begin
		         end
	endcase
endfunction



/*
2:
************* PSEUDOCODE NO FSM: FULL DUPLEX **************

SEGNALI: 

AWREADY
AWVALID
AWADDR
AWPROT  (3 bit)//sono tutti 0 dal master, quindi la memoria li può ignorare // input per la memoria

WREADY
WVALID
WDATA
WSTRB (4 bit) // sono tutti a 1 , quindi li ignoriamo (?)//input per la memoria  

BVALID
BREADY
BRESP  //serve per dire al processore se la scrittura è corretta  //output per la memoria

ARVALID
ARREADY
ARADDR
ARPROT  (3 bit) // da ignorare (lato memoria)  //input per la memoria

RVALID
RREADY
RDATA
RRESP (2 bit) // è necessario? serve per dire al processore se la lettura è corretta  //output per la memoria

*/





logic led;// = 1'b0;



// READ FROM THAT SPECIFIC ADDRESS   0x4001 0800 : CTR del GPIOA
always@(*)
begin

if(rst == 1'b1)
begin
	
	//led = flash_1[18'h3FFFC];
	led = peripherals[18'h10800];

end	

end 








endmodule : tb_memory_test
