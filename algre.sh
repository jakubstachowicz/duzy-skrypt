#!/bin/bash -u
# Author                : Jakub Stachowicz (s198302@student.pg.edu.pl)
# Created On            : 18.05.2024
# Last Modified By      : Jakub Stachowicz (s198302@student.pg.edu.pl)
# Last Modified On      : 19.05.2024 
# Version               : 1.0.0
# External Dependencies : g++ (optional, for compiling source code option)
#                         vscode (optional, for quicker developement using vscode's tasks)
# Description           : README.md
# Licensed under MIT License (see LICENSE)

TEST_SRC=""
BRUTE_SRC=""
TESTGEN_SRC=""

TESTS_DIR="./tests/"

TIME=0
TLIMIT=0
O3=0
WARN=0
VSC=0
RANGE_L=-1
RANGE_R=-1

# Print version and author information
print_version() {
    echo "algre version 1.0.0"
    echo "Author: Jakub Stachowicz"
}

# Print help menu with usages and option
print_help() {
    printf "Usage:\t./algre.sh file(s) [options]...\n\n"
    echo "Default directory containing tests is $TESTS_DIR."
    echo "It should have 2 subfolders $TESTS_DIR""in/ and $TESTS_DIR""out/"
    echo "containing *.in files and *.out files."
    echo "File(s) can be either executable(s), or source code."
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

# End the execution with an error (incorrect option given)
incorrect_option() {
    echo "Incorrect option: \"$1\"."
    exit 1
}

# End the execution with an error (incorrect file path given)
incorrect_file() {
    echo "Incorrect file path: \"$1\"."
    exit 1
}

# End the execution with an error (incorrect directory given)
incorrect_directory() {
    echo "Incorrect directory: \"$1\"."
    exit 1
}

# End the execution with an error (no number(s) given)
no_number() {
    echo "Number(s) not given after option \"$1\"."
    exit 1
}

# End the execution with an error (no directory given)
no_directory() {
    echo "Directory not given after option \"$1\"."
    exit 1
}

# Read and parse options provided by user
# First arg is the number of args (containing not relevant data) to shift
# Second arg is script exec arguments
read_options() {
    shift "$1"
    local OPTIONS=("$@")
    local N_OPTIONS=${#OPTIONS[@]}
    local SKIP=0
    local DIR_OR_NUMBER=""
    local LAST_OPTION=""
    echo "$N_OPTIONS"
    for ((i=0; i<N_OPTIONS; i++)); do
        local OPTION=${OPTIONS[i]}
        if [ $SKIP -ne 0 ]; then
            SKIP=$((SKIP-1))
            echo "Skippin: $OPTION" 
        elif [ "$OPTION" == "-h" ]; then
            print_help
            exit 0
        elif [ "$OPTION" == "-v" ]; then
            print_version
            exit 0
        elif [ "$OPTION" == "-t" ]; then
            TIME=1
        elif [ "$OPTION" == "-O3" ]; then
            O3=1
        elif [ "$OPTION" == "-warn" ]; then
            WARN=1
        elif [ "$OPTION" == "-vsc" ]; then
            VSC=1
        elif [ "$OPTION" == "-tlim" ]; then
            TLIMIT=1
        elif [ "$OPTION" == "-nr" ]; then
            SKIP=1
            if (( i+1 < N_OPTIONS )); then
                RANGE_L=${OPTIONS[i+1]}
                RANGE_R=${OPTIONS[i+1]}
                # TODO NUMBER CHECKING
            else
                no_number "$OPTION"
            fi
        elif [ "$OPTION" == "-dir" ]; then
            SKIP=1
            if (( i+1 < N_OPTIONS )); then
                TESTS_DIR=${OPTIONS[i+1]}
                if [ ! -d "$TESTS_DIR" ]; then
                    incorrect_directory "$TESTS_DIR"
                fi
                if [[ ! $TESTS_DIR =~ /$ ]]; then
                    TESTS_DIR="$TESTS_DIR""/"
                fi
                if [[ ! $TESTS_DIR =~ ^./ ]]; then
                    TESTS_DIR="./""$TESTS_DIR"
                fi
            else
                no_directory "$OPTION"
            fi
        elif [ "$OPTION" == "-r" ]; then
            SKIP=2
            if (( i+2 < N_OPTIONS )); then
                RANGE_L=${OPTIONS[i+1]}
                RANGE_R=${OPTIONS[i+2]}
                # TODO NUMBER CHECKING
            else
                no_number "$OPTION"
            fi
        else 
            incorrect_option "$OPTION"
        fi
        echo "Current: $OPTION"
        LAST_OPTION=$OPTION
    done
    if [ $SKIP -ne 0 ]; then
        if [ "$DIR_OR_NUMBER" == "DIR" ]; then
            no_directory "$LAST_OPTION"
        else
            no_number "$LAST_OPTION"
        fi
    fi
}

# Compile the file in the source code $1 to the executable $2
# (only if the $1 and $2 are different, preventing from compiling the executable)
compile() {
    if [ "$1" != "$2" ]; then
        if ! g++ "$1" -O2 -o "$2"; then
            echo "Failed to compile \"$1\"."
            exit 1
        fi
    fi
}

# Fix paths by adding ./ in front 
fix_paths() {
    if [[ ! $TEST_SRC =~ ^\./ ]]; then
        TEST_SRC="./"$TEST_SRC
    fi
    if [[ ! $BRUTE_SRC =~ ^\./ ]]; then
        BRUTE_SRC="./"$BRUTE_SRC
    fi
    if [[ ! $TESTGEN_SRC =~ ^\./ ]]; then
        TESTGEN_SRC="./"$TESTGEN_SRC
    fi
}

# Run tests of solution ($1) with tests provided in tests directory
run_1_file_test() {
    compile "$1" "$TEST_SRC"
    fix_paths
    echo "Testing \"$TEST_SRC\"..."
    local LS_RESULT
    LS_RESULT=$(ls "$TESTS_DIR""in/" 2> /dev/null)
    if [ $? -ne 0 ]; then
        echo "Tests not found!" 
        exit 1
    fi
    for TEST_FILE in $LS_RESULT; do
        if [[ ! $TEST_FILE =~ \.in$ ]]; then
            continue
        fi
        TEST_FILE_OUT=$(echo "$TEST_FILE" | sed -E 's/\.in$//g')".out"
        if [ ! -f "$TESTS_DIR""out/$TEST_FILE_OUT" ]; then
            continue
        fi
        printf "Test %s\t" "$TEST_FILE"
        if ! $TEST_SRC < "$TESTS_DIR""in/$TEST_FILE" > /tmp/test.out; then
            rm -f /tmp/test.out
            printf "\nTested solution failed to execute.\n"
            exit 1
        fi
        if ! diff /tmp/test.out "$TESTS_DIR""out/$TEST_FILE_OUT" > /dev/null; then
            echo "FAILED"
            if [ -d "$(dirname "$TEST_SRC")/algre_failed_test" ]; then
                rm -rf "$(dirname "$TEST_SRC")/algre_failed_test"
            fi
            mkdir "$(dirname "$TEST_SRC")/algre_failed_test"
            mv /tmp/test.out "$(dirname "$TEST_SRC")/algre_failed_test/test.out"
            cp "$TESTS_DIR""out/$TEST_FILE_OUT" "$(dirname "$TEST_SRC")/algre_failed_test/$TEST_FILE_OUT"
            cp "$TESTS_DIR""in/$TEST_FILE" "$(dirname "$TEST_SRC")/algre_failed_test/$TEST_FILE"
            exit 1
        else
            echo "OK!"
            rm -f /tmp/brute.out
            rm -f /tmp/test.out
        fi
    done
}

# Run tests of solution ($1) with input data provided in tests directory
# comparing with correct output brute force solution ($2)
run_2_files_test() {
    compile "$1" "$TEST_SRC"
    compile "$2" "$BRUTE_SRC"
    fix_paths
    echo "Testing \"$TEST_SRC\" against brute force \"$BRUTE_SRC\"..."
    local LS_RESULT
    LS_RESULT=$(ls "$TESTS_DIR""in/" 2> /dev/null)
    if [ $? -ne 0 ]; then
        echo "Tests not found!" 
        exit 1
    fi
    for TEST_FILE in $LS_RESULT; do
        if [[ ! $TEST_FILE =~ \.in$ ]]; then
            continue
        fi
        printf "Test %s\t" "$TEST_FILE"
        if ! $BRUTE_SRC < "$TESTS_DIR""in/$TEST_FILE" > /tmp/brute.out; then
            rm -f /tmp/brute.out
            printf "\nBrute force failed to execute.\n"
            exit 1
        fi
        if ! $TEST_SRC < "$TESTS_DIR""in/$TEST_FILE" > /tmp/test.out; then
            rm -f /tmp/brute.out
            rm -f /tmp/test.out
            printf "\nTested solution failed to execute.\n"
            exit 1
        fi
        if ! diff /tmp/test.out /tmp/brute.out > /dev/null; then
            echo "FAILED"
            if [ -d "$(dirname "$TEST_SRC")/algre_failed_test" ]; then
                rm -rf "$(dirname "$TEST_SRC")/algre_failed_test"
            fi
            mkdir "$(dirname "$TEST_SRC")/algre_failed_test"
            mv /tmp/test.out "$(dirname "$TEST_SRC")/algre_failed_test/test.out"
            mv /tmp/brute.out "$(dirname "$TEST_SRC")/algre_failed_test/brute.out"
            cp "$TESTS_DIR""in/$TEST_FILE" "$(dirname "$TEST_SRC")/algre_failed_test/$TEST_FILE"
            exit 1
        else
            echo "OK!"
            rm -f /tmp/brute.out
            rm -f /tmp/test.out
        fi
    done
}

# Run tests of solution ($1) with input data provided by test generator ($3)
# comparing with correct output brute force solution ($2)
run_3_files_test() {
    compile "$1" "$TEST_SRC"
    compile "$2" "$BRUTE_SRC"
    compile "$3" "$TESTGEN_SRC"
    fix_paths
    echo "Testing \"$TEST_SRC\" against brute force \"$BRUTE_SRC\""
    echo "and with test generator \"$TESTGEN_SRC\"..."
    for ((i=1; i<=1000000; i++)); do
        printf "Test %s\t" "$i"
        if ! $TESTGEN_SRC $i > /tmp/input.in; then
            rm -f /tmp/input.in
            printf "\nTest generator failed to execute.\n"
            exit 1
        fi
        if ! $BRUTE_SRC < /tmp/input.in > /tmp/brute.out; then
            rm -f /tmp/input.in
            rm -f /tmp/brute.out
            printf "\nBrute force failed to execute.\n"
            exit 1
        fi
        if ! $TEST_SRC < /tmp/input.in > /tmp/test.out; then
            rm -f /tmp/input.in
            rm -f /tmp/brute.out
            rm -f /tmp/test.out
            printf "\nTested solution failed to execute.\n"
            exit 1
        fi
        if ! diff /tmp/test.out /tmp/brute.out > /dev/null; then
            echo "FAILED"
            if [ -d "$(dirname "$TEST_SRC")/algre_failed_test" ]; then
                rm -rf "$(dirname "$TEST_SRC")/algre_failed_test"
            fi
            mkdir "$(dirname "$TEST_SRC")/algre_failed_test"
            mv /tmp/test.out "$(dirname "$TEST_SRC")/algre_failed_test/test.out"
            mv /tmp/brute.out "$(dirname "$TEST_SRC")/algre_failed_test/brute.out"
            mv /tmp/input.in "$(dirname "$TEST_SRC")/algre_failed_test/input.in"
            exit 1
        else
            echo "OK!"
            rm -f /tmp/input.in
            rm -f /tmp/brute.out
            rm -f /tmp/test.out
        fi
    done
}

# Script block used to differentiate between different modes
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
        TEST_SRC=$(echo "$1" | sed -E 's/\.cpp$//g')
        run_1_file_test "$1"
    else
        incorrect_file "$1"
    fi
elif [ $# -eq 2 ]; then
    if [ ! -f "$1" ]; then
        incorrect_file "$1"
    elif [ ! -f "$2" ]; then
        # 1 file + 1 option
        TEST_SRC=$(echo "$1" | sed -E 's/\.cpp$//g')
        read_options 2 "$@"
        run_1_file_test "$1"
    else
        # 2 files
        TEST_SRC=$(echo "$1" | sed -E 's/\.cpp$//g')
        BRUTE_SRC=$(echo "$2" | sed -E 's/\.cpp$//g')
        run_2_files_test "$1" "$2"
    fi
elif [ $# -ge 3 ]; then
    if [ ! -f "$1" ]; then
        incorrect_file "$1"
    elif [ ! -f "$2" ]; then
        # 1 file + options
        TEST_SRC=$(echo "$1" | sed -E 's/\.cpp$//g')
        read_options 2 "$@"
        run_1_file_test "$1"
    elif [ ! -f "$3" ]; then
        # 2 file + options
        TEST_SRC=$(echo "$1" | sed -E 's/\.cpp$//g')
        BRUTE_SRC=$(echo "$2" | sed -E 's/\.cpp$//g')
        read_options 3 "$@"
        run_2_files_test "$1" "$2"
    else
        # 3 files...
        TEST_SRC=$(echo "$1" | sed -E 's/\.cpp$//g')
        BRUTE_SRC=$(echo "$2" | sed -E 's/\.cpp$//g')
        TESTGEN_SRC=$(echo "$3" | sed -E 's/\.cpp$//g')
        if [ $# -gt 3 ]; then
            # ... + options
            read_options 4 "$@"
        fi
        run_3_files_test "$1" "$2" "$3"
    fi
fi
