#!/usr/bin/env bash

# Goddamn bash.
set -Eeuo pipefail

# Build a release and push it to a server with ssh access.
# The server is specified using `PROD_SERVER_USER`, `PROD_SERVER_HOST` and `PROD_SERVER_RELEASE_DIR`.

# Build the release.
mix deps.get --only prod
MIX_ENV=prod mix do compile, assets.deploy, phx.gen.release
MIX_ENV=prod mix release --overwrite

scp -q -r _build/prod "$PROD_SERVER_USER"@"$PROD_SERVER_HOST":"$PROD_SERVER_RELEASE_DIR"
