#!/bin/bash
NAME=$1
bash $NAME 1 2 3
bash $NAME $RANDOM $RANDOM $RANDON
bash $NAME "foo" "bar" "foobar" "foo bar"
bash $NAME "foo" "--foo" "--help" "-l"

