#!/bin/bash
set -e

echo "███████ TrueColors Deployment Script ██████████"
echo "This script will set up your TrueColors instance with CrewAI and Ollama integration"

# Check if .env.production exists
if [ ! -f .env.production ]; then
  echo "ERROR: .env.production file not found!"
  echo "Please create this file with your configuration before running this script."
  exit 1
fi

# Make the ollama-init script executable
chmod +x bin/ollama-init

# Create necessary directories
mkdir -p ./postgres14
mkdir -p ./redis
mkdir -p ./ollama
mkdir -p ./public/system

# Pull and build Docker images
echo "Building Docker images (this might take a while)..."
docker-compose build

# Start the database first
echo "Starting database..."
docker-compose up -d db
echo "Waiting for database to initialize..."
sleep 10

# Run database migrations
echo "Running database migrations..."
docker-compose run --rm web rake db:migrate

# Start the remaining services
echo "Starting all services..."
docker-compose up -d

echo "Initializing Ollama (this will take some time to download models)..."
echo "You can check progress with: docker-compose logs -f ollama"

# Give Ollama a moment to start up
sleep 5

# Load agent configurations
echo "Loading CrewAI agent configurations..."
docker-compose exec web rake crew_bot:load_config

echo "████████████████████████████████████████████████"
echo "✅ Setup complete! Your TrueColors instance with CrewAI is now running."
echo ""
echo "Access your instance at: http://localhost:3000"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop all services: docker-compose down"
echo "████████████████████████████████████████████████" 