#!/bin/bash
################################################################################
# BOLT.DIY USER MANAGER v2.0 - MAINTENANCE SCRIPT
# © Copyright Nbility 2025 - contact@nbility.fr
#
# Script de maintenance automatique (optimize, vacuum, clean sessions, etc.)
################################################################################

set -e

# Configuration
DB_CONTAINER="user-manager-db"
DB_NAME="user_manager"
DB_USER="user_manager"
DB_PASSWORD="${DB_PASSWORD:-changeme}"
SESSION_LIFETIME=86400  # 24 hours

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_info "═══════════════════════════════════════════════════════════════"
log_info "  USER MANAGER - MAINTENANCE"
log_info "  $(date '+%Y-%m-%d %H:%M:%S')"
log_info "═══════════════════════════════════════════════════════════════"

# 1. Nettoyer les sessions expirées
log_step "1/5 Nettoyage des sessions expirées..."
DELETED_SESSIONS=$(docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "DELETE FROM sessions WHERE last_activity < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL $SESSION_LIFETIME SECOND)); SELECT ROW_COUNT();" 2>/dev/null | tail -n 1)
log_info "Sessions supprimées: $DELETED_SESSIONS"

# 2. Nettoyer les logs d'audit anciens (> 90 jours)
log_step "2/5 Nettoyage des logs d'audit (>90 jours)..."
DELETED_LOGS=$(docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "DELETE FROM audit_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY); SELECT ROW_COUNT();" 2>/dev/null | tail -n 1)
log_info "Logs supprimés: $DELETED_LOGS"

# 3. Optimiser les tables
log_step "3/5 Optimisation des tables..."
TABLES=$(docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "SHOW TABLES;" 2>/dev/null)
for TABLE in $TABLES; do
    docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "OPTIMIZE TABLE $TABLE;" 2>/dev/null >/dev/null
    log_info "Table optimisée: $TABLE"
done

# 4. Analyser les tables
log_step "4/5 Analyse des tables..."
for TABLE in $TABLES; do
    docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "ANALYZE TABLE $TABLE;" 2>/dev/null >/dev/null
    log_info "Table analysée: $TABLE"
done

# 5. Vérifier l'intégrité
log_step "5/5 Vérification de l'intégrité..."
for TABLE in $TABLES; do
    STATUS=$(docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "CHECK TABLE $TABLE;" 2>/dev/null | awk '{print $NF}')
    if [ "$STATUS" = "OK" ]; then
        log_info "Table OK: $TABLE"
    else
        log_warning "Table avec problème: $TABLE ($STATUS)"
    fi
done

# Statistiques finales
log_info "═══════════════════════════════════════════════════════════════"
log_info "  MAINTENANCE TERMINÉE"
log_info "═══════════════════════════════════════════════════════════════"

# Afficher la taille de la base
DB_SIZE=$(docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = '$DB_NAME';" 2>/dev/null)
log_info "Taille de la base: ${DB_SIZE} MB"

# Afficher le nombre d'enregistrements par table
log_info "Nombre d'enregistrements par table:"
for TABLE in $TABLES; do
    COUNT=$(docker exec "$DB_CONTAINER" mysql -u"$DB_USER" -p"$DB_PASSWORD" -D"$DB_NAME" -se "SELECT COUNT(*) FROM $TABLE;" 2>/dev/null)
    log_info "  - $TABLE: $COUNT"
done

log_info "Maintenance terminée avec succès!"

exit 0
