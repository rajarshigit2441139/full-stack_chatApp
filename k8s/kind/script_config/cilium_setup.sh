#!/usr/bin/env bash

# Install Cilium
CiliumInstall() {
    local CILIUMVERSION=$1
    local KUBEPROXYREPLACEMENT=$2
    cilium install \
        --version "$CILIUMVERSION" \
        --set ipam.mode=kubernetes \
        --set kubeProxyReplacement="$KUBEPROXYREPLACEMENT"
}

# Wait for core DNS

WaitForCoreDNS() {
    echo "Waiting for Cilium pods..."
    kubectl wait --for=condition=Ready pod \
        -n kube-system \
        -l k8s-app=cilium \
        --timeout=10m
    
    echo "Waiting for CoreDNS..."
    kubectl wait --for=condition=Ready pod \
        -n kube-system \
        -l k8s-app=kube-dns \
        --timeout=10m

    echo "Waiting for node readiness..."
    kubectl wait --for=condition=Ready nodes --all --timeout=10m

}