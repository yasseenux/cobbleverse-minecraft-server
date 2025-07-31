#!/bin/bash

# Cobbleverse Server Management Script
# Usage: ./server.sh [start|stop|restart|logs|backup|update]

SERVER_NAME="cobbleverse-server"
BACKUP_DIR="./backups"
WORLD_DIR="./world"

case "$1" in
    start)
        echo "Starting Cobbleverse server..."
        docker-compose up -d
        ;;
    stop)
        echo "Stopping Cobbleverse server..."
        docker-compose down
        ;;
    restart)
        echo "Restarting Cobbleverse server..."
        docker-compose restart
        ;;
    logs)
        echo "Showing server logs..."
        docker-compose logs -f
        ;;
    backup)
        echo "Creating world backup..."
        mkdir -p "$BACKUP_DIR"
        timestamp=$(date +%Y%m%d_%H%M%S)
        tar -czf "$BACKUP_DIR/world_backup_$timestamp.tar.gz" "$WORLD_DIR"
        echo "Backup created: $BACKUP_DIR/world_backup_$timestamp.tar.gz"
        ;;
    update)
        echo "Updating server..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|backup|update}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the server"
        echo "  stop    - Stop the server"
        echo "  restart - Restart the server"
        echo "  logs    - Show server logs"
        echo "  backup  - Create world backup"
        echo "  update  - Update and rebuild server"
        exit 1
        ;;
esac
