#!/bin/bash
# curl -sSL https://raw.githubusercontent.com/RockAfeller2013/EDR_Install/main/nstall_caldera_docker.sh | bash

# 1. Navigate to your Caldera directory

cd ~/caldera

# 2. Ensure all Git submodules are properly initialized
git submodule update --init --recursive

# 3. Install Node.js and npm (required to build the Magma plugin)
sudo apt update
sudo apt install -y nodejs npm

# 4. Build the Magma plugin
cd plugins/magma
npm install
npm run build
cd ../..

# 5. Completely rebuild the Docker containers
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d

# 6. Verify the containers are running
docker ps
