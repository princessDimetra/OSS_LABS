#!/bin/bash
find ~ -maxdepth 1 -name "*txt"
find ~ -maxdepth 1 -name "*.txt" | wc -l
find ~ -maxdepth 1 -name  "*.txt" -exec du -ch {} + | grep total
