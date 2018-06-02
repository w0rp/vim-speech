#!/usr/bin/env bash

set -e

CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
export CLOUD_SDK_REPO

# Install what we need via apt, if we need to.
if ! [ -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
    echo 'Adding a now apt source...'
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" \
        | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    echo "Adding Google's gpg key via apt-key..."
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | sudo apt-key add -
    echo 'Running apt to install things...'
    sudo apt update
    sudo apt install google-cloud-sdk google-cloud-sdk-app-engine-python
fi

if ! [ -d venv ]; then
    virtualenv -p python2.7 venv
fi

set +u
source venv/bin/activate
set -u

pip install -q pip==10.0.1 wheel==0.31.1
pip install -q google-cloud==0.33.1

echo 'Everything has probably been installed.'
