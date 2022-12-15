#!/bin/bash
ps -e -o ruid,euid,cmd | while read text
do
	temp=($text)
	if [ ${temp[1]} != ${temp[0]} ];
	then
		echo "${temp[2]}"
	fi
done
