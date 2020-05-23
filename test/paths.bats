function setup() {
    source_combine=$BATS_TEST_DIRNAME/../source_combine_t.sh
    cd $BATS_TEST_DIRNAME
    some_contents="my_var=hello"
    some_other_contents="other_var=yeswoohoo"
    some_dir="$BATS_TMPDIR/some_temp_dir"
    some_file="$BATS_TMPDIR/some_file.sh"
    some_other_file="$BATS_TMPDIR/some_other_file.sh"
    mkdir -p $some_dir

    # some_file imports some_other_file
    echo "$some_other_contents" > $BATS_TMPDIR/some_other_file.sh
    echo -e "import ./some_other_file.sh\n$some_contents" > $BATS_TMPDIR/some_file.sh
}

function teardown() {
    if [[ -f $some_file ]]; then
        rm $some_file
    fi
    if [[ -d $some_dir ]]; then
        rm -r $some_dir
    fi
}

@test "works with absolute path $BATS_TMPDIR/some_file" {
    # assumes bats tmpdir is: /tmp
    some_file="$BATS_TMPDIR/some_file.sh"
    run $source_combine $some_file
    [[ $output == *"#!/usr/bin/env bash"* ]]
    [[ $output == *"$some_contents"* ]]
    # because some_file imports some_other_file
    # the contents of some_other_file should exist:
    [[ $output == *"$some_other_contents"* ]]
}

@test "works with relative path: ./somefile" {
    cd $BATS_TMPDIR
    some_file="./some_file.sh"
    run $source_combine $some_file
    [[ $output == *"#!/usr/bin/env bash"* ]]
    [[ $output == *"$some_contents"* ]]
    [[ $output == *"$some_other_contents"* ]]
}

@test "works with relative path: ../somefile" {
    cd $some_dir
    some_file="../some_file.sh"
    run $source_combine $some_file
    [[ $output == *"#!/usr/bin/env bash"* ]]
    [[ $output == *"$some_contents"* ]]
    [[ $output == *"$some_other_contents"* ]]
}

@test "works with just file name: somefile" {
    cd $BATS_TMPDIR
    some_file="some_file.sh"
    run $source_combine $some_file
    [[ $output == *"#!/usr/bin/env bash"* ]]
    [[ $output == *"$some_contents"* ]]
    [[ $output == *"$some_other_contents"* ]]
}
