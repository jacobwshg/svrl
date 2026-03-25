
package frozenlake_pkg

	localparam int DIM = 4;
	localparam int WORLD_SIZE = DIM ** 2;
	localparam int ACTION_CNT = 4;

	localparam int DIM_WIDTH        = $clog2( DIM );
	localparam int STATE_IDX_WIDTH  = $clog2( WORLD_SIZE );
	localparam int ACTION_WIDTH     = $clog2( ACTION_CNT );

	typedef enum logic [ ACTION_WIDTH-1:0 ]
	{
		LEFT = 0, RIGHT = 1,
		UP   = 2, DOWN  = 3
	} action_t;

	typedef enum logic [ 1:0 ]
	{
		FROZEN = 2'b00,
		HOLE   = 2'b01,
		GOAL   = 2'b10
	} game_state_t;

	/*
	localparam game_state_t STATES [ 0:15 ] = 
	{
		2'b00, 2'b00, 2'b00, 2'b00,
		2'b00, 2'b01, 2'b00, 2'b01,
		2'b00, 2'b00, 2'b00, 2'b01,
		2'b01, 2'b00, 2'b00, 2'b10
	}
	*/

	localparam game_state_t STATES [ 0:WORLD_SIZE-1 ] = 
	{
		FROZEN, FROZEN, FROZEN, FROZEN,
		FROZEN, HOLE,   FROZEN, HOLE,
		FROZEN, FROZEN, FROZEN, HOLE,
		HOLE,   FROZEN, FROZEN, GOAL
	};

	function automatic void step(
		input  action_t action,
		input  logic [ DIM_WIDTH-1:0 ] row, col,
		output logic [ DIM_WIDTH-1:0 ] next_row, next_col
	);
		next_row, next_col = { row, col };

		case ( action )
			LEFT:
				if ( col > 0 )
					next_col = col - 1;
			RIGHT:
				if ( col < DIM-1 )
					next_col = col + 1;
			UP:
				if ( row > 0 )
					next_row = row - 1;
			DOWN:
				if ( row < DIM-1 )
					next_row = row + 1;
		endcase
	endfunction

	function automatic void set_flags(
		input  game_state_t game_state,

		output logic term,
		output logic trunc
	);
		term  = 1'( game_state == GOAL );
		trunc = 1'( game_state == HOLE );
	endfunction

endpackage: frozenlake_pkg

