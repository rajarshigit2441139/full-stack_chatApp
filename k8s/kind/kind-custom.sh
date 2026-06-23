#!/usr/bin/env bash
set -e

kind create cluster  --config kind-config.yml

echo "Installing Cilium..."
cilium install --version 1.19.3 --set kubeProxyReplacement=true

echo "Waiting for Cilium pods to be ready..."
kubectl wait \
  --for=condition=Ready pods \
  -n kube-system \
  -l k8s-app=cilium \
  --timeout=10m

echo "Waiting for Cilium operator..."
kubectl wait \
  --for=condition=Available deployment/cilium-operator \
  -n kube-system \
  --timeout=5m

echo "Applying Cilium policy..."
kubectl apply -f allow-kubelet.yml

echo "Cluster is ready!"