#!/bin/bash
A="$(ps -u| wc -l)"
B="$(ps -u root | wc -l)"

echo "Процессов пользователя:"
whoami
echo "$A"
echo "Процессов пользователя root:"
echo "$B"


