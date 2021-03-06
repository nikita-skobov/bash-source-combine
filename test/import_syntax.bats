function setup() {
    source $BATS_TEST_DIRNAME/../lib/import_syntax.bsc
}

@test "can detect import X syntax" {
    local file_data=(
        "other lines"
        "import X"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 
    echo "$output"
    echo "len: ${#import_files_list[@]}, all: ${import_files_list[@]}"


    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 1 ]]
    [[ "${#import_keywords_list[@]}" -eq 1 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_keywords_list[0]}" == "*" ]]
}


@test "can detect import X Y Z syntax" {
    local file_data=(
        "other lines"
        # testing out whitespaces:
        "import X      Y Z"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 

    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 3 ]]
    [[ "${#import_keywords_list[@]}" -eq 1 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_files_list[1]}" == "Y" ]]
    [[ "${import_files_list[2]}" == "Z" ]]
    [[ "${import_keywords_list[0]}" == "*" ]]
}

@test "can detect import A from X syntax" {
    local file_data=(
        "other lines"
        "import A from X"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 

    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 1 ]]
    [[ "${#import_keywords_list[@]}" -eq 1 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_keywords_list[0]}" == "A" ]]
}


@test "can detect import A B C from X syntax" {
    local file_data=(
        "other lines"
        "import A B C from X"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 

    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 1 ]]
    [[ "${#import_keywords_list[@]}" -eq 3 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_keywords_list[0]}" == "A" ]]
    [[ "${import_keywords_list[1]}" == "B" ]]
    [[ "${import_keywords_list[2]}" == "C" ]]
}

@test "can detect import { A B C } from X syntax" {
    local file_data=(
        "other lines"
        # testing out whitespaces:
        "import { A B      C } from X"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 

    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 1 ]]
    [[ "${#import_keywords_list[@]}" -eq 3 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_keywords_list[0]}" == "A" ]]
    [[ "${import_keywords_list[1]}" == "B" ]]
    [[ "${import_keywords_list[2]}" == "C" ]]
}

@test "can detect import * from X syntax" {
    local file_data=(
        "other lines"
        # whitespace test:
        "import *    from X"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 

    echo "$output"

    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 4 ]]
    [[ "${#import_files_list[@]}" -eq 1 ]]
    [[ "${#import_keywords_list[@]}" -eq 1 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_keywords_list[0]}" == "*" ]]
}


@test "can detect multi-line import {\nA\nB\nC\n} from X syntax" {
    local file_data=(
        "other lines"
        # testing out whitespaces:
        "import {"
        "      A"
        "B  "
        "   C   "
        "} from     X"
        "line2"
        "line3"
    )
    local import_files_list=()
    local import_keywords_list=()
    # sanity checks:
    [[ "${#file_data[@]}" -eq 8 ]]
    [[ "${#import_files_list[@]}" -eq 0 ]]
    [[ "${#import_keywords_list[@]}" -eq 0 ]]

    parse_import_statement file_data 1 import_files_list import_keywords_list 
    echo "$output"

    # should not modify the actual file_data array:
    [[ "${#file_data[@]}" -eq 8 ]]
    [[ "${#import_files_list[@]}" -eq 1 ]]
    [[ "${#import_keywords_list[@]}" -eq 3 ]]
    [[ "${import_files_list[0]}" == "X" ]]
    [[ "${import_keywords_list[0]}" == "A" ]]
    [[ "${import_keywords_list[1]}" == "B" ]]
    [[ "${import_keywords_list[2]}" == "C" ]]
}
