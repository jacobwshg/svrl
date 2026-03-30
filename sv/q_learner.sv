
/*
 * 4x4 grid
 */

import globals_pkg::DWIDTH;
import globals_pkg::REWARD_WIDTH;

import frozenlake_pkg::DIM;
import frozenlake_pkg::WORLD_SIZE;
import frozenlake_pkg::ACTION_CNT;

import frozenlake_pkg::action_t;
import frozenlake_pkg::gamestate_t;
import frozenlake_pkg::GAMESTATES;

import frozenlake_pkg::DIM_WIDTH;
import frozenlake_pkg::ACTION_WIDTH;
import frozenlake_pkg::GAMESTATE_IDX_WIDTH;
import frozenlake_pkg::OUTWIDTH;

import quant_pkg::QUANT;
import quant_pkg::DEQUANT;

module q_learner 
#(
	parameter logic signed [ DWIDTH-1:0 ] ALPHA   = globals_pkg::ALPHA,
	parameter logic signed [ DWIDTH-1:0 ] GAMMA   = globals_pkg::GAMMA,
	parameter logic signed [ DWIDTH-1:0 ] EPSILON = globals_pkg::EPSILON,

	parameter int DWIDTH = globals_pkg::DWIDTH,
	parameter int REWARD_WIDTH = globals_pkg::REWARD_WIDTH,

	parameter int DIM        = frozenlake_pkg::DIM,
	parameter int WORLD_SIZE = frozenlake_pkg::WORLD_SIZE,
	parameter int ACTION_CNT = frozenlake_pkg::ACTION_CNT,
	parameter frozenlake_pkg::gamestate_t GAMESTATES [ 0:WORLD_SIZE-1 ] = 
		frozenlake_pkg::GAMESTATES
)
(
	input  logic clk,
	input  logic rst,
	input  logic [ DWIDTH-1:0 ] maxsteps_in,

	input  logic signed [ DWIDTH-1:0 ] rand_in,
	input  logic rand_empty,
	input  logic pred_full,
	
	output logic train_done,
	output logic done,
	output logic rand_rd_en,
	output logic pred_wr_en,
	output logic [ frozenlake_pkg::OUTWIDTH-1:0 ] pred_out
);

	localparam int DIM_WIDTH = frozenlake_pkg::DIM_WIDTH;
	localparam int GAMESTATE_IDX_WIDTH = frozenlake_pkg::GAMESTATE_IDX_WIDTH;
	localparam int ACTION_WIDTH = frozenlake_pkg::ACTION_WIDTH;
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
		S_EXPLOIT_CHOICE,
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
	} fsm_state_t;
	fsm_state_t fsm_state, fsm_state_c;

	frozenlake_pkg::action_t action, action_c;

	logic [ ACTION_WIDTH-1:0 ]
		Qmax_action_rd_addr, Qmax_action_wr_addr,
		Qmax_action_in, Qmax_action_out;
	logic Qmax_action_wr_en;

	bram #(
		.BRAM_ADDR_WIDTH ( ACTION_WIDTH ),
		.BRAM_DATA_WIDTH ( ACTION_WIDTH )
	) Qmax_actions_buf (
		.clock   ( clk ),
		.rd_addr ( Qmax_action_rd_addr ),
		.wr_addr ( Qmax_action_wr_addr ),
		.wr_en   ( Qmax_action_wr_en ),
		.din     ( Qmax_action_in ),
		.dout    ( Qmax_action_out )
	);

	logic [ DWIDTH-1:0 ] maxsteps_reg, step, step_c;

	logic train_done_c;

	logic [ ACTION_WIDTH:0 ] Qmax_action_idx, Qmax_action_idx_c;

	logic [ DWIDTH-1:0 ] rand_reg, rand_c;

	logic signed [ REWARD_WIDTH-1:0 ] gamestate_Qmax, gamestate_Qmax_c;

	logic Qmax_is_next, Qmax_is_next_c;

	logic [ DWIDTH-1:0 ] choice, choice_c;

	logic [ DIM_WIDTH-1:0 ]
		row, row_c,
		col, col_c;

	logic [ GAMESTATE_IDX_WIDTH-1:0 ]
		cur_gamestate_idx,  cur_gamestate_idx_c,
		next_gamestate_idx, next_gamestate_idx_c;
	logic signed [ REWARD_WIDTH-1:0 ]
		Q_cur, Q_cur_c,
		Q_next, Q_next_c,
		Q_tmp, Q_tmp_c;

	// from GAMESTATES ROM
	logic [ GAMESTATE_IDX_WIDTH-1:0 ] gamestate_rd_addr;
	frozenlake_pkg::gamestate_t gamestate_out;

	logic
		term, term_c,
		trunc, trunc_c;

	logic [ GAMESTATE_IDX_WIDTH-1:0 ]
		Qtbl_rd_addr, 
		//Qtbl_rd_addr_c,
		Qtbl_wr_addr;
	logic [ ACTION_CNT-1:0 ] Qtbl_wr_en;
	logic signed [ REWARD_WIDTH-1:0 ] Qtbl_din;
	logic signed [ ACTION_CNT-1:0 ] [ REWARD_WIDTH-1:0 ] Qtbl_dout;

	bram_block #(
		.BRAM_ADDR_WIDTH ( GAMESTATE_IDX_WIDTH ),
		.BANK_DATA_WIDTH ( REWARD_WIDTH ),
		.BANK_CNT        ( ACTION_CNT ),
		.BRAM_DATA_WIDTH ( REWARD_WIDTH * ACTION_CNT )
	) Qtbl (
		.clock  ( clk ),
		//.rd_addr( Qtbl_rd_addr_c ),
		.rd_addr ( Qtbl_rd_addr ),
		.wr_addr ( Qtbl_wr_addr ),
		.wr_en   ( Qtbl_wr_en ),
		.din     ( Qtbl_din ),
		.dout    ( Qtbl_dout )
	);

	assign gamestate_rd_addr = next_gamestate_idx_c;
	always_ff @ ( posedge clk )
	begin: rd_gamestate
		gamestate_out <= GAMESTATES[ gamestate_rd_addr ];
	end: rd_gamestate

	assign done = 1'( fsm_state == S_DONE );

	always_comb
	begin
		step_c = step;
		train_done_c = train_done;

		rand_rd_en = 1'b0;
		pred_wr_en = 1'b0;
		pred_out = 'hX;

		fsm_state_c = fsm_state;
		rand_c = rand_reg;
		gamestate_Qmax_c = gamestate_Qmax;
		choice_c = choice;
		action_c = action;

		Qmax_is_next_c = Qmax_is_next;

		Qmax_action_rd_addr = 'h0;
		Qmax_action_wr_addr = 'hX;
		Qmax_action_in = 'hX;
		Qmax_action_wr_en = 1'b0;
		Qmax_action_idx_c = Qmax_action_idx;

		{ row_c, col_c } = { row, col };

		cur_gamestate_idx_c  = cur_gamestate_idx;
		next_gamestate_idx_c = next_gamestate_idx;
		Q_cur_c  = Q_cur;
		Q_next_c = Q_next;
		Q_tmp_c  = Q_tmp;

		// Normally, read from Q-table at current game state
		// unless when updating reward
		//
		//Qtbl_rd_addr_c = Qtbl_rd_addr;
		Qtbl_rd_addr = cur_gamestate_idx;
		Qtbl_wr_addr = cur_gamestate_idx;
		Qtbl_wr_en = 'b0;
		Qtbl_din = 'shX;

		term_c  = term;
		trunc_c = trunc;

		// only written to downstream in S_PREDICT_OUT
		pred_out = { action, next_gamestate_idx, Q_next };

		case ( fsm_state )
			S_INIT:
			begin
				// initialize rewards to 0
				//Qtbl_wr_addr = cur_gamestate_idx;
				Qtbl_din = 'sh0;
				Qtbl_wr_en = ~'b0;
				if ( cur_gamestate_idx == WORLD_SIZE-1 )
				begin
					// At next clk edge, all state rows in Q-table will have
					// been zero-initialized
					cur_gamestate_idx_c = 'h0;
					fsm_state_c = S_GET_RAND;
				end
				else
				begin
					cur_gamestate_idx_c = cur_gamestate_idx + 1'h1;
				end
			end
			S_GET_RAND:
			begin
				if ( ~rand_empty )
				begin
					rand_rd_en = 1'b1;
					rand_c = rand_in;

					$display( "\n\n@%0t step %0d, gamestate idx %0d, got rand %08h", $time, step, cur_gamestate_idx, rand_c );

					fsm_state_c = ( rand_in < EPSILON )
						? S_EXPLORE_GET_RAND
						: S_EXPLOIT_GET_RAND;
				end
				//Qtbl_rd_addr_c = cur_gamestate_idx;
			end

			// explore
			S_EXPLORE_GET_RAND:
			begin
				if ( ~rand_empty )
				begin
					rand_rd_en = 1'b1;
					rand_c = rand_in;

					$display( "@%0t \texplore got rand %08h", $time, rand_c );

					fsm_state_c = S_EXPLORE_CHOICE;
				end
			end
			S_EXPLORE_CHOICE:
			begin
				// assume ACTION_CNT is power of 2
				choice_c = rand_reg << ACTION_WIDTH;
				fsm_state_c = S_EXPLORE_ACTION;
			end
			S_EXPLORE_ACTION:
			begin
				// rand is quantized, so dequantize
				action_c = quant_pkg::DEQUANT( choice );

				$display( "@%0t \texplore quantized choice: %08h, action: %0d", $time, choice, action_c );

				fsm_state_c = S_TAKE_STEP;
			end

			// exploit
			S_EXPLOIT_GET_RAND:
			begin
				if ( ~rand_empty )
				begin
					rand_rd_en = 1'b1;
					rand_c = rand_in;

					$display( "@%0t \texploit got rand %08h", $time, rand_c );

					Qmax_is_next_c = 1'b0;

					Qmax_action_idx_c = 'h0;
					gamestate_Qmax_c = QMIN;
					fsm_state_c = S_FIND_QMAX;
				end
			end
			S_FIND_QMAX:
			begin
				// iterate over all actions with Qmax_action_idx
				// 
				// if prev cycle's state was S_EXPLOIT_GET_RAND,
				// we are reading from current gamestate's rewards;
				// if S_AFTER_STEP, we are reading from next gamestate's rewards
				//
				/*
				$display(
					"@%0t \texploit Qtbl_dout: %0h, action: %0d, reward Qtbl_dout[ Qmax_action_idx ]: %08h, gamestate_Qmax: %08h",
					$time, Qtbl_dout, Qmax_action_idx, Qtbl_dout[ Qmax_action_idx ], gamestate_Qmax
				);
				*/
				if ( $signed( Qtbl_dout[ Qmax_action_idx ] ) > $signed( gamestate_Qmax ) )
				begin
					gamestate_Qmax_c = Qtbl_dout[ Qmax_action_idx ];
				end

				// if still finding Q_max in next game state 
				// ( updating reward, not exploiting ),
				// hold read addr at next state
				if ( Qmax_is_next )
				begin
					Qtbl_rd_addr = next_gamestate_idx;
				end

				// all action rewards seen
				if ( Qmax_action_idx == ACTION_CNT-1 ) //DOWN
				begin

					if ( Qmax_is_next )
						$display( "@%0t \tnext gamestate %0d Qmax: %08h", $time, Qtbl_rd_addr, gamestate_Qmax_c );
					else
						$display( "@%0t \texploit state %0d Qmax: %08h", $time, Qtbl_rd_addr, gamestate_Qmax_c );

					Qmax_action_idx_c = 'h0;

					if ( Qmax_is_next )
					begin
						// preserve action set in S_EXPLOIT_ACTION
						fsm_state_c = S_MUL_GAMMA;
					end
					else
					begin
						// reset action for iterating in below state
						action_c = 'h0;
						Qmax_action_idx_c = 'h0;
						fsm_state_c = S_COUNT_QMAX_ACTIONS;
					end

				end
				else
				begin
					Qmax_action_idx_c = Qmax_action_idx + 1'h1;
				end
			end
			S_COUNT_QMAX_ACTIONS:
			begin
				// iterate over all actions with `action`, adding actions sharing Qmax 
				// to buffer and incrementing Qmax_action_idx _as needed_ 
				// (whenever action has shared Qmax).
				//
				// This also makes Qmax_action_idx come out as the count for
				// number of actions sharing Qmax (1 above highest
				// Qmax-sharing action idx). 
				//
				// in any cycle, Qmax_action_idx <= action (equal if 
				// all actions share Qmax)
				//
				if ( Qtbl_dout[ action ] == gamestate_Qmax )
				begin
					//$display( "@%0t \texploit action %0d sharing Qmax", $time, action );
					Qmax_action_wr_addr = Qmax_action_idx;
					Qmax_action_in = action[ ACTION_WIDTH-1:0 ];
					Qmax_action_wr_en = 1'b1;
					Qmax_action_idx_c = Qmax_action_idx + 1'h1;
				end

				// finished comparing all action rewards with Qmax found in
				// above state
				if ( action == ACTION_CNT-1 ) //DOWN
				begin
					// resetting action is not strictly needed, since it will
					// be set in S_EXPLOIT_ACTION soon
					//action_c = 'h0;
					fsm_state_c = S_EXPLOIT_CHOICE;
				end
				else
				begin
					action_c = action + 1'h1;
				end
			end
			S_EXPLOIT_CHOICE:
			begin
				//$display( "@%0t \texploit rand: %08h, %0d actions sharing Qmax", $time, rand_reg, Qmax_action_idx );
				choice_c = ( rand_reg * Qmax_action_idx );
				fsm_state_c = S_EXPLOIT_ACTION_SETUP;
			end
			// set up Qmax_actions_buf BRAM read
			S_EXPLOIT_ACTION_SETUP:
			begin
				Qmax_action_rd_addr = quant_pkg::DEQUANT( choice );
				$display( "@%0t \texploit quantized choice: %08h, dequant: %0d", $time, choice, Qmax_action_rd_addr );
				fsm_state_c = S_EXPLOIT_ACTION;
			end
			S_EXPLOIT_ACTION:
			begin
				action_c = Qmax_action_out;
				$display( "@%0t \texploit action: %0d", $time, action_c );
				fsm_state_c = S_TAKE_STEP;
			end

			S_TAKE_STEP:
			begin
				// cache current reward in this state, despite doing it in
				// S_MUL_GAMMA ( initial state in update computation ) has
				// better locality; 
				// this is because when going from S_FIND_QMAX to S_MUL_GAMMA,
				// Qtbl rd addr is stil the next gamestate, and we would be 
				// reading an invalid reward in S_MUL_GAMMA
				//
				Q_cur_c = Qtbl_dout[ action ];

				// take step to obtain updated row, col and game state idx;
				// reward and flags are not updated yet
				frozenlake_pkg::step(
					action,
					row, col,
					row_c, col_c,
					next_gamestate_idx_c
				);

				fsm_state_c = S_AFTER_STEP;
			end
			// between these states, GAMESTATES is addressed by
			// updated next_gamestate_idx_c
			S_AFTER_STEP:
			begin

				frozenlake_pkg::eval_gamestate(
					gamestate_out,
					term_c, trunc_c, Q_next_c
				);

				if ( train_done )
				begin
					// for prediction: no current reward update needed
					fsm_state_c = S_PREDICT_OUT;
				end
				else
				begin
					// for training; build new Q_cur bottom-up
					Q_next_c = quant_pkg::QUANT( Q_next_c );

					// read from Qtbl at computed next gamestate
					//Qtbl_rd_addr_c = next_gamestate_idx;
					Qtbl_rd_addr = next_gamestate_idx;
					// FIXED: bug: resetting action will lose the chosen action
					// in this gamestate; use Qmax_action_idx to iterate over
					// next gamestate actions instead.
					//action_c = 'h0;
					Qmax_action_idx_c = 'h0;
					gamestate_Qmax_c = QMIN;

					// to obtain Qmax in next gamestate when updating Q_cur,
					// reuse S_FIND_QMAX from exploit datapath, but since
					// we assert Qmax_is_next, it will return to S_MUL_GAMMA
					//
					Qmax_is_next_c = 1'b1;
					fsm_state_c = S_FIND_QMAX;
				end
			end

			S_MUL_GAMMA:
			begin
				// Qmax is from *next* game state ( S_AFTER_STEP (~train_done) 
				// -> S_FIND_QMAX -> S_MUL_GAMMA )
				Q_tmp_c = GAMMA * gamestate_Qmax;
				fsm_state_c = S_ADD_SUB;
			end
			S_ADD_SUB:
			begin
				Q_tmp_c = Q_next - Q_cur;
				Q_tmp_c = Q_tmp_c + quant_pkg::DEQUANT( Q_tmp ); 
				fsm_state_c = S_MUL_ALPHA;
			end
			S_MUL_ALPHA:
			begin
				Q_tmp_c = ALPHA * Q_tmp;
				fsm_state_c = S_UPDATE_QCUR;
			end
			S_UPDATE_QCUR:
			begin
				// both alpha and previous Q_tmp are quantized;
				// dequantize to get once-quantized product
				Q_cur_c = Q_cur + quant_pkg::DEQUANT( Q_tmp );

				$display( "@%0t \tstep %0d final Q_cur: %08h", $time, step, Q_cur_c );

				Qtbl_din = Q_cur_c;
				//Qtbl_wr_addr = cur_gamestate_idx;
				Qtbl_wr_en[ action ] = 1'b1;
				fsm_state_c = S_STEP_TAIL;
			end
			// end of training step
			S_STEP_TAIL:
			begin
				// flags set in S_AFTER_STEP
				// if fell into hole or reached goal, reset game state
				if ( term || trunc )
				begin
					cur_gamestate_idx_c = 'h0;
					row_c = 'h0;
					col_c = 'h0;
				end
				else
				begin
					cur_gamestate_idx_c = next_gamestate_idx;
					// updated row and col had been registered at the end of
					// the prev S_TAKE_STEP cycle, so no update in this state
				end

				step_c = step + 1'h1;
				if ( step_c == maxsteps_reg )
				begin
					train_done_c = 1'b1;
				end

				if ( ~train_done_c )
				begin
					fsm_state_c = S_GET_RAND;
				end
				else
				begin
					// enter initial prediction step
					cur_gamestate_idx_c = 'h0;
					row_c = 'h0;
					col_c = 'h0;
					term_c  = 1'b0;
					trunc_c = 1'b0;
					fsm_state_c = S_EXPLOIT_GET_RAND;
				end
			end

			S_PREDICT_OUT:
			begin
				if ( ~pred_full )
				begin
					// next_gamestate_idx and Q_next were respectively updated 
					// on the clk edge out of S_TAKE_STEP and S_AFTER_STEP

					//pred_out = { action, next_gamestate_idx, Q_next };

					$display(
						"@%0t Predicted action %0d, next gamestate idx %0d, reward %0d",
						$time, action, next_gamestate_idx, Q_next
					);

					pred_wr_en = 1'b1;

					cur_gamestate_idx_c = next_gamestate_idx;
					fsm_state_c = ( term || trunc )
						? S_DONE
						: S_EXPLOIT_GET_RAND;
				end
			end

			S_DONE:
			begin
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
			$display(
				"q_learner .ALPHA = %08h, .GAMMA = %08h, .EPSILON = %08h",
				ALPHA, GAMMA, EPSILON
			);

			maxsteps_reg <= maxsteps_in;
			step <= 'h0;
			train_done <= 1'b0;

			fsm_state <= S_INIT;
			rand_reg <= 'h0;
			gamestate_Qmax <= QMIN;
			choice <= 'h0;
			action <= 'h0; //LEFT;
			Qmax_action_idx <= 'h0;
			Qmax_is_next <= 1'b0;
			row <= 'h0;
			col <= 'h0;
			cur_gamestate_idx  <= 'h0;
			next_gamestate_idx <= 'h0;
			Q_cur  <= 'sh0;
			Q_next <= 'sh0;
			Q_tmp  <= 'sh0;
			//Qtbl_rd_addr <= 'h0;
			term  <= 1'b0;
			trunc <= 1'b0;

		end
		else
		begin
			step <= step_c; 
			train_done <= train_done_c;

			fsm_state <= fsm_state_c;
			rand_reg <= rand_c;
			gamestate_Qmax <= gamestate_Qmax_c;
			choice <= choice_c;
			action <= action_c;
			Qmax_action_idx <= Qmax_action_idx_c;
			Qmax_is_next <= Qmax_is_next_c;
			row <= row_c;
			col <= col_c;
			cur_gamestate_idx  <= cur_gamestate_idx_c;
			next_gamestate_idx <= next_gamestate_idx_c;
			Q_cur  <= Q_cur_c;
			Q_next <= Q_next_c;
			Q_tmp  <= Q_tmp_c;
			//Qtbl_rd_addr <= Qtbl_rd_addr_c;
			term  <= term_c;
			trunc <= trunc_c;
		end
	end

endmodule: q_learner

