
#include "frozenlake.h"

void
FrozenLake::step(
	const int action,
	int &row, int &col,
	int &next_state, int &Q_next,
	bool &term, bool &trunc
)
{
	next_state = 0;
	Q_next = 0;
	term = false;
	trunc = false;

	if ( action >= ACTION_CNT )
	{
		return;
	}
	switch ( static_cast<Action>( action ) )
	{
	case LEFT:
		if ( col > 0 )
		{
			--col;
		}
		break;

	case RIGHT:
		if ( col < DIM-1 )
		{
			++col;
		}
		break;

	case UP:
		if ( row > 0 )
		{
			--row;
		}
		break;

	case DOWN:
		if ( row < DIM-1 )
		{
			++row;
		}
		break;

	default:
		break;
	}

	next_state = row * DIM + col;

	switch ( row )
	{
	case 1:
		if ( col==1 || col==3 )
		{
			trunc = true;
		}
		break;
	case 2:
		if ( col==3 )
		{
			trunc = true;
		}
		break;
	case 3:
		if ( col==0 )
		{
			trunc = true;
		}
		else if ( col==3 )
		{
			term = true;
			Q_next = 1;
		}
		break;
	}
	default:
		break;
}

