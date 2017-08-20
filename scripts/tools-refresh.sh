#!/usr/bin/env bash
# -*- shell-script -*-
docker pull sdwandemo/tiny-helper

DKR="docker run --rm -t -w /opt/tmp -v /mnt/images:/mnt/images -v /opt/tmp:/opt/tmp sdwandemo/tiny-helper"
compose_url="https://github.com/sdwandemo/topology.git"

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

_find_latest_binary() {
    local repo=$1
    local arch=$2

    echo $(curl -fsSL https://api.github.com/repos/$repo/releases/latest | jq -r ".assets[] | .browser_download_url | select(test(\"${arch}\"))")
}

_install_binary() {
    local src=$1
    local dst=$2

    curl -fsSL $src > $dst
    chmod +x $dst
    logger -t tools-refresh -s refreshed $dst
}

_refresh_docker_machine_kvm() {
    local arch="16.04"
    local repo="dhiltgen/docker-machine-kvm"
    local src=$(_find_latest_binary $repo $arch)
    local dst="/usr/local/bin/docker-machine-driver-kvm"

    _install_binary $src $dst
}

_refresh_minikube() {
    local arch="linux-amd64$"
    local repo="kubernetes/minikube"
    local src=$(_find_latest_binary $repo $arch)
    local dst="/usr/local/bin/minikube"

    _install_binary $src $dst
}

_refresh_docker_compose() {
    local arch="$(uname -s)-$(uname -m)"
    local repo="docker/compose"
    local src=$(_find_latest_binary $repo $arch)
    local dst="/usr/local/bin/docker-compose"

    _install_binary $src $dst
}

_refresh_helm() {
    local uri="https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"
    curl -fsSL $uri | bash
    logger -t tools-refresh -s refreshed /usr/local/bin/helm
}

_refresh_all_tools() {
    _refresh_docker_compose
    _refresh_docker_machine_kvm
    _refresh_minikube
    _refresh_helm
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
_refresh_all_tools
#_docker_compose_run

logger -t tools-refresh -s 'script finished'
