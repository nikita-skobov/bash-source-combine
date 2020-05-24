#!/usr/bin/env bash

# use the currently installed source combine
# on the source combine library to create a temporary
# test version of it:
source_combine lib/source_combine.bsc > source_combine_t.sh
chmod +x source_combine_t.sh
bats test/
