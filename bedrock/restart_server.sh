#!/usr/bin/bash

# Definição de constantes e configurações
readonly SCRIPT_NAME=$(basename "$0")
readonly BACKUP_DIR="$HOME/docker/backups/minecraft-bedrock"
readonly REALMS_DIR="$HOME/docker/minecraft-server/bedrock/realms"  # Ajuste conforme necessário
readonly BACKUP_DONE_FILE="/tmp/minecraft_backup_done"
readonly LOG_DIR="$HOME/docker/minecraft-server/bedrock"
readonly LOG_FILE="$LOG_DIR/backup.log"
readonly DOCKER_COMPOSE_FILE="compose.yml"
readonly CONTAINER_NAME="minecraft-bedrock-server"

# Configurações de horário
readonly BACKUP_HOUR=2    # 2:00 AM
readonly START_HOUR=6     # 6:00 AM
readonly WARNING_TIME=60  # Tempo de aviso em segundos

# Função para logging
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Função para verificar erros
check_error() {
    if [ $? -ne 0 ]; then
        log "ERROR" "$1"
        exit 1
    fi
}

# Função para verificar dependências
check_dependencies() {
    local deps=("docker")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "ERROR" "Dependência não encontrada: $dep"
            exit 1
        fi
    done
}

# Função para verificar se o container existe
check_container() {
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log "ERROR" "Container ${CONTAINER_NAME} não encontrado"
        exit 1
    fi
}

# Função para verificar se o Docker Compose file existe
check_docker_compose() {
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "Docker Compose file não encontrado: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
}

# Função para criar diretórios necessários
create_directories() {
    mkdir -p "$BACKUP_DIR" "$LOG_DIR"
    check_error "Falha ao criar diretórios"
}

# Função para enviar mensagem aos jogadores
send_server_message() {
    local message="$1"
    if docker ps -q --filter "name=$CONTAINER_NAME" &>/dev/null; then
        docker exec "$CONTAINER_NAME" send-command "say $message" || true
    fi
}

# Função para parar o servidor
stop_server() {
    log "INFO" "Iniciando processo de parada do servidor..."
    
    # Avisa os jogadores
    send_server_message "O servidor será desligado em $WARNING_TIME segundos!"
    sleep $WARNING_TIME
    
    # Para o container
    log "INFO" "Parando container Docker..."
    docker compose down
    check_error "Falha ao parar o container"
    
    log "INFO" "Servidor parado com sucesso"
}

# Função para iniciar o servidor
start_server() {
    log "INFO" "Iniciando servidor..."
    docker compose up -d
    check_error "Falha ao iniciar o servidor"
    log "INFO" "Servidor iniciado com sucesso"
}

# Função para realizar backup
do_backup() {
    log "INFO" "Iniciando processo de backup..."
    
    # Verifica se o backup já foi feito hoje
    if [ -f "$BACKUP_DONE_FILE" ]; then
        log "INFO" "Backup já realizado hoje"
        return 0
    fi
    
    # Verifica se o diretório realms existe
    if [ ! -d "$REALMS_DIR" ]; then
        log "ERROR" "Diretório realms não encontrado: $REALMS_DIR"
        exit 1
    fi
    
    # Realiza o backup
    local backup_name="realms-$(date +'%Y%m%d-%H%M%S')"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "INFO" "Copiando arquivos para $backup_path..."
    cp -r "$REALMS_DIR" "$backup_path"
    check_error "Falha ao realizar backup"
    
    # Comprime o backup
    log "INFO" "Comprimindo backup..."
    tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
    check_error "Falha ao comprimir backup"
    
    # Remove o diretório temporário
    rm -rf "$backup_path"
    
    # Marca o backup como realizado
    touch "$BACKUP_DONE_FILE"
    
    # Remove backups antigos (mantém últimos 7 dias)
    find "$BACKUP_DIR" -name "realms-*.tar.gz" -mtime +7 -delete
    
    log "INFO" "Backup concluído com sucesso"
}

# Função principal
main() {
    # Verifica hora atual
    local current_hour
    current_hour=$(date +'%H')
    
    # Validações iniciais
    check_dependencies
    check_docker_compose
    create_directories
    
    case $current_hour in
        $BACKUP_HOUR)
            log "INFO" "Executando rotina de backup (${BACKUP_HOUR}h)"
            check_container
            stop_server
            do_backup
            ;;
            
        $START_HOUR)
            log "INFO" "Executando rotina de início (${START_HOUR}h)"
            # Remove marca de backup do dia anterior
            rm -f "$BACKUP_DONE_FILE"
            start_server
            ;;
            
        *)
            log "INFO" "Nada a fazer neste horário ($current_hour)"
            exit 0
            ;;
    esac
}

# Tratamento de sinais
trap 'log "ERROR" "Script interrompido"; exit 1' SIGINT SIGTERM

# Executa função principal
main

exit 0