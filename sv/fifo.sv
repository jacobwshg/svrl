
module fifo #(
	parameter FIFO_DATA_WIDTH = 32,
	parameter FIFO_BUFFER_SIZE = 256
)
(
	input  logic reset,
	input  logic wr_clk,
	input  logic wr_en,
	input  logic [ FIFO_DATA_WIDTH-1:0 ] din,
	output logic full,
	input  logic rd_clk,
	input  logic rd_en,
	output logic [ FIFO_DATA_WIDTH-1:0 ] dout,
	output logic empty
);

	function automatic logic [ FIFO_DATA_WIDTH-1:0 ] to01(
		input logic [ FIFO_DATA_WIDTH-1:0 ] data
	);
		logic [ FIFO_DATA_WIDTH-1:0 ] result;
		for ( int i=0; i < FIFO_DATA_WIDTH; ++i )
		begin
			result[ i ] = ( data[ i ] === 1'b1 ) ? 1'b1 : 1'b0;
		end;
		return result;
	endfunction

	localparam FIFO_ADDR_WIDTH = $clog2( FIFO_BUFFER_SIZE );
	logic [ FIFO_DATA_WIDTH-1:0 ] fifo_buf [ FIFO_BUFFER_SIZE-1:0 ];
	logic [ FIFO_ADDR_WIDTH:0 ] wr_addr, wr_addr_c;
	logic [ FIFO_ADDR_WIDTH:0 ] rd_addr, rd_addr_c;
	logic full_c, empty_c;

	always_ff @ ( posedge wr_clk ) 
	begin : p_write_buffer
		if ( wr_en && !full_c )
		begin
			fifo_buf[ wr_addr[ FIFO_ADDR_WIDTH-1:0 ] ] <= din;
		end
	end

	always_ff @ ( posedge wr_clk, posedge reset )
	begin : p_wr_addr
		if ( reset ) 
			wr_addr <= 'h0;
		else
			wr_addr <= wr_addr_c;
	end

	always_ff @ ( posedge rd_clk ) 
	begin : p_rd_buffer
		dout <= to01( fifo_buf[ rd_addr_c[ FIFO_ADDR_WIDTH-1:0 ] ] );
	end

	always_ff @ ( posedge rd_clk, posedge reset )
	begin : p_rd_addr
		if ( reset ) 
			rd_addr <= 'h0;
		else
			rd_addr <= rd_addr_c;
	end

	always_ff @ ( posedge rd_clk, posedge reset )
	begin : p_empty
		if ( reset ) 
			empty <= 1'b1;
		else
			empty <= ( wr_addr === rd_addr_c ) ? 1'b1 : 1'b0;
	end

	assign empty_c = ( wr_addr === rd_addr ) ? 1'b1 : 1'b0;
	assign full_c = ( wr_addr[ FIFO_ADDR_WIDTH-1:0 ] === rd_addr[ FIFO_ADDR_WIDTH-1:0 ] ) &&
					( wr_addr[ FIFO_ADDR_WIDTH ] !== rd_addr[ FIFO_ADDR_WIDTH ] ) ? 1'b1 : 1'b0;
	assign full = full_c;
	assign rd_addr_c = ( rd_en && !empty_c ) ? ( rd_addr + 1'h1 ) : rd_addr;
	assign wr_addr_c = ( wr_en && !full_c  ) ? ( wr_addr + 1'h1 ) : wr_addr;

endmodule

