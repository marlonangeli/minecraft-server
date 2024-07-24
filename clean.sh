#!/usr/bin/bash

docker_down() {
    docker compose down
}

docker_rm_volume() {
    docker volume rm minecraft-data
}

# Are you sure?
echo "Are you sure you want to remove all files and stop the server? (y/n)"
read -r response
if [ $response == "y" ]; then
    docker_down
    docker_rm_volume
    echo "All files have been removed and the server has been stopped."
else
    echo "No files have been removed."
fi