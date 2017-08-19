#!/usr/bin/env bash
# -*- shell-script -*-
docker pull sdwandemo/tiny-helper

DKR="docker run --rm -t -w /opt/tmp -v /mnt/images:/mnt/images -v /opt/tmp:/opt/tmp sdwandemo/tiny-helper"
compose_url="https://github.com/sdwandemo/topology2.git"

_pull_images() {
    images=$(docker images | awk 'NR > 1 {print $1":"$2}')
    [[ -n "$images" ]] && for i in $images; do docker pull $i; done
}

_copy_prep() {
    logger -t tools-refresh -s COPY IMAGES PREP
    local cmd="ruby -ropen-uri -e"
    $DKR $cmd "eval(open('https://raw.githubusercontent.com/sdwandemo/topology/master/scripts/copy_prep.rb').read)"
    logger -t tools-refresh -s COPY IMAGES PREP FINISHED
}

_docker_compose_refresh() {
    local version="$(uname -s)-$(uname -m)"
    local binary=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | jq -r ".assets[] | .browser_download_url | select(contains(\"${version}\"))")
    curl -fsSL "${binary}" > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    logger -t tools-refresh -s 'refreshed docker-compose'
}

_docker_compose_run() {
    echo 1024 > /proc/sys/fs/inotify/max_user_instances
    echo 65536 > /proc/sys/fs/inotify/max_user_watches
    runuser -l ubuntu -c "git clone ${compose_url} app"
    runuser -l ubuntu -c "cd app && docker-compose up -d --force-recreate"
}

_pull_images
_copy_prep
/opt/tmp/init_images
_docker_compose_refresh
_docker_compose_run

logger -t tools-refresh -s 'script finished'
