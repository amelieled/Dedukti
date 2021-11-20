
#!/bin/bash

shift #Remove the reset regression parameter
shift #Remove the filename (which is duplicated anyway)
err_code=$1
shift

./dkcheck.native --no-color $@ 2>&1 | grep -i -q "^\[ERROR CODE:$err_code\]"
