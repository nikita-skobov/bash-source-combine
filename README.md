# bash-source-combine

## Table of contents

* [What is it?](#what-is-it)
* [How to use it?](#how-to-use-it)
* [Installation](#installation)
* [Development](#development)
* [Examples](#examples)

## What is it?

bash-source-combine is a script that uses the import part of [bash oo-framework](https://github.com/niieani/bash-oo-framework) to accomplish a basic form of bash compilation.

Specifically, it can take import syntax in the form:

```sh
import ../folder/my_functions.sh
# OR:
import ./my_file.sh ../folder/my_functions.sh
# OR:
import func_one func_two from ../folder/my_functions.sh
# OR:
import {
    func_one
    func_two
} from ../folder/my_functions.sh
```

and it transcludes the contents of the imported files directly in place.

## How to use it?

bash-source-combine echoes out the combined file, so the basic usage is to redirect STDOUT to a file:

```sh
source_combine my_main_file.sh > my_main_file_combined.sh
```

If instead you wish to run my_main_file.sh instead of combining it into a file first, there is provided: `source_combine_run.sh` which uses source_combine (it finds it from your system path. See the [installation section](#installation)) and it sources the resulting combined script. It also allows for passing arguments. The first argument is the name of the script to combine and run. The remaining arguments are passed to the combined script:

```sh
source_combine_run my_main_file.sh --some-arg1 --some-arg2 etc
```

## Installation

The intended usage of these scripts is for them to be installed and be available on your system path. Specifically where you put these is up to you, but I prefer to put them in `/usr/local/bin`.

```sh
git clone https://github.com/nikita-skobov/bash-source-combine
cd bash-source-combine
sudo cp source_combine.sh /usr/local/bin/source_combine
sudo cp source_combine_run.sh /usr/local/bin/source_combine_run

# make sure they are executable:
sudo chmod +x /usr/local/bin/source_combine
sudo chmod +x /usr/local/bin/source_combine_run
```


## Development

As of version 2.0.0, this script is [self hosted!](https://en.wikipedia.org/wiki/Self-hosting_(compilers)) meaning it is compiled using itself. The `lib/` folder contains the source code `.bsc` files which when compiled produce the `source_combine.sh` script in the root of this directory. If you wish to develop on this project, follow the installation section above, and then you can do:

```sh
# make sure you are in the root of this repo
source_combine ./lib/source_combine.bsc > ./dev_source_combine.sh
chmod +x ./dev_source_combine.sh
```

And then you can use the new output `dev_source_combine.sh` instead of the provided one.

This is what the test running script does before it runs any of the tests:

## Testing

The tests are ran using [bats-core](https://github.com/bats-core/bats-core), and are located in the `test/` directory. To run the tests, make sure bats is installed, and then do:

```sh
# make sure you are in the root of the repo:
./test/run_tests.sh
```

Which will first compile a test version of `source_combine.sh` from the files in `lib/` as `source_combine_t.sh`, and it will use this newly compiled file to run the tests.


## Examples

### example1

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

### Example2

my_functions.sh:

```sh
do_this() {
    echo "$1"
}

do_something() {
    echo "$2"
}

do_that() {
    echo "$1 and $2"
}

```

my_main.sh:

```sh
import do_this do_that from ./my_functions.sh
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

do_this ()
{
    echo "$1"
}

do_that ()
{
    echo "$1 and $2"
}
do_this
do_that
```

You will notice that it uses a different function declaration syntax. The reason for this is when you use `import X from Y` syntax, the easiest way to accomplish that is to rely on the bash builtin `type` which will output a function definition in the above syntax.


### Example3


my_functions.sh:

```sh
do_this() {
    echo "$1"
}

do_something() {
    echo "$2"
}

do_that() {
    echo "$1 and $2"
}

```

my_main.sh:

```sh
import * from ./my_functions.sh
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
do_this () {
    echo "$1"
}

do_something() {
    echo "$2"
}

do_that () {
    echo "$1 and $2"
}
do_this
do_that
```

Note that the syntax:

```sh
import * from Y
```

will do the exact same as:

```sh
import Y
```

### Example4


my_functions.sh:

```sh
do_this() {
    echo "$1"
}

do_something() {
    echo "$2"
}

do_that() {
    echo "$1 and $2"
}

```

my_main.sh:

```sh
import {
    do_this
    do_that
} from ./my_functions.sh

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

do_this () 
{ 
    echo "$1"
}

do_that () 
{ 
    echo "$1 and $2"
}

do_this
do_that
```

# License

This project is distributed under the AGPL3 license. The license for this project is located in [./LICENSE](https://github.com/nikita-skobov/bash-source-combine/blob/master/LICENSE)

This project uses the following external libraries/projects:

- [bash-oo-framework](https://github.com/niieani/bash-oo-framework). The license file for this project is included in [./bash-oo-framework.txt](https://github.com/nikita-skobov/bash-source-combine/blob/master/bash-oo-framework.txt)
