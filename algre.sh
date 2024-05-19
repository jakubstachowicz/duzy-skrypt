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

print_version() {
    echo "algre version 1.0.0"
    echo "Author: Jakub Stachowicz"
}

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

incorrect_option() {
    echo "Incorrect option: $1"
    exit 1
}

incorrect_directory() {
    echo "Incorrect file directory: $1"
    exit 1
}

read_options() {
    shift "$1"
    echo "N_OPTS: $#"
    for option in "$@"; do
        echo "Option: $option"
    done
}

compile() {
    if [ "$1" != "$2" ]; then
        if ! g++ "$1" -O2 -o "$2"; then
            echo "Failed to compile $1."
            exit 1
        fi
    fi
}

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

run_1_file_test() {
    compile "$1" "$TEST_SRC"
    fix_paths
    echo "Testing \"$TEST_SRC\"..."
    LS_RESULT=$(ls "$TESTS_DIR""in/")
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

run_2_files_test() {
    compile "$1" "$TEST_SRC"
    compile "$2" "$BRUTE_SRC"
    fix_paths
    echo "Testing \"$TEST_SRC\" against brute force \"$BRUTE_SRC\"..."
    LS_RESULT=$(ls "$TESTS_DIR""in/")
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
        incorrect_directory "$1"
    fi
elif [ $# -eq 2 ]; then
    if [ ! -f "$1" ]; then
        incorrect_directory "$1"
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
        incorrect_directory "$1"
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
