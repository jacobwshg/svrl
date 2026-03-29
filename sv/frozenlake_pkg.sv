
import globals_pkg::REWARD_WIDTH;

package frozenlake_pkg;

	localparam int DIM = 4;
	localparam int WORLD_SIZE = DIM ** 2;
	localparam int ACTION_CNT = 4;

	localparam int DIM_WIDTH = $clog2( DIM );
	localparam int GAMESTATE_IDX_WIDTH  = $clog2( WORLD_SIZE );
	localparam int ACTION_WIDTH = $clog2( ACTION_CNT );
	localparam int OUTWIDTH = ACTION_WIDTH
		+ GAMESTATE_IDX_WIDTH
		+ globals_pkg::REWARD_WIDTH;

	typedef enum logic [ ACTION_WIDTH-1:0 ]
	{
		LEFT = 0, RIGHT = 1,
		UP   = 2, DOWN  = 3
	} _action_enum_t;
	typedef logic [ ACTION_WIDTH-1:0 ] action_t;

	typedef enum logic [ 1:0 ]
	{
		FROZEN = 2'b00,
		HOLE   = 2'b01,
		GOAL   = 2'b10
	} gamestate_t;

	/*
	localparam gamestate_t GAMESTATES [ 0:15 ] = 
	{
		2'b00, 2'b00, 2'b00, 2'b00,
		2'b00, 2'b01, 2'b00, 2'b01,
		2'b00, 2'b00, 2'b00, 2'b01,
		2'b01, 2'b00, 2'b00, 2'b10
	}
	*/

	localparam gamestate_t GAMESTATES [ 0:WORLD_SIZE-1 ] = 
	{
		FROZEN, FROZEN, FROZEN, FROZEN,
		FROZEN, HOLE,   FROZEN, HOLE,
		FROZEN, FROZEN, FROZEN, HOLE,
		HOLE,   FROZEN, FROZEN, GOAL
	};

	function automatic void step(
		input  action_t action,
		input  logic [ DIM_WIDTH-1:0 ] row, col,
		output logic [ DIM_WIDTH-1:0 ] next_row, next_col,
		output logic [ GAMESTATE_IDX_WIDTH-1:0 ] next_gamestate_idx
	);
		{ next_row, next_col } = { row, col };
		next_gamestate_idx = 'h0;

		case ( action )
			2'b00: //LEFT
				if ( col > 0 )
					next_col = col - 1;
			2'b01: //RIGHT
				if ( col < DIM-1 )
					next_col = col + 1;
			2'b10: //UP
				if ( row > 0 )
					next_row = row - 1;
			2'b11: //DOWN
				if ( row < DIM-1 )
					next_row = row + 1;
		endcase

		// assume DIM is power of 2, so row and col always occupy distinct
		// bits
		next_gamestate_idx = { next_row, next_col };

	endfunction: step

	function automatic void eval_gamestate(
		input  gamestate_t gamestate,
		output logic term,
		output logic trunc,
		output logic [ 31:0 ] reward
	);
		term  = 1'( gamestate == GOAL );
		trunc = 1'( gamestate == HOLE );
		// generate logical reward ( no quantization )
		reward = ( gamestate == GOAL ) ? 1'h1: 1'h0;
	endfunction: eval_gamestate

endpackage: frozenlake_pkg

