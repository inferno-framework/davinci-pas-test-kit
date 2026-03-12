#!/bin/sh

# Exit on error
set -e

echo "Starting background services..."
docker compose -f docker-compose.background.yml up -d

echo "Installing gems..."
bundle install

echo "Running migrations..."
bundle exec inferno migrate

echo "Starting Inferno on port 4567..."
# Ensure APP_ENV is development so .env.development is loaded
export APP_ENV=development
bundle exec inferno start
