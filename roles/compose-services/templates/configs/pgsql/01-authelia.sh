#!/bin/bash
set -euo piepfail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER {{ authelia_db_user }} WITH PASSWORD '{{ authelia_db_password }}';
    CREATE DATABASE {{ authelia_db }};
    GRANT ALL PRIVILEGES ON DATABASE {{ authelia_db }} TO {{ authelia_db_user }};
    ALTER DATABASE {{ authelia_db }} OWNER TO {{ authelia_db_user }};
EOSQL