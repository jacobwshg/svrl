module bram 
#(
	parameter BRAM_ADDR_WIDTH = 10,
	parameter BRAM_DATA_WIDTH = 8
) 
(
	input  logic clock,
	input  logic [ BRAM_ADDR_WIDTH-1:0 ] rd_addr,
	input  logic [ BRAM_ADDR_WIDTH-1:0 ] wr_addr,
	input  logic wr_en,
	input  logic [ BRAM_DATA_WIDTH-1:0 ] din, 
	output logic [ BRAM_DATA_WIDTH-1:0 ] dout
);
	logic [ BRAM_DATA_WIDTH-1:0 ] mem [ 2**BRAM_ADDR_WIDTH-1:0 ]
	/* synthesis syn_ramstyle = "block_ram" */
	;

	logic [ BRAM_ADDR_WIDTH-1:0 ] rd_addr_r;

	always_ff @ ( posedge clock ) begin
		if ( wr_en )
		begin
			mem[ wr_addr ] <= din; 
		end
		rd_addr_r <= rd_addr;
	end

	assign dout = mem[ rd_addr_r ];

endmodule

