#!/bin/bash

# Local development setup script

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Azure Microservices Lab - Local Setup${NC}"
echo ""

# Install dependencies
echo -e "${YELLOW}Installing npm dependencies...${NC}"

cd gateway
npm install
cd ..

cd api
npm install
cd ..

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Start services
echo -e "${YELLOW}Starting services with Docker Compose...${NC}"
docker-compose up -d

echo ""
echo -e "${GREEN}✓ Services started!${NC}"
echo ""
echo "Available endpoints:"
echo "  Frontend:  http://localhost"
echo "  Gateway:   http://localhost:3000"
echo "  API:       http://localhost:5000"
echo ""
echo "View logs:"
echo "  docker-compose logs -f"
echo ""
echo "Stop services:"
echo "  docker-compose down"
