
import uvm_pkg::*;

class my_uvm_driver extends uvm_driver#( my_uvm_transaction );
	`uvm_component_utils( my_uvm_driver )

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
	endfunction: build_phase

	virtual task drive();
		my_uvm_transaction tx_in;

		@ ( posedge vif.rst );
		@ ( negedge vif.rst );

		forever
		begin
			vif.in_din = 'h0;
			vif.in_wr_en = 1'b0;

			@ ( negedge vif.clk )
			begin
				if ( !vif.in_full )
				begin
					seq_item_port.get_next_item( tx_in );
					
					vif.in_din = tx_in.rand_q;
					vif.in_wr_en = 1'b1;
					
					seq_item_port.item_done();
				end
			end
		end

		@ ( negedge vif.clk );
		vif.in_din = 'h0;
		vif.in_wr_en = 1'b0;

	endtask: drive

	virtual task run_phase( uvm_phase phase );
		drive();
	endtask: run_phase

endclass: my_uvm_driver

