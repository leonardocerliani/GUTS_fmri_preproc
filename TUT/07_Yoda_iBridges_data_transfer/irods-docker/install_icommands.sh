#!/bin/bash
set -e

apt update
apt install -y wget gnupg lsb-release apt-transport-https openssl libssl-dev ca-certificates

mkdir -p /etc/apt/keyrings

wget -qO - https://packages.irods.org/irods-signing-key.asc | \
    gpg \
        --no-options \
        --no-default-keyring \
        --no-auto-check-trustdb \
        --homedir /dev/null \
        --no-keyring \
        --import-options import-export \
        --output /etc/apt/keyrings/renci-irods-archive-keyring.pgp \
        --import

echo "deb [signed-by=/etc/apt/keyrings/renci-irods-archive-keyring.pgp arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list

apt-get update

apt-get install -y irods-icommands=4.3.3-0~jammy irods-runtime=4.3.3-0~jammy
