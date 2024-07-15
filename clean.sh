#!/usr/bin/bash

remove_files() {
    rm -rf $1
}

docker_down() {
    docker compose down
}

# Are you sure?
echo "Are you sure you want to remove all files and stop the server? (y/n)"
read -r response
if [ $response == "y" ]; then
    docker_down
    remove_files "data/*"
    remove_files "logs/*"
    echo "All files have been removed and the server has been stopped."
else
    echo "No files have been removed."
fi