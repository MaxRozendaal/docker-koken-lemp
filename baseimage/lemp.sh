#!/bin/bash
set -e
source /bd_build/buildconfig
set -x

#install key requirements
$minimal_apt_get_install dirmngr gnupg gpg-agent

# add maria db keys
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

# add LEMP repositories
add-apt-repository 'deb [arch=amd64] http://ams2.mirrors.digitalocean.com/mariadb/repo/10.2/ubuntu bionic main'
add-apt-repository ppa:ondrej/php
add-apt-repository -y ppa:ondrej/nginx-mainline
add-apt-repository -y ppa:rwky/graphicsmagick
apt-get update

$minimal_apt_get_install nginx mariadb-server mariadb-client php7.1-fpm php7.1-mysqli php7.1-curl php7.1-intl php7.1-mbstring php7.1-mcrypt graphicsmagick
