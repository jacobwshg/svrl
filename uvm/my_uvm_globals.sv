`ifndef __GLOBALS__
`define __GLOBALS__

// UVM Globals
localparam int CLOCK_PERIOD = 10;

localparam string INFILE_RAND_F = "../sim/uniforms-f.txt";
localparam string INFILE_RAND_Q = "../sim/uniforms-q.txt";
localparam int RAND_CNT = 1000;

localparam int DWIDTH = 32;
localparam int REWARD_WIDTH = DWIDTH;

localparam int FRAC_WIDTH = 14;
localparam logic signed [ DWIDTH-1:0 ] ALPHA   = 32'h2000; // 0.5
localparam logic signed [ DWIDTH-1:0 ] GAMMA   = 32'h2ccc; // 0.7
localparam logic signed [ DWIDTH-1:0 ] EPSILON = 32'hccc;  // 0.2
localparam int MAX_STEPS = 3000;

localparam int DIM = 4;
localparam int WORLD_SIZE = DIM ** 2;
localparam int GAMESTATE_IDX_WIDTH  = $clog2( WORLD_SIZE );

localparam int ACTION_CNT = 4;
localparam int ACTION_WIDTH = $clog2( ACTION_CNT );

`endif

