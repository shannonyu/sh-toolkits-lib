#sh-toolkits-lib

A library to implement shell toolkits, which means collect similar or common operations together. But there is more, you can use this library to implement api sdk also.

#Get started

##How to install

Clone the source:

    git clone https://github.com/dangoakachan/sh-toolkits-lib.git
    cd sh-toolkits-lib

**Note**: sh-toolkits-lib depends on the [logdotsh](https://github.com/dangoakachan/logdotsh), so don't forget to clone the submodule too:

    git submodule update --init --recursive


Then install the library:

    sh deploy.sh install

It will copy all source files to /etc/sh-toolkits-lib folder.

##First example

Save following code into a file, for example test_toolkit.sh:

    . /etc/sh-toolkits-lib/functions.sh

    function toolkit_1() # <p1> [p2]
    {
        check_params "$@"
        echo p1=$p1 p2=$p2
    }

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

    execute_function "$@"

Then run the script in the command line without any arguments, it will show the usage:

    $ sh test_toolkits.sh
    == Usage: ==
    test_toolkits.sh <function_name> [name=value]

    == Available functions: ==
    |- lookup_domain        <domain>
    |- show_hidden_char     <str>
    |- toolkit_1            <p1> [p2]


As you see, it will list the available functions and their usage, for example, the **toolkit_1**
function has two arguments, p1 and p2, the former is required, and the latter is optional.

The arguments are given in format of name=value, so if you want to call **toolkit_1**, you need run like this:

    $ sh test_toolkits.sh toolkit_1 p1=1 p2=2
    p1=1 p2=2

But if you missing required arguments or write wrong arguments name, it will throw an error as you expect:

    $ sh test_toolkits.sh toolkit_1 p1=1 p3=2
    [ERROR] [2013-06-02 23:23:10] 'p3' is invalid to toolkit_1!
    $ sh test_toolkits.sh toolkit_1 p2=2
    [ERROR] [2013-06-02 23:23:35] 'p1' is required when calling toolkit_1 (<p1>).

##Function definition

A valid function definition must be:

    function func_name() # <param1> [param2]
    {
        # function body code
    }

From above definition, we get follow part:
 
* Function name: func_name
* Function parameter definition: <param1> [param2]
    * Angular bracket: required paramameter
    * Square bracket: optional parameter

##Argument check

In the example, when we missing required argument or write wrong argument name, the function will throw an error. This work is done by **check_params** function.

In addition to this, it will assign the argument value to variable, whose name is the same as the parameter in the definition:

   function func_name() # <param1> [param2]
    {
        check_params "$@"
        echo param1=$param1 param2=$param2
    } 

##The "main"

If you done all of above work, don't forget to add below statements to the end of the script:

    execute_function "$@"

**execute_function** will pass the arguments to specified function, and run it.

#Advanced Usage

##Extra help

If you think the default help is too simple, you can add an extra help function as you like:

    # Extra help
    function toolkit_1_help()
    {
        echo "This is extra help for test2"
    }

    function toolkit_1() # <p1> [p2]
    {
        check_params --help_func=toolkit_1_help "$@"
        echo p1=$p1 p2=$p2
    }

The extra help information will be printed after the default one:

    $ sh test_toolkits.sh toolkit_1
    == Usage: ==
    test_toolkits.sh <function_name> [--help|-h] [name=value]

    == Functions usage: ==
    |- toolkit_1    <p1> [p2]

    == Extra help: ==
    This is extra help for test2

##Debug script

In shell, we use 'set -x' to debug script. In use of sh-toolkits-lib, you can enable this by adding --debug option when run the script:

    $ sh test_toolkits.sh --debug toolkit_1
    + shift
    + [[ toolkit_1 = --* ]]
    + local func_name=toolkit_1
    + shift
    + '[' -z toolkit_1 ']'
    + has_function test_toolkits.sh toolkit_1
    + ggrep -qE '^ *function +toolkit_1 *\(' test_toolkits.sh
    + toolkit_1

##Bash completion

See complete.sh in the src directory fore more help

##More

Reading the source..
