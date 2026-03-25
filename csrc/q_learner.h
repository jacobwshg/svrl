
#ifndef Q_LEARNER_H
#define Q_LEARNER_H

#include "frozenlake.h"

class QLearner
{
private:
	static inline const std::string RAND_PATH { "../sim/uniforms-f.txt" };
	static inline constexpr int RAND_CNT { 1000 };

	// only store quantized rewards
	std::vector< std::vector<int> > Qtbl {};

	std::vector<float> rand_f_mem {};
	std::vector<int>   rand_q_mem {};
	int rand_cnt { 0 };
	int rand_idx { 0 };

public:
	float alpha_f   { 0.5f };
	float gamma_f   { 0.5f };
	float epsilon_f { 0.2f };

	int alpha_q   {};
	int gamma_q   {};
	int epsilon_q {};

	int max_steps  {};
	int state_cnt  { FrozenLake::STATE_CNT };
	int action_cnt { FrozenLake::ACTION_CNT };

	QLearner(
		float alpha_f,
		float gamma_f,
		float epsilon_f,
		int max_steps,
		int state_cnt,
		int action_cnt 
	);

	void get_rand( float &rand_f, int &rand_q );

	void train( void );

	void predict( void ) const;

};

#endif

