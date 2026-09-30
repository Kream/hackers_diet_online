#!/bin/bash
set -euo pipefail

DATA_ROOT="/server/pub/hackdiet"
SEED_DIR="/opt/hackers_diet_online/docker/pubname"

# Recreate every data subdirectory the application writes to. This matters for
# bind mounts, which (unlike named/anonymous volumes) do NOT inherit the dirs
# seeded into the image, so they must be (re)created on every start.
mkdir -p \
    "$DATA_ROOT/Users" \
    "$DATA_ROOT/Sessions" \
    "$DATA_ROOT/RememberMe" \
    "$DATA_ROOT/ClusterSync" \
    "$DATA_ROOT/Pubname" \
    "$DATA_ROOT/Invitations" \
    "$DATA_ROOT/Backups"
# word lists for HDiet::pubname. Always refresh from the image so a new 
# volume and a rebuilt image remain in sync with the git repo
cp "$SEED_DIR/firstnames.txt" "$SEED_DIR/lastnames.txt" "$DATA_ROOT/Pubname/"

chown -R www-data:www-data "$DATA_ROOT"
exec "$@"
