#!/bin/bash
#
# auto_deploy.sh - Script d'automatisation de deploiement (TP DevOps UCAD)
#
# Repond aux 3 questions de la Partie 1 :
#   1. L'URL du depot est passee en parametre.
#   2. Fonction de log avec horodatage.
#   3. Lancement de l'application en arriere-plan + sauvegarde du PID.
#
# Usage :
#   ./auto_deploy.sh <URL_DU_DEPOT> [NOM_DU_DOSSIER]
# Exemple :
#   ./auto_deploy.sh https://github.com/votre-nom/votre-app.git mon_app
#
# On arrete le script a la moindre erreur (-e), sur variable non definie (-u)
# et on propage les erreurs dans les pipes (-o pipefail).
set -euo pipefail

# ----------------------------------------------------------------------------
# Couleurs pour l'affichage
# ----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Fichiers de log et de PID
LOG_FILE="deploy.log"
PID_FILE=".app.pid"

# ----------------------------------------------------------------------------
# Question 2 : fonction de log avec horodatage
# Ecrit a la fois a l'ecran (avec couleur) et dans deploy.log (sans couleur).
# ----------------------------------------------------------------------------
log() {
  local level="$1"; shift
  local message="$*"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  local color="$NC"
  case "$level" in
    INFO)  color="$GREEN" ;;
    WARN)  color="$YELLOW" ;;
    ERROR) color="$RED" ;;
  esac

  # Affichage colore a l'ecran
  echo -e "${color}[${timestamp}] [${level}] ${message}${NC}"
  # Trace persistante sans codes couleur
  echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# Petit utilitaire : verifie qu'une commande existe
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log ERROR "$1 requis mais non installe. Abandon."
    exit 1
  }
}

# ----------------------------------------------------------------------------
# Question 1 : recuperation de l'URL du depot en parametre
# ----------------------------------------------------------------------------
if [ "$#" -lt 1 ]; then
  log ERROR "Usage : $0 <URL_DU_DEPOT> [NOM_DU_DOSSIER]"
  exit 1
fi

REPO_URL="$1"
# 2e parametre optionnel : nom du dossier. Par defaut, deduit de l'URL.
PROJECT_DIR="${2:-$(basename "$REPO_URL" .git)}"

log INFO "=== Deploiement automatique ==="
log INFO "Depot      : $REPO_URL"
log INFO "Dossier    : $PROJECT_DIR"

# ----------------------------------------------------------------------------
# Verification des dependances
# ----------------------------------------------------------------------------
log INFO "Verification des dependances (git, node, npm)..."
require_cmd git
require_cmd node
require_cmd npm
log INFO "Dependances OK (git $(git --version | awk '{print $3}'), node $(node -v))."

# ----------------------------------------------------------------------------
# Clonage / mise a jour du depot
# ----------------------------------------------------------------------------
if [ -d "$PROJECT_DIR" ]; then
  log INFO "Le repertoire $PROJECT_DIR existe deja. Mise a jour (git pull)..."
  cd "$PROJECT_DIR"
  git pull
else
  log INFO "Clonage du repository..."
  git clone "$REPO_URL" "$PROJECT_DIR"
  cd "$PROJECT_DIR"
fi

# Si l'app vit dans un sous-dossier (ex: ./app), on s'y place.
if [ -f "app/package.json" ] && [ ! -f "package.json" ]; then
  log INFO "package.json trouve dans ./app, deplacement dans ce dossier."
  cd app
fi

# ----------------------------------------------------------------------------
# Installation et tests
# ----------------------------------------------------------------------------
log INFO "Installation des dependances (npm install)..."
npm install

log INFO "Lancement des tests (npm test)..."
# On desactive temporairement 'set -e' pour capturer le code de retour
set +e
npm test
TEST_EXIT_CODE=$?
set -e

if [ "$TEST_EXIT_CODE" -ne 0 ]; then
  log ERROR "Echec des tests (code $TEST_EXIT_CODE). Deploiement interrompu."
  exit 1
fi
log INFO "Tests passes avec succes."

# ----------------------------------------------------------------------------
# Question 3 : demarrage en arriere-plan + sauvegarde du PID
# ----------------------------------------------------------------------------
# Si une ancienne instance tourne, on l'arrete proprement.
if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE")"
  if kill -0 "$OLD_PID" >/dev/null 2>&1; then
    log WARN "Une instance tourne deja (PID $OLD_PID). Arret en cours..."
    kill "$OLD_PID" || true
    sleep 2
  fi
  rm -f "$PID_FILE"
fi

log INFO "Demarrage de l'application en arriere-plan..."
# nohup : l'app survit a la fermeture du terminal ; sortie redirigee vers app.log
nohup npm start > app.log 2>&1 &
APP_PID=$!
echo "$APP_PID" > "$PID_FILE"

# Petite verification : le process est-il toujours vivant ?
sleep 2
if kill -0 "$APP_PID" >/dev/null 2>&1; then
  log INFO "Application demarree (PID $APP_PID). Logs : app.log"
  log INFO "Pour l'arreter : kill \$(cat $PID_FILE)"
else
  log ERROR "L'application n'a pas demarre. Consultez app.log."
  exit 1
fi
