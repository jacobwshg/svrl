
#ifndef FROZENLAKE_H
#define FROZENLAKE_H

#include <array>

namespace FrozenLake
{
	constexpr int DIM { 8 };
	constexpr int WORLD_SIZE { DIM * DIM };
	constexpr int ACTION_CNT { 4 };

	enum class GameState: int
	{
		FROZEN = 0x0,
		HOLE   = 0x1,
		GOAL   = 0x2,
	};

	static constexpr std::array< GameState, WORLD_SIZE > STATES
	{
		GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN,
		GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN,

		GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::HOLE,   GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN,
		GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::HOLE,   GameState::FROZEN, GameState::FROZEN,

		GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::HOLE,   GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::FROZEN,
		GameState::FROZEN, GameState::HOLE,   GameState::HOLE,   GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::HOLE,   GameState::FROZEN,

		GameState::FROZEN, GameState::HOLE,   GameState::FROZEN, GameState::FROZEN, GameState::HOLE,   GameState::FROZEN, GameState::HOLE,   GameState::FROZEN,
		GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::HOLE,   GameState::FROZEN, GameState::FROZEN, GameState::FROZEN, GameState::GOAL,
	};

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
		int &next_state, int &Q_next_i,
		bool &term, bool &trunc
	);

}

#endif

