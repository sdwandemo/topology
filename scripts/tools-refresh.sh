#!/usr/bin/env bash

# _latest_release() {

# }

_docker_compose() {
    local version="$(uname -s)-$(uname -m)"
    local binary=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[] | .browser_download_url | select(contains(\"${version}\"))")
    curl -fsSL "${binary}" > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    logger -t tools-refresh -s 'refreshed docker-compose'
}

_docker_compose

logger -t tools-refresh -s 'script finished'
