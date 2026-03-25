
#include "quant.h"
#include "q_learner.h"
#include <cstdio>



QLearner::QLearner(
	float alpha,
	float gamma,
	float epsilon,
	int max_steps,
	int state_cnt,
	int action_cnt
):
	alpha { alpha }, gamma { gamma }, epsilon { epsilon },
	max_steps { max_steps }, state_cnt { state_cnt } action_cnt { action_cnt }
{
	// initialize Q-table
	this->Qtbl.resize( this->state_cnt, std::vector<int>( this->action_cnt, 0 ) );

	// load randoms
	this->rand_mem.reserve( QLearner::RAND_CNT );
	this->rand_q_mem.reserve( QLearner::RAND_CNT );

	std::ifstream rand_ifs { QLearner::RAND_PATH };
	float rand {};
	while ( rand_ifs >> rand )
	{
		this->rand_mem.emplace_back( rand );
		this->rand_q_mem.emplace_back( Quant::QUANTIZE_F( rand ) );
	}

	this->rand_cnt = static_cast<int>( rand_mem.size() );
}

void
QLearner::get_rand( float &rand, int &rand_q )
{
	if ( this->rand_idx == this->rand_cnt )
	{
		this->rand_idx = 0;
	}
	rand   = this->rand_mem[ this->rand_idx ];
	rand_q = this->rand_q_mem[ this->rand_idx ];
	++this->rand_idx;
}

void
QLearner::train( void )
{
	const int alpha_q { Quant::QUANTIZE_F( this->alpha ) };
	const int gamma_q { Quant::QUANTIZE_F( this->epsilon ) };
	const int epsilon_q { Quant::QUANTIZE_F( this->gamma ) };

	std::vector<int> Qmax_actions_buf( this->action_cnt );

	int current_state { 0 };
	int row { 0 }, int col { 0 };

	for ( int step = 0; step < this->max_steps; ++step )
	{
		float rand {};
		int rand_q {};
		this->get_rand( rand, rand_q );
		std::printf( "\n\nStep %d got rand %f ( %08x )\n", step, rand, rand_q );

		const std::vector<int> &Q_state { Qtbl[ current_state ] };
		int action {};

		if ( rand_q < epsilon_q )
		{
			// explore
			rand_q = this->get_rand( rand, rand_q );
			std::printf( "\tExplore: got new rand %f ( %08x )\n", rand, rand_q );

			const int choice { Quant::DEQUANTIZE_I( rand_q * this->action_cnt ) };
			std::printf(
				"\tExplore: choice %d, reference choice (no quant): %d \n",
				choice, static_cast<int>( rand * this->action_cnt )
			);

			action = choice;
			std::printf( "\tExplore: action %d\n", action );
		}
		else
		{
			// exploit
			rand_q = this->get_rand( rand, rand_q );
			std::printf( "\tExploit: got new rand %f ( %08x )\n", rand, rand_q );
			const std::vector<int> &Q_state { Qtbl[ current_state ] };

			//////////
			int state_Qmax { -( 1<<30 ) };
			for ( const int Q : Q_state )
			{
				if ( Q > state_Qmax )
				{
					state_Qmax = Q;
				}
			}
			std::printf( "\tExploit: current state %d, Qmax %08x\n", current_state, state_Qmax );

			int Qmax_action_idx { 0 };
			int action { 0 };
			for ( const int Q : Q_state )
			{
				if ( Q == state_Qmax )
				{
					std::printf(
						"\tExploit: action %d sharing Qmax\n", action
					);
					Qmax_actions_buf[ Qmax_action_idx ] = action;
					++Qmax_action_idx;
				}
				++action;
			}
			std::printf( "\tExploit: %d actions sharing Qmax", Qmax_action_idx );

			const int choice { Quant::DEQUANTIZE_I( rand_q * Qmax_action_idx ) };
			std::printf(
				"\tExploit: choice %d, reference choice (no quant)%d \n",
				choice, static_cast<int>( rand * Qmax_action_idx )
			);
			///////

			action = Qmax_actions_buf[ choice ];
			std::printf( "\tExploit: action %d\n", action );

		}

		int next_state {};
		int Q_next_i {};
		bool term {}, trunc {};

		FrozenLake::step(
			action,
			row, col,
			next_state, Q_next_i,
			term, trunc
		);
		const int Q_next { Quant::QUANTIZE_I( Q_next_i ) };
		std::printf(
			"\tAfter step: row %d, col %d, next state %d, next reward %d ( quantized %08x ), term %d, trunc %d",
			row, col, next_state, Q_next_i, Q_next, term, trunc
		);
		
		const std::vector<int> &Q_next_state { Qtbl[ next_state ] };
		int next_state_Qmax { -( 1<<30 ) };
		for ( const int Q: Q_next_state )
		{
			if ( Q > next_state_Qmax ) { next_state_Qmax = Q };
		}
		std::printf( "\tNext state max reward: %08x\n", next_state_Qmax );

		int Q_cur { Q_state[ action ] };
		std::printf( "\tCurrent reward: %08x\n", Q_cur );

		const int Q_cur { Q_state[ action ] };
		std::printf( "\tCurrent reward: %08x\n", Q_cur );

		int Q_tmp { gamma_q * next_state_Qmax };
		std::printf( "\tQ_tmp = gamma_q * next_state_Qmax = %08x\n", Q_tmp );

		Q_tmp = Q_next + Quant::DEQUANTIZE_I( Q_tmp ) - Q_cur;
		std::printf( "\tQ_next + DQ( Q_tmp ) - Q_cur = %08x\n", Q_tmp );

		Q_tmp *= alpha_q;
		std::printf( "\tQ_tmp *= alpha_q = %08x \n", Q_tmp );

		Q_cur += Quant::DEQUANTIZE_I( Q_tmp );
		std::printf( "\tQ_cur += DQ( Q_tmp ) = %08x\n", Q_cur );

		// write back current reward
		Qtbl[ current_state ][ action ] = Q_cur;

		if ( term || trunc )
		{
			row = col = 0;
			current_state = 0;
		}
		else
		{
			current_state = next_state;
		}
	}
}

