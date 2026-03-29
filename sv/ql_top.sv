
import globals_pkg::FIFO_DEPTH;
import globals_pkg::DWIDTH;
import globals_pkg::REWARD_WIDTH;
import globals_pkg::ALPHA;
import globals_pkg::GAMMA;
import globals_pkg::EPSILON;

import frozenlake_pkg::DIM;
import frozenlake_pkg::WORLD_SIZE;
import frozenlake_pkg::ACTION_CNT;
import frozenlake_pkg::GAMESTATES;
import frozenlake_pkg::ACTION_WIDTH;
import frozenlake_pkg::GAMESTATE_IDX_WIDTH;
import frozenlake_pkg::OUTWIDTH;

module ql_top
#(
	parameter int FIFO_DEPTH = globals_pkg::FIFO_DEPTH,
	parameter int DWIDTH     = globals_pkg::DWIDTH,
	parameter int OUTWIDTH   = frozenlake_pkg::OUTWIDTH
)
(
	input  logic clk, rst,
	input  logic [ DWIDTH-1:0 ] maxsteps_in,

	input  logic signed [ DWIDTH-1:0 ] in_din,
	input  logic in_wr_en,
	input  logic out_rd_en,

	output logic in_full,
	output logic [ OUTWIDTH-1:0 ] out_dout,
	output logic out_empty,

	output logic train_done, done
);

	logic signed [ globals_pkg::DWIDTH-1:0 ] in_dout;
	logic in_rd_en, in_empty;

	logic [ OUTWIDTH-1:0 ] out_din;
	logic out_wr_en, out_full;

	fifo #(
		.FIFO_DATA_WIDTH  ( DWIDTH ),
		.FIFO_BUFFER_SIZE ( FIFO_DEPTH )
	) fifo_in (
		.reset  ( rst ),
		.wr_clk ( clk ),
		.wr_en  ( in_wr_en ),
		.din    ( in_din ),
		.full   ( in_full ),
		.rd_clk ( clk ),
		.rd_en  ( in_rd_en ),
		.dout   ( in_dout ),
		.empty  ( in_empty )
	);

	q_learner #(
		.DWIDTH ( globals_pkg::DWIDTH ),
		.REWARD_WIDTH ( globals_pkg::REWARD_WIDTH ),

		.DIM        ( frozenlake_pkg::DIM ),
		.WORLD_SIZE ( frozenlake_pkg::WORLD_SIZE ),
		.ACTION_CNT ( frozenlake_pkg::ACTION_CNT ),
		.GAMESTATES ( frozenlake_pkg::GAMESTATES ),

		.ALPHA   ( globals_pkg::ALPHA ),
		.GAMMA   ( globals_pkg::GAMMA ),
		.EPSILON ( globals_pkg::EPSILON )
	) ql (
		.clk ( clk ), .rst ( rst ), .maxsteps_in ( maxsteps_in ),
		.rand_in ( in_dout ), .rand_empty ( in_empty ),
		.pred_full ( out_full ),

		.train_done ( train_done ), .done( done ),
		.rand_rd_en ( in_rd_en ),
		.pred_wr_en ( out_wr_en ), .pred_out ( out_din )
	);

	fifo #(
		.FIFO_DATA_WIDTH  ( OUTWIDTH ),
		.FIFO_BUFFER_SIZE ( FIFO_DEPTH )
	) fifo_out (
		.reset  ( rst ),
		.wr_clk ( clk ),
		.wr_en  ( out_wr_en ),
		.din    ( out_din ),
		.full   ( out_full ),
		.rd_clk ( clk ),
		.rd_en  ( out_rd_en ),
		.dout   ( out_dout ),
		.empty  ( out_empty )
	);

endmodule: ql_top

