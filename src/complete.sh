#!/bin/echo Warnning, this library must only be sourced!                                                
# vim: set expandtab smarttab shiftwidth=4 tabstop=4:

#
# Author: dangoakachan@foxmail.com
# Description: bash completion functions for mange tools
#
# How to use:
# (Assume the executable script name is 'bin')
#
# . /etc/houyi_pet/lib/misc/mgmt/complete.sh
#
# function _bin()
# {
#     _comp bin
# }
#
# complete -o default -o nospace -F _bin bin
#

# Base completion function
# $1: command name to be completed
# $2: add extra completion function
function _comp()
{
    local bin=$1
    local advanced_complete_func=$2

    local cur prev cword=-1 action
    local words=()

    # Reset COMPREPLY array
    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"

    # Ignore options
    for i in "${COMP_WORDS[@]}"; do
        if [[ "$i" == -* ]]; then
            continue
        fi

        let cword+=1
        words[cword]=$i

        if [[ "$i" == "$cur" ]]; then
            break
        fi
    done

    if [ $cword -eq 0 ]; then
        return 0
    fi

    prev=${words[cword-1]}  # previous word
    cur=${words[cword]}     # current word

    # Need to complete action names
    if [ $cword -eq 1 ]; then
        COMPREPLY=( $(compgen -W "`$bin --list`" -- $cur) )
        return 0
    fi

    action=${words[1]}      # store the action name

    # Need to complete parameter names
    if ! echo "$cur" | grep -sq =; then
        COMPREPLY=( $(compgen -S = -W "`$bin --list-params $action`" -- $cur) )
        return 0
    fi

    # Below we will complete especial parameter values
    if [ -n "$advanced_complete_func" ]; then
        prev="${cur%%=*}"       # parameter name
        cur="${cur#*=}"         # parameter value

        $advanced_complete_func "$action" "$prev" "$cur"
    fi
}
