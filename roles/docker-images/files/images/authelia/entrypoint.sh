#!/bin/sh
set -eu # fail on error

CONFIG="/config/configuration.yml"

# TODO wait until database is alive
# Authelia image comes with netcat (nc) installed and apt is not available

# TODO: check if Authelia has been configured before
echo "Initialize Authelia database schema"
authelia storage migrate up -c "$CONFIG"
# TODO: mark Authelia as configured

# TODO: Execute the original entrypoint