#!/bin/bash
cd "$1"
echo "Каталоги:"
ls . -a -l  |grep ^d
echo "Обычные файлы:"
ls . -a -l | grep ^-
echo "Символьные ссылки"
ls . -a -l | grep ^l
echo "Символьные устройства"
ls . -a -l | grep ^c
echo "Блочные устройства"
ls . -a -l | grep ^b

