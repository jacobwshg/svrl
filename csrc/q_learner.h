
#ifndef Q_LEARNER_H
#define Q_LEARNER_H

#include "frozenlake.h"
#include <string>
#include <vector>

class QLearner
{
private:
	static inline const std::string RAND_PATH { "../sim/uniforms-f.txt" };
	static inline constexpr int RAND_CNT { 1000 };

	int alpha_q   {};
	int gamma_q   {};
	int epsilon_q {};
	int decay_q   {};
	int eps_min_q {};

	// only store quantized rewards
	std::vector< std::vector<int> > Qtbl {};

	std::vector<float> rand_f_mem {};
	std::vector<int>   rand_q_mem {};
	int rand_cnt { 0 };
	int rand_idx { 0 };

	void get_rand( float &rand_f, int &rand_q );

public:
	float alpha_f   { 0.5f };
	float gamma_f   { 0.5f };
	float epsilon_f { 0.2f };
	float decay_f   { 0.0f };
	float eps_min_f { 0.0f };

	int max_steps  {};
	int world_size { FrozenLake::WORLD_SIZE };
	int action_cnt { FrozenLake::ACTION_CNT };

	std::vector<int> pred_actions {};
	std::vector<int> pred_state_idxs {};
	std::vector<int> pred_rewards_i {};

	QLearner(
		float alpha_f,
		float gamma_f,
		float epsilon_f,
		float decay_f,
		float eps_min_f,

		int max_steps,
		int world_size,
		int action_cnt 
	);

	void train( void );

	void predict( void );

	void print_Qtbl( void ) const;

};

#endif

