#!/usr/bin/env bash

################## START OF oo-bootstrap.sh ######################

# This code was taken directly from
# https://github.com/niieani/bash-oo-framework
# The following is the license located at the root
# of their repository:

###################### START LICENSE ######################
# The MIT License (MIT)

# Copyright (c) 2015 Bazyli Brzóska @ https://invent.life/

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###################### END LICENSE ######################

# The following file has been modified slightly to allow
# 'echoing' of bash files instead of sourcing them
# the functionality comes from a global variable
# ECHO_INSTEAD_OF_SOURCE being set to true (by default its false)

###########################
### BOOTSTRAP FUNCTIONS ###
###########################

ECHO_INSTEAD_OF_SOURCE=${ECHO_INSTEAD_OF_SOURCE:-false}

if [[ -n "${__INTERNAL_LOGGING__:-}" ]]
then
  alias DEBUG=":; "
else
  alias DEBUG=":; #"
fi

System::SourceHTTP() {
  local URL="$1"
  local -i RETRIES=3
  shift

  local source_file=""
  if hash curl 2>/dev/null
  then
    source_file=$(curl --fail -sL --retry $RETRIES "${URL}" || { [[ "$URL" != *'.sh' && "$URL" != *'.bash' ]] && curl --fail -sL --retry $RETRIES "${URL}.sh"; } || echo "e='Cannot import $URL' throw") "$@"
  else
    source_file=$(wget -t $RETRIES -O - -o /dev/null "${URL}" || { [[ "$URL" != *'.sh' && "$URL" != *'.bash' ]] && wget -t $RETRIES -O - -o /dev/null "${URL}.sh"; } || echo "e='Cannot import $URL' throw") "$@"
  fi


  if [[ ! -z "$source_file" ]]; then
    if [[ "$ECHO_INSTEAD_OF_SOURCE" == true ]]; then
      echo "$source_file"
    else
      builtin source <(echo "$source_file")
      __oo__importedFiles+=( "$URL" )
    fi
  else
    echo "FAILED TO IMPORT FROM HTTP: $URL"
  fi
}

System::SourcePath() {
  local libPath="$1"
  shift
  # echo trying $libPath
  if [[ -d "$libPath" ]]
  then
    local file
    for file in "$libPath"/*.sh
    do
      System::SourceFile "$file" "$@"
    done
  else
    System::SourceFile "$libPath" "$@" || System::SourceFile "${libPath}.sh" "$@"
  fi
}

declare -g __oo__fdPath=$(dirname <(echo))
declare -gi __oo__fdLength=$(( ${#__oo__fdPath} + 1 ))

System::ImportOne() {
  local libPath="$1"
  local __oo__importParent="${__oo__importParent-}"
  local requestedPath="$libPath"
  shift

  if [[ "$requestedPath" == 'github:'* ]]
  then
    requestedPath="https://raw.githubusercontent.com/${requestedPath:7}"
  elif [[ "$requestedPath" == './'* ]]
  then
    requestedPath="${requestedPath:2}"
  elif [[ "$requestedPath" == "$__oo__fdPath"* ]] # starts with /dev/fd
  then
    requestedPath="${requestedPath:$__oo__fdLength}"
  fi

  # [[ "$__oo__importParent" == 'http://'* || "$__oo__importParent" == 'https://'* ]] &&
  if [[ "$requestedPath" != 'http://'* && "$requestedPath" != 'https://'* ]]
  then
    requestedPath="${__oo__importParent}/${requestedPath}"
  fi

  if [[ "$requestedPath" == 'http://'* || "$requestedPath" == 'https://'* ]]
  then
    __oo__importParent=$(dirname "$requestedPath") System::SourceHTTP "$requestedPath"
    return
  fi

  # try relative to parent script
  # try with parent
  # try without parent
  # try global library
  # try local library
  {
    local localPath="$( cd "${BASH_SOURCE[1]%/*}" && pwd )"
    localPath="${localPath}/${libPath}"
    System::SourcePath "${localPath}" "$@"
  } || \
  # If user set a MAIN_DIR env var, try that:
  # if its not set, then this becomes the same as the next one.
  System::SourcePath "${MAIN_DIR}/${requestedPath}" "$@" || \
  System::SourcePath "${requestedPath}" "$@" || \
  System::SourcePath "${libPath}" "$@" || \
  System::SourcePath "${__oo__libPath}/${libPath}" "$@" || \
  System::SourcePath "${__oo__path}/${libPath}" "$@" || e="Cannot import $libPath" throw
}

System::Import() {
  local libPath
  for libPath in "$@"
  do
    System::ImportOne "$libPath"
  done
}

File::GetAbsolutePath() {
  # http://stackoverflow.com/questions/3915040/bash-fish-command-to-print-absolute-path-to-a-file
  # $1 : relative filename
  local file="$1"
  if [[ "$file" == "/"* ]]
  then
    echo "$file"
  else
    echo "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  fi
}

System::WrapSource() {
  local libPath="$1"
  shift

    if [[ "$ECHO_INSTEAD_OF_SOURCE" == true ]]; then
      # This file depends on ArrayContains, so even
      # if echo instead of source, still source that file:
      if [[ "$libPath" == *"Array/Contains"* ]]; then
        builtin source "$libPath" "$@" || throw "Unable to load $libPath"
      else
        local source_file=$(<"$libPath")
        echo "$source_file"
      fi
    else
      builtin source "$libPath" "$@" || throw "Unable to load $libPath"
    fi
}

System::SourceFile() {
  local libPath="$1"
  shift

  # DEBUG subject=level3 Log "Trying to load from: ${libPath}"
  [[ ! -f "$libPath" ]] && return 1 # && e="Cannot import $libPath" throw

  libPath="$(File::GetAbsolutePath "$libPath")"

  # echo "importing $libPath"

  # [ -e "$libPath" ] && echo "Trying to load from: ${libPath}"
  if [[ -f "$libPath" ]]
  then
    ## if already imported let's return
    # if declare -f "Array::Contains" &> /dev/null &&
    if [[ "${__oo__allowFileReloading-}" != true ]] && [[ ! -z "${__oo__importedFiles[*]}" ]] && Array::Contains "$libPath" "${__oo__importedFiles[@]}"
    then
      # DEBUG subject=level3 Log "File previously imported: ${libPath}"
      return 0
    fi

    # DEBUG subject=level2 Log "Importing: $libPath"

    __oo__importedFiles+=( "$libPath" )
    __oo__importParent=$(dirname "$libPath") System::WrapSource "$libPath" "$@"
    # eval "$(<"$libPath")"

  else
    :
    # DEBUG subject=level2 Log "File doesn't exist when importing: $libPath"
  fi
}

Array::Contains() {
  local element
  for element in "${@:2}"
  do
    [[ "$element" = "$1" ]] && return 0
  done
  return 1
}


System::Bootstrap() {
  ## note: aliases are visible inside functions only if
  ## they were initialized AFTER they were created
  ## this is the reason why we have to load files in a specific order
    local one="1"
    local two="2"
    if [[ $one == $two ]]; then
        echo "This is very bad!"
        exit 1
    fi
#   if ! System::Import Array/Contains
#   then
#     cat <<< "FATAL ERROR: Unable to bootstrap (missing lib directory?)" 1>&2
#     exit 1
#   fi
}

########################
### INITIALZE SYSTEM ###
########################

# From: http://wiki.bash-hackers.org/scripting/debuggingtips
export PS4='+(${BASH_SOURCE##*/}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# Bash will remember & return the highest exitcode in a chain of pipes.
# This way you can catch the error inside pipes, e.g. mysqldump | gzip
set -o pipefail

shopt -s expand_aliases
declare -g __oo__libPath="$( cd "${BASH_SOURCE[0]%/*}" && pwd )"
declare -g __oo__path="${__oo__libPath}/.."
declare -ag __oo__importedFiles

## stubs in case either exception or log is not loaded
namespace() { :; }
throw() { eval 'cat <<< "Exception: $e ($*)" 1>&2; read -s;'; }

System::Bootstrap

alias import="__oo__allowFileReloading=false System::Import"
alias source="__oo__allowFileReloading=true System::ImportOne"
alias .="__oo__allowFileReloading=true System::ImportOne"

declare -g __oo__bootstrapped=true

################## END OF oo-bootstrap.sh ######################



strip_unused_functions() {
    # 1 should be the string of the whole file
    # the rest of the arguments should be the function names
    # to be included
    # so strip out all of the other functions
    local file_data=()
    while IFS= read -r line; do
        # echo $line;
        file_data+=("$line")
    done <<< "$1"
    shift
    local file_data_len=${#file_data[@]}
    local ind=0
    while [[ $ind -lt $file_data_len ]]; do
        local lin=${file_data[ind]}
        local trimmed_line="${lin#"${lin%%[![:space:]]*}"}"
        if [[ $trimmed_line == "#!"* ]]; then
            # do not place several shebangs, this
            # compiler adds its own shebang at the top
            ((ind+=1))
            continue
        fi
        if [[ $trimmed_line == "#"* ]]; then
            # this is a comment
            echo "${file_data[ind]}"
            ((ind+=1))
            continue
        fi
        if [[ -z "$trimmed_line" ]]; then
            # echo "$i is empty!"
            echo "${file_data[ind]}"
            ((ind+=1))
            continue
        fi

        if [[ $trimmed_line == "import"* ]]; then
            # preserve imports
            echo "${file_data[ind]}"
        else
            break
        fi
        ((ind+=1))
    done

    # now we want to source everything after line ind:
    # and then simply echo out the function definitions
    # as given by type
    local rest_of_file=""
    while [[ $ind -lt $file_data_len ]]; do
        rest_of_file="$rest_of_file\n${file_data[ind]}"
        ((ind+=1))
    done
    builtin source <(echo -e "$rest_of_file")

    # iterate over function names, and echo out their definitions:
    for func_name in "$@"; do
        func_def=$(type "$func_name" 2> /dev/null)
        if [[ -z $func_def ]]; then
            echo "FAILED TO FIND IMPORT FOR '$func_name'"
            exit 1
        fi
        echo "${func_def#*function}"
    done
}


process_file() {
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
            local import_functions=("*")
            local remove_import="import "
            local actual_import_string="${trimmed_line##$remove_import}"
            if [[ $actual_import_string == *"from"* ]]; then
                # echo "# ITS A FROM JUST SKIP IT!"
                # echo "everything after 'from ' ${actual_import_string#*from\ }"
                # echo "everything before ' from' ${actual_import_string%from*}"
                # in this case the import string looks something like this:
                # import X Y from file
                # so first, get a string of the names of functions to be
                # imported
                local function_names="${actual_import_string%from*}"
                # then: change the actual import string to only contain
                # the filename:
                actual_import_string="${actual_import_string#*from\ }"

                # next, read an array of the function names
                # to be imported from this file
                local ind=0
                if [[ $function_names == "* " ]]; then
                    # if user just wants to do
                    # import * from X
                    import_functions[0]="*"
                else
                    for fname in $function_names; do
                        import_functions[$ind]="$fname"
                        ((ind+=1))
                    done
                fi
            fi
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
            if [[ ${import_functions[0]} == "*" ]]; then
                process_file "$the_actual_script"
            else
                local stripped_script=$(strip_unused_functions "$the_actual_script" "${import_functions[@]}")
                process_file "$stripped_script"
            fi
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

# no need to source it anymore
# since its included in this file
# builtin source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/oo-bootstrap.sh"

main_script="$1"

if [[ -z $main_script ]]; then
    echo "Must provide a path to the script that you wish to combine the source for." && exit 1
fi

if [[ ! -f $main_script ]]; then
    echo "$main_script is not a file" && exit 1
fi

PROCESSED_FILE_LIST=()

main_script_text=$(<"$main_script")
main_script_location="${main_script%/*}"

# this is an env variable set for the oo-bootstrap script
# to properly resolve relative path names of imports.
# by setting it to the main script, as long as all imports
# from the main script are relative it will find it
# no matter how deep/complex the nested import structure is
MAIN_DIR="$PWD"
if [[ "$main_script_location" != "$main_script" ]]; then
    # in this case the user entered a path to a script
    # either a ./file.sh
    # or ../../somefolder/file.sh
    # or somefolder/file.sh
    # or /absolutepath/to/folder/file.sh
    # so we must resolve the path:
    MAIN_DIR="$(cd ${main_script%/*} && pwd)"
fi

# use this shebang in the compiled file
echo "#!/usr/bin/env bash"

# this will echo out the whole compiled file
process_file "$main_script_text"
