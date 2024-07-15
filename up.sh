#!/usr/bin/bash

move_file() {
    # Check if a filename was provided as an argument
    if [ -z "$1" ]; then
        echo "Usage: $0 <filename>"
        exit 1
    fi

    # Name of the file to be moved
    file_to_move="$1"

    # Check if the file exists
    if [ ! -f "$file_to_move" ]; then
        echo "File '$file_to_move' does not exist."
        exit 1
    fi

    # Destination directory
    temp_dir="temp"

    # Create the temp directory if it does not exist
    if [ ! -d "$temp_dir" ]; then
        mkdir "$temp_dir"
        echo "Directory '$temp_dir' created."
    fi

    # Move the file to the temp directory
    mv "$file_to_move" "$temp_dir"
    echo "File '$file_to_move' moved to '$temp_dir'."
}

# Client side mods
move_file "mods/oculus-mc1.19.2-1.6.4.jar"

docker compose up -d
echo "Stack is up."