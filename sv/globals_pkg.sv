
package globals_pkg;

	localparam int FIFO_DEPTH = 32;

	localparam int DWIDTH = 32;
	localparam int REWARD_WIDTH = DWIDTH;

	localparam logic signed [ DWIDTH-1:0 ] ALPHA   = 32'h2000; // 0.5
	localparam logic signed [ DWIDTH-1:0 ] GAMMA   = 32'h2ccc; // 0.7
	localparam logic signed [ DWIDTH-1:0 ] EPSILON = 32'hccc;  // 0.2

	localparam int MAX_STEPS = 3000;

endpackage: globals_pkg

