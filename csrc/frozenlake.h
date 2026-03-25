
#ifndef FROZENLAKE_H
#define FROZENLAKE_H

namespace FrozenLake
{
	constexpr int DIM { 4 };
	constexpr int STATE_CNT { DIM * DIM };
	constexpr int ACTION_CNT { 4 };

	enum class Action: int
	{
		LEFT  = 0,
		RIGHT = 1,
		UP    = 2,
		DOWN  = 3,
	};

	void
	step(
		const int action,
		int &row, int &col,
		int &next_state, int &Q_next,
		bool &term, bool &trunc
	);
}

#endif


