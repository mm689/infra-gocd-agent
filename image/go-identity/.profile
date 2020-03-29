#!/bin/bash
# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
     . "$HOME/.bashrc"
    fi
fi

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
