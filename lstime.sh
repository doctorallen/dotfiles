#!/bin/bash
for dir in */; do
    timestamp=$(find ./$dir -type f -printf "%T@ %t\\n" | sort -nr -k 1,2 | head -n 1)
    printf "%s %s\n" "$timestamp" "$dir"
done | sort -nr -k 1,2 | awk '{$1=""; print}'
