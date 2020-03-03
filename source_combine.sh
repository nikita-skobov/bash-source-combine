#!/usr/bin/env bash

# # eg:
# # file1.sh
# # load my_function:
# source ./my_function.sh
# my_function "hello"


# # my_function.sh
# my_function() {
#   echo "input: $1"   
# }

function process_file() {
    local file_data=()
    while IFS= read -r line; do
        # echo $line;
        file_data+=("$line")
    done <<< "$1"

    local still_sourcing=true

    for i in "${!file_data[@]}"; do
        if [[ "$still_sourcing" == false ]]; then
            echo "${file_data[i]}"
            continue
        fi

        local lin=${file_data[i]}
        local trimmed_line="${lin#"${lin%%[![:space:]]*}"}"

        if [[ $trimmed_line == "#!"* ]]; then
            # do not place several shebangs, this
            # compiler adds its own shebang at the top
            continue
        fi
        if [[ $trimmed_line == "#"* ]]; then
            # this is a comment
            echo "${file_data[i]}"
            continue
        fi
        if [[ -z "$trimmed_line" ]]; then
            # echo "$i is empty!"
            echo "${file_data[i]}"
            continue
        fi

        if [[ $trimmed_line == "import"* ]]; then
            local remove_import="import "
            local actual_import_string="${trimmed_line##$remove_import}"
            # make an array of import args:
            IFS=' ' read -ra input_args <<< "$actual_import_string"


            # Loop through the input args, and ensure
            # that we have not already imported any of them.
            local input_args_without_duplicates=()
            for i in ${!input_args[@]}; do
                local import_name="${input_args[i]}"
                if [[ "$import_name" != "http"* ]]; then
                    # if its http/https, leave import name as is
                    # otherwise, get full path to the file:
                    local dir_of_import="$(cd $MAIN_DIR/${input_args[i]%/*} && pwd)"
                    import_name="$dir_of_import/${input_args[i]}"
                fi
                if [[ " ${PROCESSED_FILE_LIST[@]} " =~ " ${import_name} " ]]; then
                    continue
                fi

                input_args_without_duplicates+=("${input_args[i]}")
                PROCESSED_FILE_LIST+=("$import_name")
            done
            
            the_actual_script=$(import "${input_args_without_duplicates[@]}")
            process_file "$the_actual_script"
            continue
        elif [[ $trimmed_line == "source"* && $trimmed_line == *"oo-bootstrap"* ]]; then
            continue
            # this is sourcing the bootstrap library which is unecessary for compiled files
        elif [[ $trimmed_line == "builtin source"* && $trimmed_line == *"oo-bootstrap"* ]]; then
            # this is sourcing the bootstrap library which is unecessary for compiled files
            # echo "${file_data[i]}"
            continue
        elif [[ $trimmed_line == "MAIN_DIR"* ]]; then
            # its ok for the files to have MAIN_DIR at the top
            # if they want to be ran as is without compilation
            echo "${file_data[i]}"
        else
            # once we find the first non-comment, non-import
            # non-source, non-main_dir line, we stop sourcing
            # This means that WE DO NOT want to add any imports
            # in the middle of the file.
            echo "${file_data[i]}"
            still_sourcing=false
        fi
    done
}



ECHO_INSTEAD_OF_SOURCE="true"
builtin source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/oo-bootstrap.sh"

main_script="$1"

if [[ -z $main_script ]]; then
    echo "Must provide a path to the script that you wish to combine the source for." && exit 1
fi

if [[ ! -f $main_script ]]; then
    echo "$main_script is not a file" && exit 1
fi

PROCESSED_FILE_LIST=()

main_script_text=$(<"$main_script")

# this is an env variable set for the oo-bootstrap script
# to properly resolve relative path names of imports.
# by setting it to the main script, as long as all imports
# from the main script are relative it will find it
# no matter how deep/complex the nested import structure is
MAIN_DIR="$(cd ${main_script%/*} && pwd)"

# use this shebang in the compiled file
echo "#!/usr/bin/env bash"

# this will echo out the whole compiled file
process_file "$main_script_text"
