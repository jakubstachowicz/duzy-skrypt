#!/bin/bash -u
# Author                : Jakub Stachowicz (s198302@student.pg.edu.pl)
# Created On            : 18.05.2024
# Last Modified By      : Jakub Stachowicz (s198302@student.pg.edu.pl)
# Last Modified On      : 18.05.2024 
# Version               : 1.0.0
# External Dependencies : g++ (optional, for compiling source code option)
#                         vscode (optional, for quicker developement using vscode's tasks)
# Description           : README.md
# Licensed under MIT License (see LICENSE)

TEST_SRC=""
BRUTE_SRC=""
TESTGEN_SRC=""

print_version() {
    echo "algre version 1.0.0"
    echo "Author: Jakub Stachowicz"
}

print_help() {
    printf "Usage:\t./algre.sh file(s) [options]...\n"
    echo "Files can be either executables, or source code."
    echo "If source code is provided, it will be compiled using g++"
    printf "(use g++ --help for more details).\n\n"

    echo "No files:"
    printf "  -h\tHelp (this menu).\n"
    printf "  -v\tVersion information.\n"
    echo "With files:"
    printf "  1st\tWill be interpreted as the solution to be tested.\n"
    printf "  2nd\tWill be interpreted as the correct answers generator.\n"
    printf "  3rd\tWill be interpreted as the input generator.\n"
    printf "     \tIt should take one parameter, an integer,\n"
    printf "     \tused to seed the random number generator.\n\n"

    echo "Options:"
    echo "  none (for now)."
}

incorrect_option() {
    echo "Incorrect option: $1"
    exit 1
}

incorrect_directory() {
    echo "Incorrect file directory: $1"
    exit 1
}

read_options() {
    shift $1
    echo "N_OPTS: $#"
    for option in "$@"; do
        echo "Option: $option"
    done
}

if [ $# -eq 0 ]; then
    printf "Usage:\t./algre.sh file(s) [options]...\n"
    printf "Help:\t./algre.sh -h\n"
elif [ $# -eq 1 ]; then
    if [ "$1" == "-v" ]; then
        print_version
    elif [ "$1" == "-h" ]; then
        print_help
    elif [ -f "$1" ]; then
        # 1 file
        echo "jej"
    else
        incorrect_directory "$1"
    fi
elif [ $# -eq 2 ]; then
    if [ ! -f "$1" ]; then
        incorrect_directory "$1"
    elif [ ! -f "$2" ]; then
        # 1 file + 1 option
        echo "jej"
        read_options 2 "$@"
    else
        # 2 files
        echo "jej2"
    fi
elif [ $# -ge 3 ]; then
    if [ ! -f "$1" ]; then
        incorrect_directory "$1"
    elif [ ! -f "$2" ]; then
        # 1 file + options
        echo "jej"
        read_options 2 "$@"
    elif [ ! -f "$3" ]; then
        # 2 file + options
        echo "jej2"
        read_options 3 "$@"
    else
        # 3 files...
        echo "jej3"
        if [ $# -gt 3 ]; then
            # ... + options
            read_options 4 "$@"
        fi
    fi
fi
