
#ifndef QUANT_H
#define QUANT_H

namespace Quant
{
	static constexpr int FRAC_WIDTH { 14 };
	static constexpr int Q_STEP { 1 << FRAC_WIDTH };

	inline int
	QUANTIZE_F( const float f )
	{
		return static_cast<int>( f * static_cast<float>( Q_STEP ) );
	}

	inline int
	QUANTIZE_I( const int i )
	{
		return i << FRAC_WIDTH;
	}

	inline float
	DEQUANTIZE_F( const int q )
	{
		return static_cast<float>( q ) / static_cast<float>( Q_STEP );
	}

	inline int
	DEQUANTIZE_I( const int q )
	{
		int dq { q >> FRAC_WIDTH };
		if ( (q < 0) && ( q & ( Q_STEP-1 ) )  )
		{
			++dq;
		}
		return dq;
	}

}

#endif

