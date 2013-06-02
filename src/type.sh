#!/bin/echo Warnning, this library must only be sourced!
# vim: set expandtab smarttab shiftwidth=4 tabstop=4:

#
# Author: dangoakachan@foxmail.com
# Description: defines some type validate function
#

# Validate a string against a set of possible values
# $1: string to be validated
# $2: a set of possible values splitted by space
# Return: 0 (yes) or 1 (no)
function is_in()
{
    local str=$1
    
    shift 1

    if echo "$@" | grep -Eq -- "([[:space:]]|^)$str([[:space:]]|$)"; then
        return 0
    else
        return 1
    fi
}

# Validate a "true" string
# $1: string to be validated
# Return: 0 (yes) or 1 (no)
# Note: If the value of a string is one of 'yes', 'true', '1', 'on', then
# it is called a "true" string
function is_true()
{
    is_in $1 "yes true 1 on"
}

# Validate a "false" string
# $1: string to be validated
# Return: 0 (yes) or 1 (no)
# Note: If the value of a string is one of 'no', 'false', '0', 'off', then
# it is called a "false" string
function is_false()
{
    is_in $1 "no false 0 off"
}

# Check if the string is a number
# $1: the string to be validated
# Return: 0 (yes) or 1 (no)
function is_number()
{
    echo "$1" | grep -qE "^[0-9]+$"
    return $?
}

# Check if the string is a ip address
# $1: the string to be validated
# Return: 0 (yes) or 1 (no)
function is_ip()
{
    echo "$1" | grep -qE '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    return $?
}

# Check if the string is a ip segment
# $1: the string to be validated
# Return: 0 (yes) or 1 (no)
function is_ip_segment()
{
    echo "$1" | grep -qE '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/(3[0-2]|[12][0-9]|[1-9])$'
    return $?
}

# Check if the config fle is readable by you
# $1: the config file name
# Return: 0 (yes) or 1 (no)
function is_conf()
{
    test -r "$1"
}

# Get the type of specified item
# $1: the item to be checked
# Return the type, the type may be 'builtin', 'function',
# 'keyword', 'file', 'alias', or ''.
function typeof()
{
    type -t $1 2>/dev/null
}

# Check whether an item is a function
# $1: the function name
# Return: 0(yes) or 1(no)
function is_function()
{
    local func_name=$1
    test "`typeof $func_name`" = "function"
}
