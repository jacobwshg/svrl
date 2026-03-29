
import uvm_pkg::*;
import my_uvm_package::*;

`include "my_uvm_if.sv"

`timescale 1 ns / 1 ns

module my_uvm_tb;

	my_uvm_if vif();

	// DUT
	ql_top dut
	(
		.clk ( vif.clk ),
		.rst ( vif.rst ),
		.maxsteps_in ( vif.maxsteps_in ),

		.in_din    ( vif.in_din ),
		.out_rd_en ( vif.out_rd_en ),
		.out_empty ( vif.out_empty ),

		.in_wr_en ( vif.in_wr_en ),
		.in_full  ( vif.in_full ),
		.out_dout ( vif.out_dout ),

		.train_done ( vif.done ),
		.done ( vif.done )
	);

	initial
	begin
		uvm_resource_db#( virtual my_uvm_if )::set(
			.scope( "ifs" ), .name( "vif" ), .val( vif )
		);

		run_test("my_uvm_test");		
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

