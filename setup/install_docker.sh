#!/bin/bash

function installDocker(){
    echo "Installing Docker..."

    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https ca-certificates curl software-properties-common

    # Modern GPG key management (not deprecated apt-key)
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    sleep 5
    echo "✅ Docker and Docker Compose v2 installed"
}

function init(){
    if [ -z "$(which docker)" ]; then
        installDocker
    else
        echo "Docker already installed: $(docker --version)"
    fi
}

function main(){
    init
}

main
