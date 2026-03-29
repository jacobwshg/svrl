import uvm_pkg::*;

class my_uvm_monitor_output extends uvm_monitor;

	`uvm_component_utils( my_uvm_monitor_output )

	uvm_analysis_port#( my_uvm_transaction ) mon_ap_output;
	virtual my_uvm_if vif;

	function new( string name, uvm_component parent );
		super.new( name, parent );
	endfunction: new

	virtual function void build_phase( uvm_phase phase );
		super.build_phase( phase );
		void'(
			uvm_resource_db#( virtual my_uvm_if )::read_by_name(
				.scope( "ifs" ), .name( "vif" ), .val( vif )
			)
		);
		mon_ap_output = new( "mon_ap_output", this );
	endfunction: build_phase

	virtual task run_phase( uvm_phase phase );

		my_uvm_transaction tx_out;

		@ ( posedge vif.rst );	
		@ ( negedge vif.rst );	

		while ( ~vif.done )
		begin	
			vif.out_rd_en = 1'b0;

			@ ( negedge vif.clk );
			if ( !vif.out_empty )
			begin
				vif.out_rd_en = 1'b1;

				tx_out = my_uvm_transaction::type_id::create( "tx_out", this );
				{
					tx_out.pred_action,
					tx_out.pred_gamestate_idx,
					tx_out.pred_reward
				} = vif.out_dout;

				mon_ap_output.write( tx_out ); 
			end
		end
	endtask: run_phase

	virtual function void final_phase( uvm_phase phase );
		super.final_phase( phase );
	endfunction: final_phase

endclass: my_uvm_monitor_output

