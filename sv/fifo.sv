
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

	logic [ FIFO_ADDR_WIDTH:0 ] wr_addr_r;
	logic [ FIFO_ADDR_WIDTH:0 ] rd_addr_r, rd_addr_next;

	always_ff @ ( posedge wr_clk )
	begin
		if ( reset )
		begin
			wr_addr_r <= 'h0;
		end
		else if ( wr_en && !full )
		begin
			fifo_buf[ wr_addr_r[ FIFO_ADDR_WIDTH-1:0 ] ] <= din;
			wr_addr_r <= wr_addr_r + 1'h1;
		end
	end

	assign full = (
		wr_addr_r[ FIFO_ADDR_WIDTH:0 ] ===
		{ ~rd_addr_r[ FIFO_ADDR_WIDTH ], rd_addr_r[ FIFO_ADDR_WIDTH-1:0 ] }
	);

	always_ff @ ( posedge rd_clk )
	begin
		if ( reset )
		begin
			rd_addr_r <= 1'h0;
			empty <= 1'b1;
		end
		else
		begin
			rd_addr_r <= rd_addr_next;
			empty <= ( rd_addr_next === wr_addr_r );
		end
	end

	assign rd_addr_next = rd_addr_r + ( ( rd_en && !empty ) ? 1'h1 : 1'h0 );
	assign dout = fifo_buf[ rd_addr_r[ FIFO_ADDR_WIDTH-1:0 ] ];

endmodule

