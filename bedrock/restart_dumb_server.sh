#!/usr/bin/bash

# Diretórios e arquivos
BACKUP_DIR=~/docker/backups/minecraft-bedrock
REALMS_DIR=./realms  # Substitua pelo caminho correto da pasta realms se necessário
BACKUP_DONE_FILE="/tmp/backup_done_today"

# Horários de inatividade
START_INACTIVE=2  # 2:00
END_INACTIVE=6    # 6:00

# Função para exibir uso do script
usage() {
    echo "Uso: $0 [-y]"
    echo " -y : Confirma automaticamente sem perguntar"
    exit 1
}

# Verifica argumento -y
CONFIRM=false
while getopts "y" opt; do
  case ${opt} in
    y ) CONFIRM=true ;;
    * ) usage ;;
  esac
done

# Obtém a hora atual (somente horas)
CURRENT_HOUR=$(date +'%H')

# Se estiver no período de inatividade, desliga o servidor e, se for a última execução do dia, faz o backup
if (( CURRENT_HOUR >= START_INACTIVE && CURRENT_HOUR < END_INACTIVE )); then
    echo "Período de inatividade entre 2:00 e 6:00. Parando o servidor Minecraft..."

    docker exec minecraft-bedrock-server send-command say "O servidor será desligado em 10 segundos." 
    sleep 10

    # Para o container Docker
    docker compose down

    # Realiza o backup uma vez ao dia, se ainda não foi feito
    if [ ! -f "$BACKUP_DONE_FILE" ]; then
        echo "Fazendo backup da pasta realms..."
        
        # Cria o diretório de backup, se não existir
        mkdir -p "$BACKUP_DIR"
        
        # Copia a pasta realms com um timestamp
        cp -r "$REALMS_DIR" "$BACKUP_DIR/realms-$(date +'%Y%m%d%H%M%S')"
        
        # Marca o backup como feito
        touch "$BACKUP_DONE_FILE"
        echo "Backup concluído e servidor parado para o dia."
    else
        echo "Backup já foi feito hoje. Servidor parado para o dia."
    fi

    exit 0
fi

# Fora do período de inatividade, verifica se é a primeira execução do dia
if (( CURRENT_HOUR >= END_INACTIVE )); then
    # Remove o arquivo de controle do backup ao iniciar o servidor no novo dia
    if [ -f "$BACKUP_DONE_FILE" ]; then
        rm "$BACKUP_DONE_FILE"
        echo "Primeira execução do dia. Iniciando o servidor Minecraft..."
    else
        # Se o arquivo de controle não existir, o servidor já está rodando (reinicia)
        docker exec minecraft-bedrock-server send-command say "O servidor será reiniciado em 10 segundos." 
        sleep 10

        # Para o container Docker
        docker compose down
        echo "Reiniciando o servidor Minecraft..."
        sleep 10
    fi


    # Inicia o servidor
    docker compose up -d
    echo "Servidor Minecraft iniciado."
fi


