#!/usr/bin/env bash
set -euo pipefail

### -----------------------------
### Configuration
### -----------------------------

DOMAIN=${1:?Usage: $0 <domain>}
RENEW_BEFORE_DAYS=30

BASE_DIR="/etc/hysteria/tls"
CA_KEY="$BASE_DIR/ca.key"
CA_CERT="$BASE_DIR/ca.crt"

SERVER_KEY="$BASE_DIR/server.key"
SERVER_CERT="$BASE_DIR/server.crt"
SERVER_CSR="$BASE_DIR/server.csr"
SERVER_EXT="$BASE_DIR/server.ext"

DAYS_CA=3650
DAYS_SERVER=825

### -----------------------------
### Setup
### -----------------------------

umask 077
mkdir -p "$BASE_DIR"

### -----------------------------
### Resolve IP (optional)
### -----------------------------

IP="$(dig +short "$DOMAIN" | grep -E '^[0-9]+\.' | head -n1 || true)"

if [[ -n "$IP" ]]; then
  SAN="DNS:$DOMAIN,IP:$IP"
else
  SAN="DNS:$DOMAIN"
fi

### -----------------------------
### Create CA if missing
### -----------------------------

if [[ ! -f "$CA_KEY" || ! -f "$CA_CERT" ]]; then
  echo ">> Creating Hysteria CA"

  openssl genrsa -out "$CA_KEY" 4096
  openssl req -x509 -new -nodes \
    -key "$CA_KEY" \
    -sha256 \
    -days "$DAYS_CA" \
    -subj "/CN=Hysteria Root CA" \
    -out "$CA_CERT"
fi

### -----------------------------
### Check if renewal is needed
### -----------------------------

RENEW=true

if [[ -f "$SERVER_CERT" ]]; then
  EXPIRY_DATE="$(openssl x509 -enddate -noout -in "$SERVER_CERT" | cut -d= -f2)"
  EXPIRY_SECS="$(date -d "$EXPIRY_DATE" +%s)"
  NOW_SECS="$(date +%s)"

  DAYS_LEFT=$(( (EXPIRY_SECS - NOW_SECS) / 86400 ))

  if (( DAYS_LEFT > RENEW_BEFORE_DAYS )); then
    echo ">> Server cert valid for $DAYS_LEFT more days; no renewal needed"
    RENEW=false
  fi
fi

# Create a combined certificate (server + CA) for sing‑box
cat "$SERVER_CERT" "$CA_CERT" > "$BASE_DIR/fullchain.crt"

### -----------------------------
### Renew server cert
### -----------------------------
function fn_is_container_running() {
    local CID=$(docker ps -q -f status=running -f name=^/$1$)
    if [ "$CID" ]; then
        echo true
    else
        echo false
    fi
}

function fn_restart_docker_container() {
    local IS_CONTAINER_RUNNING=$(fn_is_container_running $1)
    if [ "$IS_CONTAINER_RUNNING" = true ]; then
        echo -e "${B_GREEN}>> Restarting Docker container '$1' for changes to take effect${RESET}"
        docker compose -f $HOME/Rainb0w_Lite_Home/$1/docker-compose.yml down --remove-orphans
        sleep 1
        docker compose -f $HOME/Rainb0w_Lite_Home/$1/docker-compose.yml up -d
    else
        echo -e "${B_GREEN}>> Starting Docker container: ${B_RED}$1${RESET}"
        docker compose -f $HOME/Rainb0w_Lite_Home/$1/docker-compose.yml up -d
    fi
}

if [[ "$RENEW" == true ]]; then
  echo ">> Renewing server certificate"

  openssl genrsa -out "$SERVER_KEY" 2048

  openssl req -new \
    -key "$SERVER_KEY" \
    -subj "/CN=$DOMAIN" \
    -out "$SERVER_CSR"

  cat > "$SERVER_EXT" <<EOF
subjectAltName = $SAN
EOF

  openssl x509 -req \
    -in "$SERVER_CSR" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$SERVER_CERT" \
    -days "$DAYS_SERVER" \
    -sha256 \
    -extfile "$SERVER_EXT"

  rm -f "$SERVER_CSR" "$SERVER_EXT"

  echo ">> Certificate renewed successfully"

  # Reload Hysteria if present
  fn_restart_docker_container sing-box
fi
