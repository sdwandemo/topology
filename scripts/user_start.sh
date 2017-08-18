#!/usr/bin/env bash
logger -t user_start_script -s STARTED
_mk_part() {
    fdisk /dev/sdb <<EEOF
g
n



w
EEOF

    partprobe /dev/sdb
    mkfs.xfs -f -s size=4096 /dev/sdb1
    logger -t user_start_script -s mkfs
}

_install_essentials() {
    apt-get -y install zsh screen git nfs-common xfsprogs parted
    curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

_install_essentials
[[ ! -b /dev/sdb1 ]] && _mk_part
[[ ! -d /mnt/images ]] && mkdir -p /mnt/images
[[ ! -d /opt/tmp ]] && mkdir -p /opt/tmp
[[ -b /dev/sdb1 ]] && mount /dev/sdb1 /mnt
chown --recursive rancher:rancher /mnt/images
logger -t user_start_script -s FINISHED
