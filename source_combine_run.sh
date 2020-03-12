#!/usr/bin/env bash

# This script assumes
# That you have source_combine installed
# somewhere in your path

source_script="$1"
source_script_location="$(readlink -e $source_script)"
source_script_dir="${source_script_location%/*}"
source_script_name="${source_script_location##*/}"
source_script_name_without_extension="${source_script_name%.*}"

# echo "source script: $source_script"
# echo "source script name: $source_script_name"
# echo "source script name without extension: $source_script_name_without_extension"
# echo "source script location: $source_script_location"
# echo "source script dir: $source_script_dir"

source_combine_prefix="COMBINED_"
output_name="$source_script_dir/$source_combine_prefix$source_script_name"

source_combine "$source_script_location" > "$output_name"
chmod +x "$output_name"

bash $output_name

rm "$output_name"
