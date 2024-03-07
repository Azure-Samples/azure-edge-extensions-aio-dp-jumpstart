#!/bin/bash

blue(){
    echo -e "\e[0;34m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\e[0;34m $($2) \x1B[0m"
    fi
}

red(){
    echo -e "\x1B[31m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[31m $($2) \x1B[0m"
    fi
}

green(){
    echo -e "\x1B[32m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[32m $($2) \x1B[0m"
    fi
}

yellow(){
    echo -e "\x1B[33m $1 \x1B[0m"
    if [ ! -z "${2}" ]; then
    echo -e "\x1B[33m $($2) \x1B[0m"
    fi
}
