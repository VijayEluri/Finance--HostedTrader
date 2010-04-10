#!/bin/sh

find $1 -name "*.txt" -exec ./process.forexite.sh "{}" \;
