#!/bin/bash
A="$(ls ~ | wc -l)"
B="$(ls -a ~ | wc -l)"
C=$[$B-$A]

echo "Домашний каталог пользователя"
whoami
echo "содержит обычных файлов:"
echo "$A"
echo "скрытых файлов:"
echo "$C"


