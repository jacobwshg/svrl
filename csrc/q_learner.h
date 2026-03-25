
#ifndef Q_LEARNER_H
#define Q_LEARNER_H

#include "frozenlake.h"

class QLearner
{
private:
	static inline const std::string RAND_PATH { "../sim/uniforms-f.txt" };
	static inline constexpr int RAND_CNT { 1000 };

	std::vector< std::vector<int> > Qtbl {};

	std::vector<float> rand_mem {};
	std::vector<int> rand_q_mem {};
	int rand_cnt { 0 };
	int rand_idx { 0 };

public:
	float alpha   { 0.5f };
	float gamma   { 0.5f };
	float epsilon { 0.2f };

	int max_steps {};
	int state_cnt { FrozenLake::STATE_CNT };
	int action_cnt { FrozenLake::ACTION_CNT };

	QLearner(
		float alpha,
		float gamma,
		float epsilon,
		int max_steps,
		int state_cnt, 
		int action_cnt 
	);

	void get_rand( float &rand, int &rand_q );

	void train( void );

	void predict( void ) const;

};

#endif

