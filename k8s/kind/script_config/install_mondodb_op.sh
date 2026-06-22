#!/usr/bin/env bash

# Provide NameSpace during calling the function
InstallMongodb() {

    local MONGODB_NS="$1"

    helm repo add mongodb https://mongodb.github.io/helm-charts
    helm repo update

    echo "Installing mongodb-operator"

    helm upgrade --install mongodb-operator mongodb/community-operator \
        --namespace "$MONGODB_NS" \
        --create-namespace \
        --set operator.watchNamespace="$MONGODB_NS"

    sleep 10

    echo "Patching mongodb operator"

    kubectl patch deployment mongodb-kubernetes-operator \
        -n "$MONGODB_NS" \
        --type='merge' \
        -p '{
          "spec": {
            "template": {
              "spec": {
                "nodeSelector": {
                  "node-role.kubernetes.io/control-plane": ""
                },
                "tolerations": [
                  {
                    "key": "node-role.kubernetes.io/control-plane",
                    "operator": "Exists",
                    "effect": "NoSchedule"
                  }
                ]
              }
            }
          }
        }'
}
