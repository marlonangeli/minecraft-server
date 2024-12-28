#!/usr/bin/bash

# Constants and configurations
readonly SCRIPT_NAME=$(basename "$0")
readonly PROJECT_DIR="$HOME/docker/minecraft-server/bedrock"
readonly BACKUP_DIR="$HOME/docker/backups/minecraft-bedrock"
readonly REALMS_DIR="$PROJECT_DIR/realms"
readonly LOG_DIR="$PROJECT_DIR"
readonly LOG_FILE="$LOG_DIR/backup.log"
readonly DOCKER_COMPOSE_FILE="$PROJECT_DIR/compose.yml"
readonly CONTAINER_NAME="minecraft-bedrock-server"

cd "$PROJECT_DIR" || exit 1

# Time settings
readonly BACKUP_HOUR=02    # 2:00 AM
readonly START_HOUR=07     # 7:00 AM
readonly WARNING_TIME=60   # Warning time in seconds

# Logging function with improved formatting
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_levels=("DEBUG" "INFO" "WARNING" "ERROR" "CRITICAL")
    
    # Validate log level
    if [[ ! " ${log_levels[@]} " =~ " $level " ]]; then
        level="INFO"
    fi
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Error handling function
check_error() {
    if [ $? -ne 0 ]; then
        log "ERROR" "Operation failed: $1"
        exit 1
    fi
}

# Dependency verification
check_dependencies() {
    local deps=("docker")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "CRITICAL" "Missing dependency: $dep"
            exit 1
        fi
    done
    log "DEBUG" "All dependencies verified successfully"
}

# Container existence check
check_container() {
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log "ERROR" "Container not found: ${CONTAINER_NAME}"
        exit 1
    fi
    log "DEBUG" "Container ${CONTAINER_NAME} is present"
}

# Docker Compose file verification
check_docker_compose() {
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "CRITICAL" "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    log "DEBUG" "Docker Compose file verified successfully"
}

# Create necessary directories
create_directories() {
    # Create directories if not present
    if [ ! -d "$BACKUP_DIR" ] || [ ! -d "$LOG_DIR" ]; then
        log "WARNING" "Required directories not found, creating them"
        mkdir -p "$BACKUP_DIR" "$LOG_DIR"
        check_error "Failed to create required directories"
        log "INFO" "Directories created: $BACKUP_DIR, $LOG_DIR"
    fi

    # Create log file if not present
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
        check_error "Failed to create log file"
        log "INFO" "Log file created: $LOG_FILE"
    fi

    log "DEBUG" "Directories and files verified successfully"    
}

# Send server message to players
send_server_message() {
    local message="$1"
    if docker ps -q --filter "name=$CONTAINER_NAME" &>/dev/null; then
        docker exec "$CONTAINER_NAME" send-command "say $message" || true
        log "DEBUG" "Server message sent: $message"
    fi
}

# Stop the server
stop_server() {
    log "INFO" "Initiating server shutdown procedure"
    
    # Warn players
    send_server_message "Server will shut down in $WARNING_TIME seconds!"
    sleep $WARNING_TIME
    
    # Stop container
    log "INFO" "Stopping Docker container"
    docker compose down
    check_error "Failed to stop container"
    
    log "INFO" "Server stopped successfully"
}

# Start the server
start_server() {
    log "INFO" "Initiating server startup"
    docker compose up -d
    check_error "Server startup failed"
    log "INFO" "Server started successfully"
}

# Perform backup
do_backup() {
    log "INFO" "Starting backup process"
    
    # Check realms directory
    if [ ! -d "$REALMS_DIR" ]; then
        log "ERROR" "Realms directory not found: $REALMS_DIR"
        exit 1
    fi
    
    # Perform backup
    local backup_name="realms-$(date +'%Y%m%d-%H%M%S')"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "INFO" "Copying files to backup location: $backup_path"
    cp -r "$REALMS_DIR" "$backup_path"
    check_error "Backup file copy failed"
    
    # Compress backup
    log "INFO" "Compressing backup"
    tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    check_error "Backup compression failed"
    
    # Remove temporary directory
    rm -rf "$backup_path"
    
    # Remove old backups (keep last 7 days)
    find "$BACKUP_DIR" -name "realms-*.tar.gz" -mtime +7 -delete
    
    log "INFO" "Backup completed successfully"
}

# Main function
main() {
    local force=$1

    # Get current hour
    local current_hour
    current_hour=$(date +'%H')
    
    # Initial validations
    check_dependencies
    check_docker_compose
    create_directories

    if [ "$force" == "force" ]; then
        log "WARNING" "Forced server restart initiated"
        check_container
        stop_server
        sleep 5
        do_backup
        sleep 5
        start_server
        exit 0
    fi
    
    case $current_hour in
        $BACKUP_HOUR)
            log "INFO" "Executing backup routine at ${BACKUP_HOUR}:00"
            check_container
            stop_server
            do_backup
            ;;
            
        $START_HOUR)
            log "INFO" "Executing startup routine at ${START_HOUR}:00"
            start_server
            ;;
            
        *)
            log "DEBUG" "No scheduled tasks for current hour ($current_hour)"
            exit 0
            ;;
    esac
}

# Signal handling
trap 'log "ERROR" "Script interrupted"; exit 1' SIGINT SIGTERM

# Argument processing
if [ "$1" == "--force" ]; then
    main "force"
    exit 0
fi

# Execute main function
main
exit 0
