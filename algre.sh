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
    exit 0
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
    exit 0
}

# End the execution with an error (incorrect option given, $1 is the wrong option)
incorrect_option() {
    echo "Incorrect option: \"$1\"."
    exit 1
}

# End the execution with an error (incorrect file path given, $1 is the wrong path)
incorrect_file() {
    echo "Incorrect file path: \"$1\"."
    exit 1
}

# End the execution with an error (incorrect directory given, $1 is the wrong directory)
incorrect_directory() {
    echo "Incorrect directory: \"$1\"."
    exit 1
}

# End the execution with an error (no number(s) given, $1 is the option chosen)
no_number() {
    echo "Number(s) not given after option \"$1\"."
    exit 1
}

# End the execution with an error (no directory given, $1 is the option chosen)
no_directory() {
    echo "Directory not given after option \"$1\"."
    exit 1
}

# Checks if the first argument ($1) is a nonnegative number, if isn't - end the execution
is_nonnegative_number() {
    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "Not a number: \"$1\"."
        exit 1
    fi
}

# Checks if the first argument ($1) is less or equal comapered
# to the second argument ($2), if isn't - end the execution
is_less_or_equal() {
    if [ "$1" -le "$2" ]; then
        echo "$2 is less than $1."
        exit 1
    fi
}

# Read and parse options provided by the user
# First arg ($1) is the number of args (containing not relevant data) to shift
# Second arg ($2) should be the script exec arguments
read_options() {
    shift "$1"
    local OPTIONS=("$@")
    local N_OPTIONS=${#OPTIONS[@]}
    local LAST_OPTION=""
    # Number of options to skip in the main loop (if one options needs e.g. a number after it)
    local SKIP=0 
    for ((i=0; i<N_OPTIONS; i++)); do
        local OPTION=${OPTIONS[i]}
        if [ $SKIP -ne 0 ]; then
            SKIP=$((SKIP-1))
        elif [ "$OPTION" == "-h" ]; then
            print_help
        elif [ "$OPTION" == "-v" ]; then
            print_version
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
                is_nonnegative_number "$RANGE_L"
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
                is_nonnegative_number "$RANGE_L"
                is_nonnegative_number "$RANGE_R"
                is_less_or_equal "$RANGE_L" "$RANGE_R"
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
        if [ "$LAST_OPTION" == "-dir" ]; then
            no_directory "$LAST_OPTION"
        else
            no_number "$LAST_OPTION"
        fi
    fi
}

# Compile the file in the source code $1 to the executable $2
# (only if the $1 and $2 are different, preventing from compiling the executable)
compile() {
    if [ "$1" == "$2" ]; then
        return 0
    fi
    if [ $O3 -eq 0 ] && [ $WARN -eq 0 ]; then
        if ! g++ "$1" -o "$2"; then
            echo "Failed to compile \"$1\"."
            exit 1
        fi
    fi
    # In this section of code, O3, WARN, or all of them are true
    local WARN_FLAGS=(
        "-pedantic"
        "-Wall"
        "-Wextra"
        "-Wmissing-declarations"
        "-Wmissing-include-dirs"
        "-Wshadow"
        "-Werror"
    )
    if [ $WARN -eq 0 ]; then
        # Since WARN if false, O3 must be true
        if ! g++ "$1" -O3 -o "$2"; then
            echo "Failed to compile \"$1\"."
            exit 1
        fi
    else
        if [ $O3 -eq 0 ]; then
            # WARN true, no O3
            if ! g++ "$1" "${WARN_FLAGS[@]}" -o "$2"; then
                echo "Failed to compile \"$1\"."
                exit 1
            fi
        else  
            # Both options true
            WARN_FLAGS+=("-O3")
            if ! g++ "$1" "${WARN_FLAGS[@]}" -o "$2"; then
                echo "Failed to compile \"$1\"."
                exit 1
            fi
        fi
    fi
}

# Fix paths by adding ./ in front (to make execution possible)
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

# Run tests of the solution ($1) with tests provided in the tests directory
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

# Run tests of the solution ($1) with input data provided in the tests directory
# comparing with the correct output brute force solution ($2)
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

# Run tests of the solution ($1) with input data provided by the test generator ($3)
# comparing with the correct output brute force solution ($2)
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

# Script block used to differentiate between different modes of operation
if [ $# -eq 0 ]; then
    # Small message about the script if no args are given
    printf "Usage:\t./algre.sh file(s) [options]...\n"
    printf "Help:\t./algre.sh -h\n"
elif [ $# -eq 1 ]; then
    # 1 argument could be either 1 file mode or 1 option mode (-h, -v)
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
    # 2 arguments could be either 2 file mode, 1 file mode with 1 option
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
    # 3 arguments could be either 3 file mode with 0 or more options,
    # 2 file mode with 1 or more options, and 1 file mode with 2 or more options
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
