#!/usr/bin/env bash

# Setup Cluster Networking with Cilium

SetCiliumNetwork() {
    local NETWORKFILEPATH=$1
    echo "Applying Cilium policy..."
    kubectl apply -f $NETWORKFILEPATH
}
