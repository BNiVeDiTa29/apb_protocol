module apb_master (

input logic clk,
input logic rst_n,
input transfer,
input logic [31:0] addr_in,
input logic [31:0] data_in,
input logic write_en,

output logic pselx,		//send to slave
output logic penable,		//send to slave
output logic [31:0] paddr,	//send to slave
output logic pwrite,		//send to slave
output logic [31:0] pwdata,	//send to slave

input logic pready,		//from the slave
input logic [31:0] prdata	//from the slave
);

typedef enum logic [2:0] {
    IDLE = 3'b001,
    SETUP = 3'b010,
    ACCESS = 3'b100
  } state;

state current_state, next_state;

  logic [31:0] addr_reg; 
  logic [31:0] data_reg;
  logic write_reg;

//Reset logic for the FSM

always_ff @(posedge clk or negedge rst_n) 
	begin
		if (!rst_n)
			begin
				current_state <= IDLE;
			end
		else	
			begin
				current_state <= next_state;
			end
	end

//FSM next state transition logic

always_comb
	 begin
		next_state = current_state;

		case(current_state)
		
		IDLE : begin
			if (transfer)
				next_state = SETUP;
			else
				next_state = IDLE;
		       end

		SETUP : next_state = ACCESS;
	
		ACCESS: begin
			if (pready)
				next_state = (transfer) ? SETUP : IDLE;
			else
				next_state = ACCESS;
			end
		
		endcase
	end

//Latching the values here
  
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_reg  <= '0;
    data_reg  <= '0;
    write_reg <= 1'b0;
  end 
else if (current_state == SETUP) begin
    addr_reg  <= addr_in;
    data_reg  <= data_in;
    write_reg <= write_en;
  end
end

// FSM output combinational logic

always_comb 
	begin
      {pselx, penable, paddr, pwrite, pwdata} = '0;
      
      case(current_state)
      
		IDLE : begin
      			pselx 	= 1'b0;
          		penable	= 1'b0;
          		paddr	= 'b0;
          		pwrite	= 1'b0;
          		pwdata	= 'b0;
        	   end
      
		SETUP : begin
          		 pselx		=	1'b1;
          		 penable	= 	1'b0;
          		 paddr 		=	addr_reg;
          		 pwrite		=	write_reg;
          		 pwdata		=	data_reg;
        		end
      			
		ACCESS : begin
          		  pselx		=	1'b1;
          		  penable	=	1'b1;
          		  paddr		=	addr_reg;
          		  pwrite	=	write_reg;
          		  pwdata	=	data_reg;
      			 end
      endcase
    end
  
endmodule
