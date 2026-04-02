
import uvm_pkg::*;
import my_uvm_package::*;

`include "my_uvm_if.sv"

`timescale 1 ns / 1 ns

module my_uvm_tb;

////
//localparam logic signed [ DWIDTH-1:0 ] ALPHA   = 32'h2000; // 0.5
//localparam logic signed [ DWIDTH-1:0 ] GAMMA   = 32'h2ccc; // 0.7
//localparam logic signed [ DWIDTH-1:0 ] EPSILON = 32'h1999; // 0.4

	my_uvm_if vif();

	// DUT
	ql_top #(
		.ALPHA   ( ALPHA ),
		.GAMMA   ( GAMMA ),
		.EPSILON ( EPSILON )
	) dut (
		.clk ( vif.clk ),
		.rst ( vif.rst ),
		.maxsteps_in ( vif.maxsteps_in ),

		.in_din    ( vif.in_din ),
		.in_wr_en  ( vif.in_wr_en ),
		.out_rd_en ( vif.out_rd_en ),

		.in_full   ( vif.in_full ),
		.out_dout  ( vif.out_dout ),
		.out_empty ( vif.out_empty ),

		.train_done ( vif.train_done ),
		.done ( vif.done )
	);

	initial
	begin
		uvm_resource_db#( virtual my_uvm_if )::set(
			.scope( "ifs" ), .name( "vif" ), .val( vif )
		);

		run_test( "my_uvm_test" );
	end

	initial
	begin
		vif.maxsteps_in <= MAX_STEPS;

		vif.clk <= 1'b1;
		vif.rst <= 1'b0;
		@ ( posedge vif.clk );
		vif.rst <= 1'b1;
		@ ( posedge vif.clk );
		vif.rst <= 1'b0;
	end

	always
		#( CLOCK_PERIOD/2 )
		vif.clk = ~vif.clk;
		
endmodule: my_uvm_tb

