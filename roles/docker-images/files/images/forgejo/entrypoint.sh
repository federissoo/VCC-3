#!/bin/sh
set -eu # Interrompe lo script se c'è un errore o una variabile mancante

# Aggiorna i certificati per fidarsi della nostra CA (wildcard.crt)
update-ca-certificates

# Funzione helper per eseguire comandi come utente 'git' invece di root
# È necessario perché i comandi amministrativi di Forgejo devono girare con l'utente dell'app
forgejo_cli() { sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; }

# --- 1. ATTESA DEL DATABASE ---
# Il container non deve partire finché Postgres non è pronto a ricevere connessioni
echo "Waiting for PostgreSQL to be ready..."
until PGPASSWORD="$POSTGRES_PASSWORD" psql -h "db" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1" > /dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 2
done
echo "Database is up!"

# --- 2. CONTROLLO PRIMO AVVIO ---
# Verifica se il file di configurazione esiste già. Se non c'è, è la prima installazione.
if [ ! -f "/data/gitea/conf/app.ini" ]; then
    echo "First run detected - Configuring Forgejo..."

    # Crea le cartelle necessarie
    mkdir -p /data/gitea/conf
    mkdir -p /data/queues

    # Copia il file di configurazione preparato da Ansible
    cp /conf/app.ini /data/gitea/conf/app.ini
    
    # Sistema i permessi: l'utente 'git' deve essere il proprietario dei file
    chown -R git:git /data/gitea
    chown -R git:git /data/queues

    # --- 3. INIZIALIZZAZIONE DATABASE ---
    echo "Initializing database schema..."
    forgejo_cli migrate

    # --- 4. CREAZIONE UTENTE ADMIN ---
    echo "Creating admin user..."
    # Usa le variabili d'ambiente passate dal docker-compose
    forgejo_cli admin user create --admin \
        --username "$FORGEJO_ADMIN_USERNAME" \
        --password "$FORGEJO_ADMIN_PASSWORD" \
        --email "$FORGEJO_ADMIN_EMAIL" || echo "Admin creation skipped or failed"

    # --- 5. ATTESA AUTHELIA ---
    # Prima di configurare il login OIDC, Authelia deve essere online
    echo "Waiting for Authelia..."
    # Usa curl ignorando i certificati self-signed (-k) per controllare lo stato
    until curl -kfsS "https://auth.{{ domain_name }}/api/health" > /dev/null 2>&1; do
        echo "Authelia is unavailable - sleeping"
        sleep 5
    done
    echo "Authelia is up!"

    # --- 6. SETUP AUTENTICAZIONE OIDC ---
    echo "Configuring OIDC authentication..."
    forgejo_cli admin auth add-oauth \  # Ordina a Forgejo di aggiungere una nuova "Sorgente di Autenticazione" di tipo OAuth2 (la tecnologia alla base di OIDC).
        --name "Authelia" \
        # --provider "openidConnect" \
        --key "$FORGEJO_OIDC_CLIENT_ID" \
        --secret "$FORGEJO_OIDC_CLIENT_SECRET" \  # È la password segreta condivisa. Serve a garantire che sia davvero il server Forgejo a chiedere i dati
        --auto-discover-url "https://auth.{{ domain_name }}/.well-known/openid-configuration" \
        --group-claim-name "groups" \
        --admin-group "admins" || echo "Auth provider setup skipped or failed"

    echo "Configuration completed!"
else
    echo "App.ini found, skipping initial setup."
fi

# --- 7. AVVIO DELL'APPLICAZIONE ---
echo "Starting Forgejo..."
# Esegue il comando originale dell'immagine sostituendo il processo corrente
exec /usr/bin/entrypoint "/bin/s6-svscan" "/etc/s6"