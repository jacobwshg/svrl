

import uvm_pkg::*;

interface my_uvm_if;
	logic clk;
	logic rst;
	logic [ DWIDTH-1:0 ] maxsteps_in,

	logic [ DWIDTH-1:0 ] in_din;
	logic in_wr_en;
	logic in_full;

	logic [ ACTION_WIDTH + GAMESTATE_IDX_WIDTH + REWARD_WIDTH-1:0 ]
		out_dout;
	logic out_rd_en;
	logic out_empty;

	logic train_done;
	logic done;

endinterface: my_uvm_if

