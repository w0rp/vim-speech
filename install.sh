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

if ! dpkg -s libportaudio2 > /dev/null; then
    echo 'Installing libportaudio2...'
    sudo apt install libportaudio2
fi

if ! [ -f /usr/include/portaudio.h ]; then
    echo 'Installing portaudio19-dev...'
    sudo apt install portaudio19-dev
fi

if ! [ -d plugin/venv ]; then
    virtualenv -p python2.7 plugin/venv
fi

set +u
source plugin/venv/bin/activate
set -u

pip install -q pip==10.0.1 wheel==0.31.1
pip install -q -r requirements.txt

echo 'Everything has probably been installed.'
