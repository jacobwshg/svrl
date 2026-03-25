
/*
 * 4x4 grid
 */

module q_learner 
#(
	parameter int DWIDTH = 32,
	parameter int ACTION_CNT = 4,

	parameter int DIM = 4,
	parameter int STATE_CNT = DIM ** 2,

	parameter int REWARD_WIDTH = DWIDTH,
	parameter logic signed [ DWIDTH-1:0 ] ALPHA,
	parameter logic signed [ DWIDTH-1:0 ] GAMMA,
	parameter logic signed [ DWIDTH-1:0 ] EPSILON,
	parameter int MAX_STEPS
)
(
	input  logic clk,
	input  logic rst,
	input  logic [ DWIDTH-1:0 ] steps,

	input  logic rand_in,
	input  logic rand_empty,
	input  logic pred_full,
	
	output logic train_done,
	output logic rand_rd_en,
	output logic pred_wr_en,
	output logic [ $clog2( STATE_CNT ) + $clog2( ACTION_CNT ) + REWARD_WIDTH-1:0 ]
		pred_out;
);

	import quant_pkg::*;

	localparam int STATE_WIDTH = $clog2( STATE_CNT );
	localparam int ACTION_WIDTH = $clog2( ACTION_CNT );
	localparam logic signed [ REWARD_WIDTH-1:0 ] QMIN = 1'h1 <<< ( REWARD_WIDTH-1 );

	typedef enum logic [ 4:0 ]
	{
		S_INIT,
		S_GET_RAND,

		S_EXPLORE_GET_RAND,
		S_EXPLORE_CHOICE,
		S_EXPLORE_ACTION,

		S_EXPLOIT_GET_RAND,
		S_FIND_QMAX,
		S_COUNT_QMAX_ACTIONS,
		S_EXPLOIT_ACTION_SETUP,
		S_EXPLOIT_ACTION,

		S_TAKE_STEP,
		S_AFTER_STEP,
		S_MUL_GAMMA,
		S_ADD_SUB,
		S_MUL_ALPHA,
		S_UPDATE_QCUR,
		S_STEP_TAIL,

		S_PREDICT_OUT,

		S_DONE
	} state_t;
	state_t state, state_c;

	typedef enum logic [ ACTION_WIDTH-1:0 ]
	{
		LEFT = 0, RIGHT = 1, UP = 2, DOWN = 3
	} action_t;
	action_t action, action_c;

	logic [ ACTION_WIDTH-1:0 ]
		Qmax_action_rd_addr, Qmax_action_wr_addr,
		Qmax_action_in, Qmax_action_out;
	logic Qmax_action_wr_en;

	bram #(
		.BRAM_ADDR_WIDTH( ACTION_WIDTH ),
		.BRAM_DATA_WIDTH( ACTION_WIDTH )
	) Qmax_actions_buf (
		.clock( clk ),
		.rd_addr( Qmax_action_rd_addr ),
		.wr_addr( Qmax_action_wr_addr ),
		.wr_en( Qmax_action_wr_en ),
		.din( Qmax_action_in ),
		.dout( Qmax_action_out )
	);

	logic train_done_c;

	logic [ ACTION_WIDTH:0 ] Qmax_action_idx, Qmax_action_idx_c;

	logic [ DWIDTH-1:0 ] rand_reg, rand_c;

	logic signed [ REWARD_WIDTH-1:0 ] state_Qmax, state_Qmax_c;

	logic Qmax_is_next, Qmax_is_next_c;

	logic [ DWIDTH-1:0 ] choice, choice_c;

	logic [ DWIDTH-1:0 ] step, step_c;

	// technically only need half STATE_WIDTH for each dimension;
	// keep full width to facilitate arithmetic
	logic [ STATE_WIDTH-1:0 ]
		row, row_c,
		col, col_c;

	logic [ STATE_WIDTH:0 ]
		cur_game_state, cur_game_state_c,
		next_game_state, next_game_state_c;
	logic signed [ REWARD_WIDTH-1:0 ]
		Q_cur, Q_cur_c,
		Q_next, Q_next_c,
		Q_tmp, Q_tmp_c;

	logic
		term, term_c,
		trunc, trunc_c;

	logic [ STATE_WIDTH-1:0 ]
		Qtbl_rd_addr, 
		//Qtbl_rd_addr_c,
		Qtbl_wr_addr;
	logic [ ACTION_CNT-1:0 ] Qtbl_wr_en;
	logic signed [ REWARD_WIDTH-1:0 ] Qtbl_din;
	logic signed [ ACTION_CNT-1:0 ] [ REWARD_WIDTH-1:0 ] Qtbl_dout;

	bram_block #(
		.BRAM_ADDR_WIDTH( STATE_WIDTH ),
		.BANK_DATA_WIDTH( REWARD_WIDTH ),
		.BANK_CNT       ( ACTION_CNT ),
		.BRAM_DATA_WIDTH( BANK_DATA_WIDTH*BANK_CNT )
	) Qtbl (
		.clock  ( clk ),
		//.rd_addr( Qtbl_rd_addr_c ),
		.rd_addr( Qtbl_rd_addr ),
		.wr_addr( Qtbl_wr_addr ),
		.wr_en  ( Qtbl_wr_en ),
		.din    ( Qtbl_din ),
		.dout   ( Qtbl_dout )
	);

	function automatic void step_frozenlake_4x4(
		input  action_t action,
		input  logic [ STATE_WIDTH-1:0 ] row, col,
		output logic [ STATE_WIDTH-1:0 ] row_o, col_o,
		output logic [ STATE_WIDTH-1:0 ] obs,
		output logic signed [ REWARD_WIDTH-1:0 ] rew,
		output logic term,
		output logic trunc
	);

		row_o, col_o = { row, col };
		obs = 'h0;
		rew = 'h0;
		term = 1'b0;
		trunc = 1'b0;

		case ( action )
			LEFT:
			begin
				if ( col > 0 )
				begin
					col_o = col - 1;
				end
			end
			RIGHT:
			begin
				if ( col < DIM-1 )
				begin
					col_o = col + 1;
				end
			end
			UP:
			begin
				if ( row > 0 )
				begin
					row_o = row - 1;
				end
			end
			DOWN:
			begin
				if ( row < DIM-1 )
				begin
					row_o = row + 1;
				end
			end
			default:
			begin
			end
		endcase

		obs = ( row_o <<< 2 ) + col_o;

		case ( row_o )
			1:
			begin
				if ( col_o==1 || col_o==3 )
				begin
					trunc = 1'b1;
				end
			end
			2:
			begin
				if ( col_o==3 )
				begin
					trunc = 1'b1;
				end
			end
			3:
			begin
				if ( col_o==0 )
				begin
					trunc = 1'b1;
				end
				else if ( col_o==3 ):
				begin
					term = 1'b1;
					rew = QUANT( 1'h1 );
				end
			end
			default:
			begin
			end
		endcase

	endfunction


	always_comb
	begin
		train_done_c = train_done;
		rand_rd_en = 1'b0;
		pred_wr_en = 1'b0;
		pred_out = 'hX;

		state_c = state;
		rand_c = rand_reg;
		state_Qmax_c = state_Qmax;
		choice_c = choice;
		action_c = action;

		Qmax_is_next_c = Qmax_is_next;

		Qmax_action_rd_addr = 'h0;
		Qmax_action_wr_addr = 'hX;
		Qmax_action_in = 'hX;
		Qmax_action_wr_en = 1'b0;
		Qmax_action_idx_c = Qmax_action_idx;

		{ row_c, col_c } = { row, col };

		cur_game_state_c  = cur_game_state;
		next_game_state_c = next_game_state;
		Q_cur_c  = Q_cur;
		Q_next_c = Q_next;
		Q_tmp_c  = Q_tmp;

		// Normally, read from Q-table at current game state
		// unless when updating reward
		//
		//Qtbl_rd_addr_c = Qtbl_rd_addr;
		Qtbl_rd_addr = cur_game_state;
		Qtbl_wr_addr = 'hX;
		Qtbl_wr_en = 'b0;
		Qtbl_din = 'shX;

		term_c  = term;
		trunc_c = trunc;

		case ( state )
			S_INIT:
			begin
				// initialize rewards to 0
				Qtbl_wr_addr = cur_game_state;
				Qtbl_din = 'sh0;
				Qtbl_wr_en = 'b1;
				cur_game_state_c = cur_game_state + 1'h1;
				if ( cur_game_state_c == STATE_CNT )
				begin
					// At next clk edge, all state rows in Q-table will have
					// been zero-initialized
					cur_game_state_c = 'h0;
					state_c = S_GET_RAND;
				end
			end
			S_GET_RAND:
			begin
				if ( ~rand_empty )
				begin
					rand_rd_en = 1'b1;
					rand_c = rand_in;
					state_c = ( rand_in < EPSILON )
						? S_EXPLORE_GET_RAND
						: S_EXPLOIT_GET_RAND;
				end
				//Qtbl_rd_addr_c = cur_game_state;
			end

			// Explore
			S_EXPLORE_GET_RAND:
			begin
				if ( ~rand_empty )
				begin
					rand_rd_en = 1'b1;
					rand_c = rand_in;
					state_c = S_EXPLORE_CHOICE;
				end
			end
			S_EXPLORE_CHOICE:
			begin
				choice_c = rand_reg <<< 2; // 4 actions
				state_c = S_EXPLORE_ACTION;
			end
			S_EXPLORE_ACTION:
			begin
				action_c = DEQUANT( choice );
				state_c = S_TAKE_STEP;
			end

			// Exploit
			S_EXPLOIT_GET_RAND:
			begin
				if ( ~rand_empty )
				begin
					rand_rd_en = 1'b1;
					rand_c = rand_in;

					Qmax_is_next_c = 1'b0;

					action_c = LEFT;
					state_Qmax_c = QMIN;
					state_c = S_FIND_QMAX;
				end
			end
			S_FIND_QMAX:
			begin
				if ( Qtbl_dout[ action ] > state_Qmax )
				begin
					state_Qmax_c = Qtbl_dout[ action ];
				end

				// if finding Q_max within next state (updating reward, not exploiting),
				// hold read addr at next state
				if ( Qmax_is_next )
				begin
					Qtbl_rd_addr = next_game_state;
				end

				if ( action == DOWN )
				begin
					Qmax_action_idx_c = 'h0;
					action_c = LEFT;
					state_c = Qmax_is_next
						? S_MUL_GAMMA
						: S_COUNT_QMAX_ACTIONS;
				end
				else
				begin
					action_c = action + 1'h1;
				end
			end
			S_COUNT_QMAX_ACTIONS:
			begin
				// iterate over all actions, increment Qmax_action_idx as
				// needed (whenever action has shared Qmax).
				// in a given cycle, Qmax_action_idx <= action (equal if 
				// all actions share Qmax)
				//
				if ( Qtbl_dout[ action ] == state_Qmax )
				begin
					Qmax_action_wr_addr = Qmax_action_idx;
					Qmax_action_in = action[ ACTION_WIDTH-1:0 ];
					Qmax_action_wr_en = 1'b1;
					Qmax_action_idx_c = Qmax_action_idx + 1'h1;
				end

				if ( action == DOWN )
				begin
					action_c = LEFT;
					state_c = S_EXPLOIT_CHOICE;
				end
				else
				begin
					action_c = action + 1'h1;
				end
			end
			S_EXPLOIT_CHOICE:
			begin
				choice_c = ( rand_reg * Qmax_action_idx );
				state_c = S_EXPLOIT_ACTION_SETUP;
			end
			// set up Qmax_actions_buf bram read
			S_EXPLOIT_ACTION_SETUP:
			begin
				Qmax_action_idx_c = DEQUANT( choice );
				Qmax_action_rd_addr = Qmax_action_idx_c[ ACTION_WIDTH-1:0 ];
				state_c = S_EXPLOIT_ACTION;
			end
			S_EXPLOIT_ACTION:
			begin
				action_c = Qmax_action_out;
				state_c = S_TAKE_STEP;
			end

			S_TAKE_STEP:
			begin

				Q_cur_c = Qtbl_dout[ action ];

				// hardcode FrozenLake
				/*
					input  action_t action,
					input  logic [ STATE_WIDTH-1:0 ] row, col,
					output logic [ STATE_WIDTH-1:0 ] row_o, col_o,
					output logic [ STATE_WIDTH-1:0 ] obs,
					output logic signed [ REWARD_WIDTH-1:0 ] rew,
					output logic term,
					output logic trunc
				*/
				step_frozenlake_4x4(
					action,
					row, col,
					row_c, col_c,
					next_game_state_c[ STATE_WIDTH-1:0 ],
					Q_next_c,
					term_c,
					trunc_c
				);

				state_c = S_AFTER_STEP;
			end
			S_AFTER_STEP:
			begin
				if ( ~train_done )
				begin
					// for training; build Q bottom-up
					// read from Qtbl at computed next state
					//Qtbl_rd_addr_c = next_game_state_c;
					Qtbl_rd_addr = next_game_state_c;

					Qmax_is_next_c = 1'b1;

					state_Qmax_c = QMIN;
					action_c = LEFT;
					// to obtain Qmax in next state when updating reward,
					// reuse S_FIND_QMAX from exploit datapath, but since
					// we assert Qmax_is_next, it will return to S_MUL_GAMMA
					state_c = S_FIND_QMAX;
				end
				else
				begin
					cur_game_state_c = next_game_state;
					state_c = S_PREDICT_OUT;
				end
			end

			S_MUL_GAMMA:
			begin
				// Qmax from next state
				Q_tmp_c = GAMMA * state_Qmax;
				state_c = S_ADD_SUB;
			end
			S_ADD_SUB:
			begin
				Q_tmp_c = Q_next + DEQUANT( Q_tmp ) - Q_cur;
				state_c = S_MUL_ALPHA;
			end
			S_MUL_ALPHA:
			begin
				Q_tmp_c = ALPHA * Q_tmp;
				state_c = S_UPDATE_QCUR;
			end
			S_UPDATE_QCUR:
			begin
				Q_cur_c = Q_cur + DEQUANT( Q_tmp );
				Qtbl_din = Q_cur_c;
				Qtbl_wr_addr = cur_game_state;
				Qtbl_wr_en[ action ] = 1'b1;
				state_c = S_STEP_TAIL;
			end
			// end of training step
			S_STEP_TAIL:
			begin
				if ( term || trunc )
				begin
					cur_game_state_c = 'h0;
					row_c = 'h0;
					col_c = 'h0;
				end
				else
				begin
					cur_game_state_c = next_game_state;
				end

				step_c = step + 1'h1;
				if ( step_c == MAX_STEPS )
				begin
					train_done_c = 1'b1;
				end

				if ( ~train_done_c )
				begin
					state_c = S_GET_RAND;
				end
				else
				begin
					// enter initial prediction step
					cur_game_state_c = 'h0;
					row_c = 'h0;
					col_c = 'h0;
					term_c = 1'b0;
					trunc_c = 1'b0;
					state_c = S_EXPLOIT_GET_RAND;
				end
			end

			S_PREDICT_OUT:
			begin
				if ( ~pred_full )
				begin
					pred_wr_en = 1'b1;
					pred_out = { cur_game_state[ STATE_WIDTH-1:0 ], action, Q_cur };
					state_c = ( term || trunc )
						? S_DONE
						: S_EXPLOIT_GET_RAND;
				end
			end

			S_DONE:
			begin
				/*
				if ( rst )
				begin
					state_c = S_INIT;
				end
				*/
			end

			default:
			begin
			end

		endcase
	end

	always_ff @ ( posedge clk, posedge rst )
	begin
		if ( rst )
		begin
			state <= S_INIT;
			rand_reg <= 'h0;
			state_Qmax <= QMIN;
			choice <= 'h0;
			action <= LEFT;
			Qmax_action_idx <= 'h0;
			Qmax_is_next <= 1'b0;
			row <= 'h0;
			col <= 'h0;
			cur_game_state  <= 'h0;
			next_game_state <= 'h0;
			Q_cur  <= 'sh0;
			Q_next <= 'sh0;
			Q_tmp  <= 'sh0;
			//Qtbl_rd_addr <= 'h0;
			term  <= 1'b0;
			trunc <= 1'b0;

			train_done <= 1'b0;
		end
		else
		begin
			state <= state_c;
			rand_reg <= rand_c;
			state_Qmax <= state_Qmax_c;
			choice <= choice_c;
			action <= action_c;
			Qmax_action_idx <= Qmax_action_idx_c;
			Qmax_is_next <= Qmax_is_next_c;
			row <= row_c;
			col <= col_c;
			cur_game_state  <= cur_game_state_c;
			next_game_state <= next_game_state_c;
			Q_cur  <= Q_cur_c;
			Q_next <= Q_next_c;
			Q_tmp  <= Q_tmp_c;
			//Qtbl_rd_addr <= Qtbl_rd_addr_c;
			term  <= term_c;
			trunc <= trunc_c;

			train_done <= train_done_c;
		end
	end

endmodule: q_learner

