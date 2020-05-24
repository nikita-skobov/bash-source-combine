function setup() {
    source_combine=$BATS_TEST_DIRNAME/../source_combine_t.sh
    cd $BATS_TEST_DIRNAME
    some_contents="my_var=hello"
    some_other_contents="other_var=yeswoohoo"
    duplicate_contents="should_only=exist_once"
    some_dir="$BATS_TMPDIR/some_temp_dir"
    some_file="$BATS_TMPDIR/some_file.sh"
    duplicate_file="$BATS_TMPDIR/duplicate.sh"
    some_other_file="$BATS_TMPDIR/some_other_file.sh"
    mkdir -p $some_dir

    # some_other_file imports duplicate
    # some_file imports some_other_file and duplicate
    echo "$duplicate_contents" > $BATS_TMPDIR/duplicate.sh
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

# the "duplicate" import contents should only appear once:
expected_output="#!/usr/bin/env bash
$some_other_contents
$duplicate_contents
$some_contents"

    [[ $output == "$expected_output" ]]
}
