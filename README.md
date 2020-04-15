# bash-source-combine

## What is it?

Bash source combine is a script that uses the import part of [bash oo-framework](https://github.com/niieani/bash-oo-framework) to accomplish a basic form of bash compilation.

Specifically, it can take import syntax in the form:

```sh
import ../folder/my_functions.sh
```

and it transcludes the content of `../folder/my_functions.sh` directly in place.


## How to use it?

bash source combine simply echoes out the combined file, so the basic usage is to redirect STDOUT to a file like so:

```sh
source_combine my_main_file.sh > my_main_file_combined.sh
```

If instead you wish to run my_main_file.sh instead of combining it into a file first, there is provided: `source_combine_run.sh` which uses source_combine (it finds it from your system path. see the installation section) and it sources the resulting combined script. It also allows for passing arguments. It only needs the first positional argument to be the name of the file being combined, and then it passes the rest of the arguments directly into the combined script:

```sh
source_combine_run my_main_file.sh --some-arg1 --some-arg2 etc
```

## Installation

The intended usage of these scripts is for them to be installed and be available on your system path. Specifically where you put these is up to you, but I prefer to put them in `/usr/local/bin`.

```sh
git clone <this_repo_name>
cd <this_repo_name>
sudo cp source_combine.sh /usr/local/bin/source_combine
sudo cp source_combine_run.sh /usr/local/bin/source_combine_run

# make sure they have are executable:
sudo chmod +x /usr/local/bin/source_combine
sudo chmod +x /usr/local/bin/source_combine_run
```


## Examples

my_functions.sh:

```sh
do_this() {
    echo "$1"
}

do_that() {
    echo "$1 and $2"
}
```

my_main.sh:

```sh
import ./my_functions.sh
do_this
do_that
```

When you run:
```sh
source_combine my_main.sh > my_main_combined.sh
```

The output file `my_main_combined.sh` will look like:

```sh
#!/usr/bin/env bash
do_this() {
    echo "$1"
}

do_that() {
    echo "$1 and $2"
}

do_this
do_that
```

Which can then be ran as:

```sh
./my_main_combined.sh arg1 arg2
# will output:
# arg1
# arg1 and arg2
```

Or you can run it directly without outputting a file via:

```sh
source_combine_run my_main.sh arg1 arg2
# will output:
# arg1
# arg1 and arg2
```
