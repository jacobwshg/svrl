
import uvm_pkg::*;

class my_uvm_scoreboard extends uvm_scoreboard;
	`uvm_component_utils( my_uvm_scoreboard )

	uvm_analysis_export #( my_uvm_transaction ) sb_export_output;
	//uvm_analysis_export #( my_uvm_transaction ) sb_export_compare;

	uvm_tlm_analysis_fifo #( my_uvm_transaction ) output_fifo;
	//uvm_tlm_analysis_fifo #( my_uvm_transaction ) compare_fifo;

	function new( string name, uvm_component parent );
		super.new( name, parent );
	endfunction: new

	virtual function void build_phase( uvm_phase phase );
		super.build_phase( phase );
		sb_export_output  = new( "sb_export_output", this );
		//sb_export_compare = new( "sb_export_compare", this );
		output_fifo  = new( "output_fifo", this );
		//compare_fifo = new( "compare_fifo", this );
	endfunction: build_phase

	virtual function void connect_phase( uvm_phase phase );
		sb_export_output.connect( output_fifo.analysis_export );
		//sb_export_compare.connect( compare_fifo.analysis_export );
	endfunction: connect_phase

	virtual task run_phase( uvm_phase phase );
		my_uvm_transaction tx_out = new( "tx_out" );
		//my_uvm_transaction tx_cmp;

		logic [ ACTION_WIDTH-1:0 ] action = 'h0;
		logic [ GAMESTATE_IDX_WIDTH-1:0 ] gamestate_idx = 'h0;
		logic [ REWARD_WIDTH-1:0 ] reward;
		string msg;

		forever
		begin
			output_fifo.get( tx_out );

			action = tx_out.pred_action;
			gamestate_idx = tx_out.pred_gamestate_idx;
			reward = tx_out.pred_reward;
			msg = $sformatf(
				"Predicted action %0d, gamestate idx %0d, reward %0d",
				action, gamestate_idx, reward
			);
			`uvm_info( "SB_RUN", msg, UVM_LOW );

			//compare_fifo.get( tx_cmp );
			//comparison( tx_cmp, tx_out );
		end
	endtask: run_phase

	/*
	virtual function void comparison(
		my_uvm_transaction tx_cmp,
		my_uvm_transaction tx_out
	);
	endfunction: comparison
	*/
endclass: my_uvm_scoreboard

