#!/bin/bash

PREFIX=/etc/sh-toolkits-lib

action=$1

if [ -z "$action" ]; then
    echo "Usage: `basename $0` <install|uninstall>"
    exit 1
fi

case $action in
    install)
        if [ ! -d "$PREFIX" ]; then
            mkdir -p $PREFIX
        fi

        cp src/*.sh $PREFIX/
        cp src/logdotsh/log.sh $PREFIX/
        sed -i 's#^PREFIX=.*$#PREFIX='$PREFIX'#' $PREFIX/functions.sh
        ;;
    uninstall)
        rm -r $PREFIX
        ;;
    *)
        echo "Error, action can only be install or uninstall"
        exit 1
        ;;
esac
