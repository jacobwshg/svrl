
#!/bin/bash

OUTF="ql.out"

rm -f ./$OUTF

clang++ -O1 -std=c++20 -Wall -Wextra\
	./frozenlake.cxx ./q_learner.cxx ./main.cxx\
	-o ./$OUTF

