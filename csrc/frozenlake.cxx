
#include "frozenlake.h"

void
FrozenLake::step(
	const int action,
	int &row, int &col,
	int &next_state_idx, int &Q_next_i,
	bool &term, bool &trunc
)
{
	next_state_idx = 0;
	Q_next_i = 0;
	term = false;
	trunc = false;

	if ( action >= ACTION_CNT )
	{
		return;
	}
	switch ( static_cast<Action>( action ) )
	{
	case Action::LEFT:
		if ( col > 0 )     { --col; }
		break;

	case Action::RIGHT:
		if ( col < DIM-1 ) { ++col; }
		break;

	case Action::UP:
		if ( row > 0 )     { --row; }
		break;

	case Action::DOWN:
		if ( row < DIM-1 ) { ++row; }
		break;

	default:
		break;
	}

	next_state_idx = row * DIM + col;

	switch ( STATES[ next_state_idx ] )
	{
	case GameState::FROZEN:
		break;

	case GameState::HOLE:
		trunc = true;
		break;

	case GameState::GOAL:
		term = true;
		Q_next_i = 1;
		break;

	default:
		break;
	}

}

