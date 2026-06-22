#!/usr/bin/env bash

ShowHelp() {

cat <<EOF

    Usage:
    ./setup.sh [OPTIONS]

    OPTIONS

    -h
        Show help

    -i
        Show cluster information

    -d
        Dry run (show plan only)

    -c
        Create Kind cluster

    -n
        Install Cilium

    -p
        Apply Cilium network policy only

    -m
        Install MongoDB Operator

    -l
        Install Helm charts

    -a
        Install everything

    VARIABLE OVERRIDES

    --kind-file FILE
        Kind cluster configuration file

    --mongodb-ns NAMESPACE
        MongoDB namespace

    --cilium-version VERSION
        Cilium version

    --kube-proxy-replacement true|false
        kubeProxyReplacement setting

    --network-file FILE
        Network policy YAML

    --helm-config FILE
        Helm chart configuration YAML

    EXAMPLES

    Show cluster info

        ./setup.sh -i

    Create Kind cluster

        ./setup.sh -c

    Install MongoDB

        ./setup.sh -m

    Install MongoDB in custom namespace

        ./setup.sh -m --mongodb-ns database

    Install Cilium

        ./setup.sh -n

    Install Cilium custom version

        ./setup.sh -n --cilium-version 1.19.4

    Apply network policy only

        ./setup.sh -p \
            --network-file ./yaml_config/custom-network.yaml

    Install Helm charts

        ./setup.sh -l \
            --helm-config ./yaml_config/custom-helm.yaml

    Full installation

        ./setup.sh -a

    Dry run

        ./setup.sh -d -a

EOF
}

ShowPlan() {

    echo "========== EXECUTION PLAN =========="
    echo

    if $INSTALL_ALL; then

        echo "Action: Full Installation"
        echo
        echo "Kind File               : $KIND_FILE"
        echo "MongoDB Namespace       : $MONGODB_NS"
        echo "Cilium Version          : $CILIUMVERSION"
        echo "Kube Proxy Replacement  : $KUBEPROXYREPLACEMENT"
        echo "Network Policy File     : $NETWORKFILEPATH"
        echo "Helm Config File        : $HELM_CONFIG_FILE"
        echo

        return
    fi

    if $CREATE_KIND; then
        echo "Action: Create Kind Cluster"
        echo "Kind File: $KIND_FILE"
        echo
    fi

    if $INSTALL_CILIUM_ONLY; then
        echo "Action: Install Cilium"
        echo "Version: $CILIUMVERSION"
        echo "Kube Proxy Replacement: $KUBEPROXYREPLACEMENT"
        echo "Network File: $NETWORKFILEPATH"
        echo
    fi

    if $INSTALL_NETWORK_POLICY_ONLY; then
        echo "Action: Apply Network Policy"
        echo "Network File: $NETWORKFILEPATH"
        echo
    fi

    if $INSTALL_MONGODB; then
        echo "Action: Install MongoDB Operator"
        echo "Namespace: $MONGODB_NS"
        echo
    fi

    if $INSTALL_HELM_CHART_ONLY; then
        echo "Action: Install Helm Charts"
        echo "Helm Config File: $HELM_CONFIG_FILE"
        echo
    fi

    if ! $CREATE_KIND &&
       ! $INSTALL_MONGODB &&
       ! $INSTALL_HELM_CHART_ONLY &&
       ! $INSTALL_CILIUM_ONLY &&
       ! $INSTALL_NETWORK_POLICY_ONLY; then

        GETINFO
        echo "Action: Create Kind Cluster"
        echo "Kind File: $KIND_FILE"
        echo
        echo "Action: Install Cilium"
        echo "Version: $CILIUMVERSION"
        echo "Kube Proxy Replacement: $KUBEPROXYREPLACEMENT"
        echo "Network File: $NETWORKFILEPATH"
        echo
        echo "Action: Apply Network Policy"
        echo "Network File: $NETWORKFILEPATH"
        echo
        echo "Action: Install MongoDB Operator"
        echo "Namespace: $MONGODB_NS"
        echo
        echo "Action: Install Helm Charts"
        echo "Helm Config File: $HELM_CONFIG_FILE"
        echo
        
    fi
}