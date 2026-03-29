
package quant_pkg;

	import globals_pkg::*;

	localparam int FRAC_WIDTH = 14;
	localparam int Q_STEP = 1<<FRAC_WIDTH;

	function automatic logic signed [ DWIDTH-1:0 ]
	QUANT( input logic signed [ DWIDTH-1:0 ] x );

		return $signed( x << FRAC_WIDTH );

	endfunction

	function automatic logic signed [ DWIDTH-1:0 ]
	DEQUANT( input logic signed [ DWIDTH-1:0 ] x );

		logic signed [ DWIDTH-1:0 ] dq = $signed( x ) >>> FRAC_WIDTH;
		// add 1 if x both is negative and 
		// has 1 in the fractional bits
		if ( x[ DWIDTH-1 ] && ( | x[ FRAC_WIDTH-1:0 ] ) )
		begin
			dq = dq + 1'h1;
		end

		return dq;

	endfunction

endpackage: quant_pkg

