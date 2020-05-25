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
  ## Update May 2020:
  ## I commented out this line because I use a MAIN_DIR
  ## variable below, instead of relying on BASH_SOURCE
  # {
  #   local localPath="$( cd "${BASH_SOURCE[1]%/*}" && pwd )"
  #   localPath="${localPath}/${libPath}"
  #   System::SourcePath "${localPath}" "$@"
  # } || \
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
# arg: $1: the trimmed line to test.
# returns true if the line is a comment, or if its empty
# which are the cases we want to echo the line
# otherwise we return false, to prevent echoing
should_echo() {
    if [[ $1 == "#"* || -z "$1" ]]; then
        return 0
    fi
    return 1
}

# arg: $1 the trimmed line to test.
# returns true if its a shebang
should_continue() {
    if [[ $1 == "#!"* ]]; then
        return 0
    fi
    return 1
}

# arg: $1 the trimmed line to test.
# returns true if it contains 'import'
should_process_import() {
    if [[ $1 == "import"* ]]; then
        return 0
    fi
    return 1
}


# 1 should be the string of the whole file
# the rest of the arguments should be the function names
# to be included
# so strip out all of the other functions
strip_unused_functions() {
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

# args: $1 the full path of the file being checked.
# If the full path exists in the full path cache, return true.
file_has_been_imported() {
    for file_name in "${full_path_cache[@]}"; do
        if [[ $1 == $file_name ]]; then
            # file has been imported already:
            return 0
        fi
    done
    # file has not been imported yet:
    return 1
}

# a variable of absolute paths to files that
# have been imported. before importing a file
# check if its full path exists here.
full_path_cache=()

# a variable of function names that have been imported as
# import A from X. This variable does not contain
# function names that are imported as import X, because
# when we import an entire file, we don't source/evaluate
# what is in the file. so therefore something like:
# import A from X
# import X
# will contain multiple functions A.
function_name_cache=()

process_file() {
    local file_data=()
    while IFS= read -r line; do
        file_data+=("$line")
    done <<< "$1"

    local still_sourcing=true

    local skip_i=0
    for i in "${!file_data[@]}"; do
        # if we are done processing import statements
        # just echo the line as is:
        if [[ "$still_sourcing" == false ]]; then
            echo "${file_data[i]}"
            continue
        fi

        # these lines exist because of multi-line
        # import statements
        # if the 'parse_import_statement' sets the skip_i
        # variable, then we skip the line until i reaches
        # skip_i. at that point, we set skip_i back to 0
        # and resume normal parsing
        if [[ $i -lt $skip_i ]]; then
            continue
        elif [[ $i == $skip_i && $skip_i != 0 ]]; then
            skip_i=0
            continue
        fi

        local current_line=${file_data[i]}
        # remove whitespace:
        local trimmed_line="${current_line#"${current_line%%[![:space:]]*}"}"

        if should_process_import "$trimmed_line"; then
            local import_files_list=()
            local import_keywords_list=()
            parse_import_statement file_data $i import_files_list import_keywords_list 
            local import_files_list_without_duplicates=()
            local import_keywords_list_without_duplicates=()

            # only check file duplicates if the import is the entire file
            if [[ "${import_keywords_list[0]}" == "*" ]]; then
                for j in ${import_files_list[@]}; do
                    local full_path=$(readlink -f $j)
                    if ! file_has_been_imported "$full_path"; then
                        # this is a file that has not been imported before
                        # so add it to the cache, to prevent it from
                        # being imported again in the future
                        import_files_list_without_duplicates+=("$j")
                        full_path_cache+=("$full_path")
                    fi
                done
            else
                # in the event that import keywords list is not everything: "*"
                # then the import files list should just be a single file
                # ie: "import A from X", you cannot have "import A from X Y"

                # first: theres no need to import any keyword
                # if the file has been imported already entirely
                # so check for that:
                local full_path=$(readlink -f ${import_files_list[0]})
                if ! file_has_been_imported "$full_path"; then
                    import_files_list_without_duplicates=("${import_files_list[@]}")
                    # check for keyword duplicates by iterating over
                    # the keywords that we are importing:
                    for j in ${import_keywords_list[@]}; do
                        if [[ ${#function_name_cache[@]} -eq 0 ]]; then
                            # cache is empty, so of course we import j:
                            import_keywords_list_without_duplicates+=("$j")
                            function_name_cache+=("$j")
                        else
                            # cache is not empty, check if the import keyword j
                            # exists in the function name cache. if it does
                            # not exist, import it, and add it to the cache
                            for k in ${function_name_cache[@]}; do
                                if [[ $j != $k ]]; then
                                    import_keywords_list_without_duplicates+=("$j")
                                    function_name_cache+=("$j")
                                fi
                            done
                        fi
                    done
                fi
            fi

            # if we removed all duplicate import files
            # and the remaining list
            # is empty, skip this import
            if [[ ${#import_files_list_without_duplicates[@]} -eq 0 ]]; then
                continue
            fi

            local currdir="$PWD"
            # TODO: change this to get proper paths to ALL import args
            # for now, this is only using the first import arg
            # which for my use case is enough, but I need to implement
            # this in the future to enable things such as:
            # import folder_one/function_one.sh folder_two/function_two.sh
            local nextdir="${import_files_list_without_duplicates[0]%/*}"
            local the_actual_script=$(import "${import_files_list_without_duplicates[@]}")
            if [[ ! -f $nextdir ]]; then
                cd $nextdir
                MAIN_DIR="$PWD"
            fi
            if [[ ${import_keywords_list[0]} == "*" ]]; then
                process_file "$the_actual_script"
            elif [[ ${#import_keywords_list_without_duplicates[@]} != "0" ]]; then
                local stripped_script=$(strip_unused_functions "$the_actual_script" "${import_keywords_list_without_duplicates[@]}")
                process_file "$stripped_script"
            fi

            cd $currdir
            MAIN_DIR="$PWD"
            continue
        elif should_continue "$trimmed_line"; then
            continue
        elif should_echo "$trimmed_line"; then
            echo "$current_line"
            continue
        else
            echo "$current_line"
            still_sourcing=false
        fi
    done
}
# valid import syntax:

# import file
# import file1 file2
# import item from file
# import item1 item2 from file
## brackets optional if on a single line:
# import { item1 item2 } from file

## brackets required if using multiple lines
# import {
#   item1
#   item2
# } from file


# args: $1 is name of the array of file data.
# $2 is the index of the array to start parsing, ie:
# it is expected that $2 is a line that contains the word 'import'.
# $3 is the name of the output array to put the
# list of filenames to import. $4 is the name of the
# output array to put the list of keywords to import
# from the filenames
parse_import_statement() {
    local -n _lines="$1"
    local ind="$2"
    local -n _import_files_list="$3"
    local -n _import_keywords_list="$4"

    local num_lines="${#_lines[@]}"
    local current_line="${_lines[ind]}"
    local remove_import="import "
    local actual_import_string="${current_line##$remove_import}"

    if [[
        $current_line != *" from "* && \
        $current_line != *"{"*
    ]]; then
        # no from statement
        # just a regular import X [...Y] statement
        for i in $actual_import_string; do
            _import_files_list+=("$i")
        done
        _import_keywords_list=("*")
    elif [[
        $current_line == *" from "*
    ]]; then
        # has a from statement, but its a one line import:
        # import A [...B] from X
        local keywords="${actual_import_string%from*}"
        # remove everything before the from keyword:
        local remove_from="from\ "
        actual_import_string="${actual_import_string#*$remove_from}"
        
        # in the case of import A B from X, you can only
        # supply a single import file, so no need to loop
        # over the import string, at this point
        # the import string is just the file that
        # should be imported:
        # we iterate here incase theres whitespace
        # on after the from, ie: 'from     X'
        for i in $actual_import_string; do
            _import_files_list+=("$i")
        done

        # explicitly check if its just a star
        # otherwise, the loop below will loop over files...
        if [[ $keywords == "* "* ]]; then
            _import_keywords_list+=("*")
            return 0
        fi

        for kname in $keywords; do
            if [[ $kname != "{" && $kname != "}" ]]; then
                _import_keywords_list+=("$kname")
            fi
        done
    elif [[
        $current_line == *"{"*
    ]]; then
        # failed to find a 'from' keyword, but we did see an opening
        # bracket. this means its a multiple line import statement
        # so go to the next line,
        # and parse the lines until we find a closing bracket:
        ((ind+=1))
        while [[ $ind -lt $num_lines ]]; do
            current_line="${_lines[ind]}"
            if [[ $current_line == *"}"* ]]; then
                # reached the end of the keywords,
                # this line contains a from X:
                local remove_from="from\ "
                actual_import_string="${current_line#*$remove_from}"
                # we iterate here incase theres whitespace
                # on after the from, ie: 'from     X'
                for i in $actual_import_string; do
                    _import_files_list+=("$i")
                done
                skip_i=$ind
                return 0
            fi

            for kname in $current_line; do
                _import_keywords_list+=("$kname")
            done
            ((ind+=1))
        done
    fi
}

ECHO_INSTEAD_OF_SOURCE="true"

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
# save users location to return back to it afterwards
BEFORE_MAIN_DIR="$PWD"
if [[ "$main_script_location" != "$main_script" ]]; then
    # in this case the user entered a path to a script
    # either a ./file.sh
    # or ../../somefolder/file.sh
    # or somefolder/file.sh
    # or /absolutepath/to/folder/file.sh
    # so we must resolve the path:
    MAIN_DIR="$(cd ${main_script%/*} && pwd)"
    cd $MAIN_DIR
fi

# use this shebang in the compiled file
echo "#!/usr/bin/env bash"

# this will echo out the whole compiled file
process_file "$main_script_text"

# go back to where the user was
cd $BEFORE_MAIN_DIR
