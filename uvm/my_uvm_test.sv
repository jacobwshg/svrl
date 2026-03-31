
import uvm_pkg::*;

class my_uvm_test extends uvm_test;

	`uvm_component_utils( my_uvm_test )

	my_uvm_env env;
	virtual my_uvm_if vif;

	function new( string name, uvm_component parent );
		super.new( name, parent );
	endfunction: new

	virtual function void build_phase( uvm_phase phase );
		super.build_phase( phase );
		env = my_uvm_env::type_id::create(
			.name( "env" ), .parent( this )
		);

		uvm_resource_db#( virtual my_uvm_if )::read_by_name(
			.scope( "ifs" ), .name( "vif" ), .val( vif )
		);

	endfunction: build_phase

	virtual function void end_of_elaboration_phase( uvm_phase phase );
		uvm_top.print_topology();
	endfunction: end_of_elaboration_phase

	virtual task run_phase( uvm_phase phase );
		my_uvm_sequence seq;

		phase.phase_done.set_drain_time( this, CLOCK_PERIOD*100 );

		// notify that run_phase has started
		// NOTE: simulation terminates once all objections are dropped
		phase.raise_objection( .obj( this ) );

		seq = my_uvm_sequence::type_id::create(
			.name( "seq" ), .contxt( get_full_name() )
		);

		// seqr streams randoms indefinitely ( because prediction phase
		// can theoretically run for arbitrary steps ), so allow joining 
		// the fork as soon as done is asserted
		fork
			seq.start( env.agent.seqr );
			wait ( vif.done === 1'b1 );
		join_any
		disable fork;

		// notify that run_phase has completed
		phase.drop_objection( .obj( this ) );
	endtask: run_phase

endclass: my_uvm_test

