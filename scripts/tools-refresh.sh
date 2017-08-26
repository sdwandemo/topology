#!/usr/bin/env bash
# -*- shell-script -*-
docker pull sdwandemo/tiny-helper

DKR="docker run --rm -t -w /opt/tmp -v /mnt/images:/mnt/images -v /opt/tmp:/opt/tmp sdwandemo/tiny-helper"
compose_url="https://github.com/sdwandemo/topology.git"

_mk_networks() {
    local driver_opts="--opt com.docker.network.bridge.name=management"
    local driver="--driver bridge"
    local name="management"
    local subnet="--subnet 10.10.10.0/24"
    local gw="--gateway 10.10.10.1"

    [[ ! $(docker network ls | grep -si $name) ]] && docker network create $driver $driver_opts $subnet $gw $name
}

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

_refresh_kubectl() {
    local binary=/usr/local/bin/kubectl
    local stable=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    local uri=https://storage.googleapis.com/kubernetes-release/release/$stable/bin/linux/amd64/kubectl
    curl -Lo $binary $uri
    chmod +x $binary
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

_refresh_shell_env() {
    local cmd="runuser -l ubuntu -c"
    $cmd '[[ ! -d $HOME/.liquidprompt ]] && git clone https://github.com/nojhan/liquidprompt.git $HOME/.liquidprompt || cd $HOME/.liquidprompt && git pull'
    $cmd '[[ ! -d $HOME/.oh-my-zsh ]] && git clone git://github.com/robbyrussell/oh-my-zsh.git $HOME/.oh-my-zsh || cd $HOME/.oh-my-zsh && git pull'
    $cmd '[[ ! $(grep -i liquid $HOME/.zshrc) ]] && echo "[[ $- = *i* ]] && source ~/.liquidprompt/liquidprompt" >> $HOME/.zshrc'
}

_refresh_all_tools() {
    _refresh_docker_compose
    _refresh_docker_machine_kvm
    _refresh_kubectl
    _refresh_minikube
    _refresh_helm
    _refresh_shell_env
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
