
#include "q_learner.h"
#include "frozenlake.h"
#include <vector>
#include <cstdio>

int
main()
{
	const float
		alpha_f   { 0.01f },
		gamma_f   { 0.999f },
		epsilon_f { 1.0f },
		decay_f   { 0.0001f },
		eps_min_f { 0.001f }
		;
	const int max_steps { 50000 };

	QLearner ql(
		alpha_f, gamma_f, epsilon_f,
		decay_f, eps_min_f,

		max_steps,
		FrozenLake::WORLD_SIZE,
		FrozenLake::ACTION_CNT
	);

	ql.train();
	std::printf( "\n" );

	ql.print_Qtbl();
	std::printf( "\n" );

	ql.predict();
	std::printf( "\n" );

	int ipred { -1 };
	for ( const int action: ql.pred_actions )
	{
		++ipred;
		const int state_idx { ql.pred_state_idxs[ ipred ] };
		const int Q_i       { ql.pred_rewards_i[ ipred ] };
		std::printf(
			"Predicted action %d, state idx %d, reward (no quant) %d \n",
			action, state_idx, Q_i
		);
	}

	std::printf( "\n" );

}

