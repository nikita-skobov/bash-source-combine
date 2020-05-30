function setup() {
    source_combine=$BATS_TEST_DIRNAME/../source_combine_t.sh
    cd $BATS_TEST_DIRNAME
    some_contents="my_var=hello"
    some_other_contents="other_var=yeswoohoo"
    duplicate2_contents="ab1() {\necho '1'\n}\nab2() {\necho '2'\n}\nab3() {\necho '3'\n}\n"
    duplicate_contents="should_only() {\necho 'exist once'\n}\n"
    some_dir="$BATS_TMPDIR/some_temp_dir"
    some_file="$BATS_TMPDIR/some_file.sh"
    duplicate_file="$BATS_TMPDIR/duplicate.sh"
    duplicate_file2="$BATS_TMPDIR/duplicate2.sh"
    some_other_file="$BATS_TMPDIR/some_other_file.sh"
    mkdir -p $some_dir

    # some_other_file imports duplicate
    # some_file imports some_other_file and duplicate
    echo -e "$duplicate_contents" > $BATS_TMPDIR/duplicate.sh
    echo -e "$duplicate2_contents" > $BATS_TMPDIR/duplicate2.sh
    echo -e "import ./duplicate.sh\n$some_other_contents" > $BATS_TMPDIR/some_other_file.sh
    echo -e "import ./some_other_file.sh ./duplicate.sh\n$some_contents" > $BATS_TMPDIR/some_file.sh
}

function teardown() {
    if [[ -f $some_file ]]; then
        rm $some_file
    fi
    if [[ -d $some_dir ]]; then
        rm -r $some_dir
    fi
}

@test "duplicate file checking works" {
    # assumes bats tmpdir is: /tmp
    some_file="$BATS_TMPDIR/some_file.sh"
    run $source_combine $some_file
    echo "$output"
    number_of_occurences=$(grep -o 'should_only' <<< "$output" | wc -l)
    [[ $number_of_occurences -eq 1 ]]
}

# a simple check if
# we imported something called A
# already, then dont import A again
# if import A from X shows up again somewhere
@test "duplicate function checking works" {
    echo -e "$duplicate_contents" > $BATS_TMPDIR/duplicate.sh
    echo -e "import should_only from ./duplicate.sh\n$some_other_contents" > $BATS_TMPDIR/some_other_file.sh
    echo -e "import ./some_other_file.sh\nimport should_only from ./duplicate.sh\n$some_contents" > $BATS_TMPDIR/some_file.sh
    some_file="$BATS_TMPDIR/some_file.sh"
    run $source_combine $some_file
    echo "$output"
    number_of_occurences=$(grep -o 'should_only' <<< "$output" | wc -l)
    [[ $number_of_occurences -eq 1 ]]
}

# if you have:
# import X
# and later you have:
# import A from X
# we should not import A because
# the entirety of X was already imported
@test "dupl func check works for importAfromX before importX" {
    echo -e "$duplicate_contents" > $BATS_TMPDIR/duplicate.sh
    echo -e "import should_only from ./duplicate.sh\n$some_other_contents" > $BATS_TMPDIR/some_other_file.sh
    echo -e "import ./duplicate.sh\nimport ./some_other_file.sh\n$some_contents" > $BATS_TMPDIR/some_file.sh
    some_file="$BATS_TMPDIR/some_file.sh"
    run $source_combine $some_file
    echo "$output"
    number_of_occurences=$(grep -o 'should_only' <<< "$output" | wc -l)
    [[ $number_of_occurences -eq 1 ]]
}


# there was a bug with duplicate function checking
# for situations of >= 3 importAfromX.
# it would import everything after the second import
# more than twice. This test ensures that doesnt happen in the future
@test "dupl func check works many importAfromX" {
    echo -e "$duplicate2_contents" > $BATS_TMPDIR/duplicate2.sh
    echo -e "import ab1 ab2 ab3 from ./duplicate2.sh\n\necho 'somefile_contents'" > $BATS_TMPDIR/some_file.sh
    some_file="$BATS_TMPDIR/some_file.sh"
    run $source_combine $some_file
    echo "$output"
    number_of_occurences_ab1=$(grep -o 'ab1' <<< "$output" | wc -l)
    [[ $number_of_occurences_ab1 -eq 1 ]]
    number_of_occurences_ab2=$(grep -o 'ab2' <<< "$output" | wc -l)
    [[ $number_of_occurences_ab2 -eq 1 ]]
    number_of_occurences_ab3=$(grep -o 'ab3' <<< "$output" | wc -l)
    [[ $number_of_occurences_ab3 -eq 1 ]]
}
