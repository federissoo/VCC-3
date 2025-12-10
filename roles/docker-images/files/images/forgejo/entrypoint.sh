#!/bin/sh
set -eu # fail on error

# Make forgejo trust our TLS certificate
update-ca-certificates

# This helper allows to run stuff as the forgejo user
# TODO: looks like it's missing the `sudo` executable
forgejo_cli() { sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; }

# TODO wait until database is alive
#  - port alive                         (bad)
#  - a mock query like 'SELECT 1' works (better)

# TODO: check if it's the first run (see if /data/gitea/conf/app.ini exists)
echo "First run detected"
mkdir -p /data/gitea
mkdir -p /data/queues
mkdir -p /data/gitea/conf
cp /conf/app.ini /data/gitea/conf/app.ini
# Fix permission for data directory
chown -R git:git /data/gitea
chown -R git:git /data/queues

# DB migration
echo "Initialize forgejo database"
forgejo_cli migrate

# TODO create admin user (if it does not exists already)
# use `forgejo_cli admin user list` and `forgejo_cli admin user create`

# TODO wait until authentication server is alive
#  - port alive                         (bad)
#  - check that the web server responds (better)
#    Authelia exposes /api/health to check status
#    For example: curl -kfsS https://auth.vcc.local/api/health returns {"status":"OK"}

# TODO setup authentication (if it does not exist)
# use `forgejo_cli admin auth list` and `forgejo_cli admin auth add-oauth`
#   --auto-discover-url is `https://auth.{{domain_name}}/.well-known/openid-configuration`
#   --provider is openidConnect

# TODO: Execute the original entrypoint