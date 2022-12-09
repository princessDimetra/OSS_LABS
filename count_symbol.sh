#!/bin/bash
cat ~/bash.txt | grep 000000 > /tmp/zeros
cat ~/bash.txt | grep -v 000000 > /tmp/nozeros

echo "С нулями"
cat /tmp/zeros | head -10
cat /tmp/zeros | tail -10

echo "Без нулей"
cat /tmp/nozeros | head -10
cat /tmp/nozeros | tail -10
