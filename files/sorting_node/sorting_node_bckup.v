module sorting_node	 #(parameter LEVEL = 2,
								parameter LENGTH = 4)
(
	input clk,
	input rst,
	
	//conexão para upper records
	input [31:0] q_U,
	input [31:0] aux_q_U,
	output [31:0]data_U,
	output [LEVEL-1:0]addr_U,
	output wren_U,
	
	//conexão para lower records
	input [31:0] q_L,
	output [31:0] data_L,
	output [LEVEL:0]addr_L,
	output wren_L,
	
	//hand shaking
	input initialize,
	output update_out,
	input update_in,
	
	output [LEVEL:0]address_updated_out,
	input [LEVEL-1:0]address_updated_in
);


	
	localparam [2:0] Initial_State = 3'd0,					//declaração dos estados();
					  Step1 = 3'd1,
					  wait_level = 3'd2,
					  Step2_LN = 3'd3,
					  Step2_RN = 3'd4;	
	reg		[2:0] SM_sorting = 3'b000; 			// Declaração do registrador de estados
	
	//Declaração dos registradores 
	
	reg [LEVEL:0]addr_L_reg;
	reg [31:0] data_L_reg;
	
	reg [LEVEL-1:0]addr_U_reg;
	reg [31:0] data_U_reg;
	
	reg wren_L_reg;
	reg wren_U_reg;
	
	reg update_out_reg;
	reg address_updated_out_reg;
	
	reg swap_LN = 0;
	reg left = 0;
	
	reg [2:0] swap_flag = 0;
	
	/******* Processo principal - Maquina de estados *******/
	always @(posedge clk)
		if (rst)	// reseta todos os registradores
		begin
			SM_sorting <= Initial_State;
			data_U_reg <= 0;
			addr_U_reg <= 0;
			wren_U_reg <= 0;
			data_L_reg <= 0;
			addr_L_reg <= 0;
			wren_L_reg <= 0;
			update_out_reg <=0;
		end else
		begin
			case (SM_sorting)
			
				// Espera a inicialização do heapsort
				Initial_State:
				begin
					if (initialize)
						SM_sorting <= Step1;
					data_U_reg <= 0;
					addr_U_reg <= 0;
					wren_U_reg <= 0;
					data_L_reg <= 0;
					addr_L_reg <= 0;
					wren_L_reg <= 0;
					address_updated_out_reg <= 0;
				end
				
				// esse passo pode ser otimizado
				// se n tiver update, fica nesse nivel ate ter update_in :)
				Step1:
				begin
					if (update_in)
					begin
						SM_sorting <= wait_level ;
						addr_U_reg <= address_updated_in;
						wren_U_reg <= 0;
						addr_L_reg <= address_updated_in;
						wren_L_reg <= 0;
					end
					wren_L_reg <= 0;
					wren_U_reg <= 0;
					SM_sorting <= wait_level;
					update_out_reg <= 0;
				end
				
				wait_level:
				begin
					SM_sorting <= Step2_LN;
				end
				
				Step2_LN:
				begin
					if (q_L < aux_q_U)		//verifica se L < N
						swap_LN <= 1;
					else
						swap_LN <= 0;
					left <= q_L;
					addr_L_reg <= address_updated_in + (LENGTH/2);
					SM_sorting <= Step2_RN;
				end
				
				Step2_RN:
				begin
					if (q_L < q_U)		//verifica se R < N 
					begin
						if (q_L < left)	//swap 3 ( R< N & R < L) 
						begin
							data_U_reg <= q_L;
							data_L_reg <= q_U;
							wren_L_reg <= 1;
							wren_U_reg <= 1;
							address_updated_out_reg = address_updated_in + (LENGTH/2);
							update_out_reg <= 1;
							addr_L_reg <= address_updated_in; //alteracao
							SM_sorting <= Step1;					//aleracao
							swap_flag = 1;
						end
						else					//Swap2 (L < N & L =< R)
						begin
							data_U_reg <= q_L;
							data_L_reg <= q_U;
							wren_L_reg <= 1;
							wren_U_reg <= 1;
							addr_L_reg <= address_updated_in;
							address_updated_out_reg = address_updated_in;
							update_out_reg <= 1;
							SM_sorting <= Step1;					//aleracao
							swap_flag = 2;
						end
					end	
					else
					begin
						if (swap_LN)		//Swap2 (L < N & L =< R)
						begin
							data_U_reg <= q_L;
							data_L_reg <= q_U;
							wren_L_reg <= 1;
							wren_U_reg <= 1;
							addr_L_reg <= address_updated_in;
							address_updated_out_reg = address_updated_in;
							update_out_reg <= 1;
							SM_sorting <= Step1;					//aleracao
							swap_flag = 3;
						end
				addr_L_reg <= address_updated_in;
				SM_sorting <= Step1;
				end
				end
			endcase
		end
					
assign 	addr_L = addr_L_reg;
assign 	addr_U = addr_U_reg;

assign 	data_U = data_U_reg;
assign 	data_L = data_L_reg;

assign wren_L = wren_L_reg;
assign wren_U = wren_U_reg;

assign update_out = update_out_reg;
assign address_updated_out = address_updated_out_reg;

//sera botar a comparação assincrono?	
	//always @(posedge clk)
// sera botar os endereços assincrono? sim, porque eles são wires e não registradores
//	reg [23:0] data2_FFT_1_x_abs,data2_FFT_1_y_abs,data2_buff_1_x_abs,data2_buff_1_y_abs;
//	always @(posedge clk)
//	begin
//		data2_FFT_1_x_abs  <= data_2_wr_RAM_FFT_1_in[63] ? ~data_2_wr_RAM_FFT_1_in[63:40] + 1: data_2_wr_RAM_FFT_1_in[63:40];
//		data2_buff_1_x_abs <= data_2_rd_RAM_buff_1[63] ? ~data_2_rd_RAM_buff_1[63:40] + 1: data_2_rd_RAM_buff_1[63:40];
//		data2_FFT_1_y_abs  <= data_2_wr_RAM_FFT_1_in[31] ? ~data_2_wr_RAM_FFT_1_in[31:8] + 1: data_2_wr_RAM_FFT_1_in[31:8];
//		data2_buff_1_y_abs <= data_2_rd_RAM_buff_1[31] ? ~data_2_rd_RAM_buff_1[31:8] + 1: data_2_rd_RAM_buff_1[31:8];
//	end
//	
//	wire [23:0] xi_2 = (SM_Declipper == CALC_ABS_MAX_Z) ? 
//							 data2_FFT_1_x_abs : data2_buff_1_x_abs;			
endmodule
				
				
				