#!/bin/echo Warnning, this library must only be sourced!
# vim: set expandtab smarttab shiftwidth=4 tabstop=4:

#
# Author: dangoakachan@foxmail.com
# Description: core library of manage toolkits
#
# Provide a very smart way to execute different functions in a script
#
# Function definition syntax in script:
#
# function func_name() # <param1> [param2]
# {
#     # function body code
# }
#
# From above definition, we get follow part:
# 
# * Function name: func_name
#
# * Function parameter definition: <param1> [param2]
#
#   - Angular bracket: required params
#   - Square bracket: optional params
#
# After all, put below line to the end of script:
#
# execute_function "$@"
#

############################################################################

# Source some base libraries
PREFIX=/etc/sh-toolkits-lib

. $PREFIX/log.sh
. $PREFIX/type.sh

############################################################################

# Constants definition
VERSION='0.2.1'
FUNC_NAME_REGEX="[a-zA-Z_][a-zA-Z0-9_]*"  # Function name
WORD_REGEX="[a-zA-Z0-9_]*"                # Word

# Replace DOT into __DOT__
DOT='__DOT__'

# Replace hyphen into __HYPHEN__
HYPHEN='__HYPHEN__'

# List the function definition in specified module
# $1: module path
# $2: function name or regular expression
# Return a list of "function name->function parameters"
function list_functions()
{
    sed -nr "s/^ *function +\<($2)\> *\(\) *# *(.*)/\1->\2/p" "$1"
}

# List all function names in specified module
# $1: module path
# Return a list of function names
function list_function_names()
{
    list_functions "$1" "$FUNC_NAME_REGEX" | awk -F"->" '{print $1}'
}

# List the function parameters
# $1: module path
# $2: function name
# Return the parameter part in function definition
function list_function_params()
{
    list_functions "$1" "$2" | awk -F"->" '{print $2}' | head -1
}

# Get the function parameters
# $1: module path
# $2: function name
# Return a list of function parameters
function get_function_params()
{
    list_function_params "$1" "$2" | sed 's/[][<>]//g'
}

# Check whether the module has the function
# $1: module path
# $2: function name or regular expression
# Return 0 if have, else return 1
function has_function()
{
    grep -qE "^ *function +$2 *\(" "$1"
}

# Check whether the module has similar function
# $1: module path
# $2: function name or regular expression
# Return 0 if have, else return 1
function has_similar_function()
{
    grep -qE "^ *function +${WORD_REGEX}$2${WORD_REGEX} *\(" "$1"
}

# Print the function help
# $1: module path
# $2: function name or regular expression
function _print_function_help()
{
    local max_width=`awk 'BEGIN {max=0;} \
        /^ *function +\<'"$2"'\> *\(\) *#/ { \
           len=length($2); \
           if (len>max) max=len; \
        } \
        END {print max;}' "$1"`
    
    list_functions "$1" "$2" | awk -F"->" \
        '{printf "|- %-'$max_width's\t%s\n", $1, $2}'
}

# Print all available functions
# $1: module path
function print_function_available()
{
    green "== Usage: ==\n"
    printf "`basename $1` <function_name> [name=value]\n\n"

    green "== Available functions: ==\n"
    _print_function_help "$1" "$FUNC_NAME_REGEX"
}

# Print the function help
# $1: module path
# $2: function name or regular expression
# $3: extra help function or strings
function print_function_help()
{
    green "== Usage: ==\n"
    printf "`basename $1` <function_name> [--help|-h] [name=value]\n\n"

    green "== Functions usage: ==\n"
    _print_function_help "$1" "$2"

    # Print extra help if exist
    if [ -n "$3" ]; then
        yellow "\n== Extra help: ==\n"

        if is_function $3; then
            eval "$3"
        else
            echo "$3"
        fi
    fi
}

# Print the suggested function hints
# $1: module path
# $2: function name or regular expression
function print_function_hints()
{
    green "== Do you mean? ==\n"
    _print_function_help "$1" "${WORD_REGEX}$2${WORD_REGEX}"
}

# Print module help information
# $1: module path
function print_module_help()
{
    local base=`basename $1`

    cat << EOF
Usage: $base [OPTIONS] <function_name> [name=value]

For more help, running:
$base --help: show this help
$base --list: list support functions
$base --list-params <function_name>: list function parameters
$base --debug: enable shell debug function
$base --name=value: set the variable name to value
EOF
}

# Get the parameter name
# $1: the parameter
function get_param_name()
{
    echo "$1" | awk -F= '{print $1}'
}

# Get the parameter value
# $1: the parameter
function get_param_value()
{
    echo "$1" | awk -F= '{$1="";OFS="=";print $0}'| cut -c2-
}

# Print the parameters passed to function
# $1: all passwd parameters
# Note: only for debug use
function print_params()
{
    local cnt=1

    for param in "$@"; do
        echo "$cnt: $param"
        let cnt+=1
    done
}

# Skip unwanted parameters and get the new one
# $1: variable name to store the new parameters, it's an array
# $2: parameter list to be skipped, seperated by whitespace
# $3: all parameters
# Example:
# skip_params params "p1 p2" "p1=2 p2=2 p3=3"
# Then you can get the new parameters by access 'params' array
function skip_params()
{
    local var=$1
    local skips="$2"

    local new_params param_name param_value

    shift 2

    # Create the new parameters list
    for param in "$@"; do
        param_name=`get_param_name "$param"`
        param_value=`get_param_value "$param"`

        # Skip the parameter in skips list
        if is_in "$param_name" "$skips"; then
            continue
        fi

        # Skip the parameter whose value is empty
        if [ -z "$param_value" ]; then
            continue
        fi

        new_params="$new_params $param_name='$param_value'"
    done

    # Create an array to store the new parameters
    eval "$var=($new_params)"
}

# Check whether the parameter is valid based on its type
# $1: parameter type
# $2: paremeter value
# $3: exit when check failed if $3 equals 1, default 1
# Note: A type-check function 'is_type' must exist
function check_param_type()
{
    local param_type="$1"
    local param_value="$2"
    local exit_mode=${3:-1}
    local check_func="is_$1"

    # Check whether the check function exists
    if ! is_function $check_func; then
        return 0
    fi

    # Check success
    if $check_func "$param_value"; then
        return 0
    fi

    # Exit or not
    if [ $exit_mode -eq 1 ]; then
        exit_msg "'$param_value' is an invalid $param_type!\n"
    else
        warn_msg "'$param_value' is an invalid $param_type!\n"
    fi
}

# Make a valid variable name
# $1: name string
# Ex: var_name a.b-c => a__DOT__B__HYPHEN__c
function var_name()
{
    echo "$1" | sed "s/\./$DOT/g;s/-/$HYPHEN/g"
}

# Be oppose to above
function un_var_name()
{
    echo "$1" | sed "s/$DOT/./g;s/$HYPHEN/-/g"
}

# Get the variable value
# $1: variable name
# Ex:
# var1="xxx"
# var_value "var1" = > "xxx" 
function var_value()
{
    local name=`var_name "$1"`

    echo "${!name}"
}

# Check the target function parameters and create variable corresponding
# to the given parameter pair.
# 
# Usage: check_params [OPTIONS] <params ..>
#
# Options:
#  --func=FUNC      indicates the target function to be checked, this is the
#                   function that call the check_params by default.
#
#  --mod=MOD        indicates the module path, this is the path of script where
#                   the check_params is called.
#
#  --help_func=FUNC indicates the extra help function, which will be called when
#                   check failed.
#
#  --debug          Enable shell debug function
#  --debug-off      Disable shell debug function
#  --help, -h       print function help and exit
# 
# Example: check_params --help_func=func1_help --func=func1 "$@"
#
# Throw error and exit if check failed.
#
# Note:
#
# Target function is the function be checked, each parameter of target function
# is like 'name=value', and whether the parameter is required or optional is
# defined by the syntax defined in the starting.
#
# Parameter definition has two syntax, either '<name>' or '[name]', the former
# defines a required parameter, and the latter defines an optional parameter.
#
# This function will check the parameter passed to the target function based
# on its definition. Throw error if one of the parameter is invalid, or not all
# required parameters are provided.
#
# If all paramters are checked successfully, at the last, we will create variable
# for each parameter, the variable name is paramter name, and the value is paramter
# value, then you can access the parameter based on the paramter name.
function check_params()
{
    # By default, module path is current source file
    local mod_path=$0

    # By default, the function is that calls check_params
    local func_name=${FUNCNAME[1]}

    # Extra help function given by user, it's optional
    local help_func_name

    # Process the options starts with hyphen
    # Note: option shoud be positioned before paramters
    while [[ "$1" == -* ]]; do
        case $1 in
            --mod=*)       # use given module path
                mod_path=`get_param_value "$1"`
                shift;;
            --func=*)      # use given function name
                func_name=`get_param_value "$1"`
                shift;;
            --help_func=*) # use extra help function
                help_func_name=`get_param_value "$1"`
                shift;;
            --help|-h)     # Only want to show help
                print_function_help "$mod_path" "$func_name" "$help_func_name" 
                exit 0;;
            --debug)       # Enable shell debug function
                set -x
                shift;;
            --debug-off)   # Disable shell debug function
                set +x
                shift;;
            *)             # Invaid options
                exit_msg "The option '$1' is invalid!\n";;
        esac
    done

    local param param_name param_value
    local func_params=`list_function_params "$mod_path" "$func_name"`

    # If no parameters given, show help like --help or -h
    # Fixed: only when the function has required parameters
    if echo "$func_params" | grep -q '<.*>' && [ $# -eq 0 ]; then
        print_function_help "$mod_path" "$func_name" "$help_func_name" 
        exit 0
    fi

    # Check the parameter format
    for param in "$@"; do
        param_name=`get_param_name "$param"`
        param_value=`get_param_value "$param"`

        # If the parameter's format is not name=value
        if [[ -z "$param_name" || -z "$param_value" ]]; then
            error_msg "'$param' isn't the form of 'name=value'!\n"
            print_function_help "$mod_path" "$func_name" "$help_func_name"
            exit 1
        fi

        # Create parameter variable if it is valid
        if echo "$func_params" | grep -q "\<$param_name\>"; then
            param_name=`var_name "$param_name"`
            eval "$param_name='$param_value'"
        else # Not found parameter
            error_msg "'$param_name' is invalid to $func_name!\n"
            print_function_help "$mod_path" "$func_name" "$help_func_name"
            exit 1
        fi
    done

    set -f  # Disable filename glob

    # Check whether all required paramters are given
    for param in $func_params; do
        # Don't need to check optional parameters
        if echo "$param" | grep -q '\[[^]]*\]'; then
            continue
        fi

        # Remove leading '<' and trailing '>'
        param_name=`expr "$param" : '<\(.*\)>'`

        # ${!param_name} (Indirect referencing) will get the paramter value
        if [ -z "${!param_name}" ]; then
            error_msg "'$param_name' is required when calling $func_name ($param).\n"
            print_function_help "$mod_path" "$func_name" "$help_func_name"
            exit 1
        fi
    done

    set +f  # Enable filename glob again
}

# Execute a target function
#
# Usage: exec_func [OPTIONS] [func_name] [params]
#
# Options:
#   --help         Print module help information
#
#   --list         List all target function names that defined in this module.
#   --list-params  List all parameters of target function.
#
#   --debug        Enable shell debug function
#
#   --name=value   assign value to the variable name, through this option, we
#                  can change the global variable name defined in the module.
#                  (A hack way)
#
# Arguments:
#   $1: target function name
#   $2..: target function parameters
#
# Return 0 if execute successfully, otherwise return 1
function execute_function()
{
    local mod_path=$0

    # Process the options
    while [[ "$1" = --* ]]; do
        case $1 in
            --help)     # Print module help information
                print_module_help "$mod_path"
                return 0;;
            --list)     # List all target function names
                list_function_names "$mod_path"
                return 0;;
            --list-params)  # List all params of target function
                get_function_params "$mod_path" $2
                return 0;;
            --debug)    # Enable debug mode
                set -x
                shift;;
            --*=*)      # Assign variables
                local var_name var_val

                # Get the variable name and value
                var_name=`get_param_name "$1"`
                var_name=${var_name#--}
                var_val=`get_param_value "$1"`

                eval "$var_name='$var_val'"
                shift;;
        esac
    done

    local func_name=$1
    shift

    if [ -z "$func_name" ]; then # If no arguments
        print_function_available "$mod_path"
    elif has_function "$mod_path" "$func_name"; then # If the function exist
        $func_name "$@"  # Call the function with parameters directly
    else # Otherwise, we print error or ?
        error_msg "The function '$func_name' doesn't exist!\n"

        # Convert to standard function name
        func_name=`echo "$func_name" | tr A-Z- a-z_`

        # We find similar functions futhermore
        if has_similar_function "$mod_path" "$func_name"; then
            print_function_hints "$mod_path" "$func_name"
        else
            print_function_available "$mod_path"
        fi

        return 1
    fi
}
