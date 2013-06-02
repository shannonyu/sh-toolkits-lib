#!/bin/bash

# No need if you use linux
if [ "`uname`" = "Darwin" ]; then
    alias sed=gsed
    alias awk=gawk
    alias grep=ggrep
fi

. /etc/sh-toolkits-lib/functions.sh

function lookup_domain() # <domain>
{
    check_params "$@"
    dig $domain +short
}

function show_hidden_char() # <str>
{
    check_params "$@"
    #echo "$str" | cat -evt
    echo "$str" | cat -A
}

function toolkit_1() # <p1> [p2]
{
    check_params "$@"
    echo p1=$p1 p2=$p2
}

execute_function "$@"
