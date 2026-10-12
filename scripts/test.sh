mkdir -p ../build
cd ../build 
xvlog -sv ../rtl/* 
xvlog -sv ../tb/*
xelab -debug typical $1 -s sim
xsim sim -runall
