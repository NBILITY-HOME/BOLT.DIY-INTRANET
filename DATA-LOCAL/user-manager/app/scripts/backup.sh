#!/bin/bash
################################################################################
# BOLT.DIY USER MANAGER v2.0 - BACKUP SCRIPT
# © Copyright Nbility 2025 - contact@nbility.fr
#
# Script de sauvegarde automatique de la base de données et des fichiers
################################################################################

set -e

# Configuration
BACKUP_DIR="/var/backups/user-manager"
DB_CONTAINER="user-manager-db"
DB_NAME="user_manager"
DB_USER="user_manager"
DB_PASSWORD="${DB_PASSWORD:-changeme}"
RETENTION_DAYS=30
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonctions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier que le dossier de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
    log_info "Création du dossier de backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# Backup de la base de données
log_info "Début du backup de la base de données..."
BACKUP_FILE="$BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz"

if docker exec "$DB_CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" | gzip > "$BACKUP_FILE"; then
    log_info "Backup de la base de données réussi: $BACKUP_FILE"

    # Vérifier la taille du fichier
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_info "Taille du backup: $SIZE"
else
    log_error "Échec du backup de la base de données"
    exit 1
fi

# Backup des logs (optionnel)
LOG_BACKUP_FILE="$BACKUP_DIR/logs_backup_$TIMESTAMP.tar.gz"
if [ -d "/var/log/user-manager" ]; then
    log_info "Backup des logs..."
    tar -czf "$LOG_BACKUP_FILE" -C /var/log user-manager 2>/dev/null || log_warning "Aucun log à sauvegarder"
fi

# Nettoyage des anciens backups
log_info "Nettoyage des backups de plus de $RETENTION_DAYS jours..."
find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "logs_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# Afficher le nombre de backups restants
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "db_backup_*.sql.gz" -type f | wc -l)
log_info "Nombre total de backups conservés: $BACKUP_COUNT"

# Résumé
log_info "Backup terminé avec succès!"
log_info "Fichiers créés:"
log_info "  - Base de données: $BACKUP_FILE"
[ -f "$LOG_BACKUP_FILE" ] && log_info "  - Logs: $LOG_BACKUP_FILE"

exit 0
