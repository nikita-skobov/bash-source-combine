function setup() {
    source_combine=$BATS_TEST_DIRNAME/../source_combine_t.sh
    cd $BATS_TEST_DIRNAME
    some_contents="my_var=hello"
    some_other_contents="other_var=yeswoohoo"
    duplicate_contents="should_only() {\necho 'exist once'\n}\n"
    some_dir="$BATS_TMPDIR/some_temp_dir"
    some_file="$BATS_TMPDIR/some_file.sh"
    duplicate_file="$BATS_TMPDIR/duplicate.sh"
    some_other_file="$BATS_TMPDIR/some_other_file.sh"
    mkdir -p $some_dir

    # some_other_file imports duplicate
    # some_file imports some_other_file and duplicate
    echo -e "$duplicate_contents" > $BATS_TMPDIR/duplicate.sh
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
