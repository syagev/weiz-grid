cd ~/SimiMotion
qsub -o Params.o -e Params.e -cwd -q yaronall.q -V -N Params ~/WeizGrid/simpleInvoke Params
tail -f --retry -s 0.5 Params.e Params.o
