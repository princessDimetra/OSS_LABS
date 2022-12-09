#!/bin/bash
A=$(whoami)
cd ~
B=$(pwd)
C=$[$(whoami|wc -m)-1]
D=$[$(pwd|wc -m)-1]
E=$[$C+$D]

echo $A $B $E
