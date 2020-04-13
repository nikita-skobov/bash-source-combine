#!/usr/bin/env bash

# This script assumes
# That you have source_combine installed
# somewhere in your path

source_script="$1"
source_script_location="$(readlink -e $source_script)"
source_script_combined=$(source_combine "$source_script_location")

# removes the name of the script to be combined
# this way, when we source it, we pass all of the other
# arguments to the script
shift

source <(echo "$source_script_combined")
