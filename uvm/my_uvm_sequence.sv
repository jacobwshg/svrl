import uvm_pkg::*;

class my_uvm_transaction extends uvm_sequence_item;
	logic [ DWIDTH-1:0 ] rand_q = 'h0;
	logic [ ACTION_WIDTH-1:0 ] pred_action = 'h0;
	logic [ GAMESTATE_IDX_WIDTH-1:0 ] pred_gamestate_idx = 'h0;
	logic [ REWARD_WIDTH-1:0 ] pred_reward = 'h0;

	`uvm_object_utils_begin( my_uvm_transaction )
		`uvm_field_int( rand_q, UVM_ALL_ON )
		`uvm_field_int( pred_action, UVM_ALL_ON )
		`uvm_field_int( pred_gamestate_idx, UVM_ALL_ON )
		`uvm_field_int( pred_reward, UVM_ALL_ON )
	`uvm_object_utils_end

	function new( string name = "" );
		super.new( name );
	endfunction
endclass

class my_uvm_sequence extends uvm_sequence#( my_uvm_transaction );
	`uvm_object_utils( my_uvm_sequence )

	function new( string name = "" );
		super.new( name );
	endfunction: new

	task body();
		my_uvm_transaction tx_in;

		/*
		int infile_q = $fopen( INFILE_RAND_Q, "r" );
		if ( !infile )
		{
			`uvm_fatal( "SEQ_RUN", $sformatf( "Failed to open input file %s", INFILE_RAND_Q ) );
		}
		*/

		logic signed [ DWIDTH-1:0 ] rand_q_mem [ 0:RAND_CNT ];
		$readmemh( INFILE_RAND_Q, rand_q_mem );
		int rand_idx = 0;
		logic signed [ DWIDTH-1:0 ] rand_q = 'h0;

		while ( !vif.train_done )
		begin
			tx_in = my_uvm_transaction::type_id::create(
				.name( "tx_in" )
			);
			start_item( tx_in );

			if ( rand_idx === RAND_CNT )
			begin
				rand_idx = 0;
			end
			rand_q = rand_q_mem[ rand_idx ];
			rand_idx += 1;

			tx_in.rand_q = rand_q;

			finish_item( tx_in );
		end

		#300;
	endtask: body
endclass: my_uvm_sequence

typedef uvm_sequencer#( my_uvm_transaction ) my_uvm_sequencer;

