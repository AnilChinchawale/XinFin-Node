#!/bin/bash

echo "Upgrading XDC Network Node..."

# Backup config
cp .env .env.bak 2>/dev/null || true

# Pull latest configs
git stash
git pull

# Restore config
mv .env.bak .env 2>/dev/null || true

# Pull latest Docker image and restart
docker compose pull
docker compose down
docker compose up -d

echo "Upgrade complete."
