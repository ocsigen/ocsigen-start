#!/bin/bash

# The only motivation of this script is to find automatically
# a 'pg_ctl' binary on the system. Because on ubuntu and debian,
# the path of the binary is not included in the PATH variable.

# # Update: The right solution on Debian/Ubuntu seems to be pg_ctlcluster
# # -- Vincent 

# The script create a file (named $file, see below) if it does
# not exist.
# If it does exist, we just output the name of the script.

# The name of the script used by the Makefile
file="pg_ctl"

# Create the script used by the Makefile
function symbolic_link_to_pg_ctl {
    ln -s $1 $file
}

# Interactive yes/no
function yes_no {
    read input 
    input=$( echo $input | tr '[:upper:]' '[:lower:]' )
    case $input in
        "yes"|"y"|"") true;;
        "no"|"n") false;;
        *)
            echo "Please enter 'yes'/'y' or 'no'/'n'"
            yes_no
            ;;
    esac
}

# We check if we have already created a script for 'pg_ctl'
if [ -f $file ]; then
    echo $file
    exit 0
fi

# Default 'pg_ctl'
pg_ctl=$( which pg_ctl )

# If 'pg_ctl' is found, write it into the script used by the Makefile
if [ $? = "0" ]; then
    symbolic_link_to_pg_ctl $pg_ctl
    exit 0
fi

# If 'pg_ctl' is not found, we try to found it using locate
if [ $? = "0" ]; then

    echo "We didn't find pg_ctl in the curent PATH environment variable..."
    echo "We're looking for it somewhere else on your system..."

    # The list of 'pg_ctl' binaries
    bins=$( locate pg_ctl | grep -E "pg_ctl$" )
    first=$( echo $bins | head -1 )

    # We didn't find any 'pg_ctl'
    if [ "$first" = "" ]; then
        echo -n "No 'pg_ctl' binary found on your system. Make sure to have"
        echo "postgresql installed."
        exit 1;
    fi

    # We iterate through binaries and ask to user which one should we use
    for bin in $bins; do

        echo $bin
        echo "Do you want to use this one ? (Y/n)"

        # Ask to the user
        yes_no

        # A choice has been selected
        if [ $? = "0" ]; then
            symbolic_link_to_pg_ctl $bin
            exit 0
        fi
    done

    # No choices have been selected, quit
    echo "No 'pg_ctl' choices selected. abort."
    exit 1
fi
