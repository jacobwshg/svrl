
#!/bin/bash

clang++ -O1 -std=c++20 -Wall -Wextra\
	./frozenlake.cxx ./q_learner.cxx ./main.cxx\
	-o ./ql.out

