#!/bin/zsh -f

OBJROOT=build
GCOV_OUT_DIR="$OBJROOT/gcov.out"

coveralls -r "$OBJROOT"
