#!/usr/bin/env bash

#----------Sources---------#
# KIND
source ./script_config/get_kind_config.sh

# MongoDB-Community-Operator 
source ./script_config/install_mondodb_op.sh

# Cilium & Network
source ./script_config/cilium_setup.sh
source ./script_config/cluster_network.sh

# CRDS
source ./script_config/install_crds.sh

# Help Script
source ./script_config/help.sh

#----------Sources End---------#

#----------Default Variables---------#
KIND_FILE="./yaml_config/chat-app-staging-kind.yaml"
MONGODB_NS=db
CILIUMVERSION=1.19.3
KUBEPROXYREPLACEMENT=false
NETWORKFILEPATH=./yaml_config/cilium_network.yaml
HELM_CONFIG_FILE="yaml_config/helm_charts.yaml"

#--------Options--------#
SHOW_HELP=false
INFO_ONLY=false
CREATE_KIND=false
INSTALL_MONGODB=false
INSTALL_NETWORK_POLICY_ONLY=false
INSTALL_ALL=false
INSTALL_HELM_CHART_ONLY=false
INSTALL_CILIUM_ONLY=false
DRY_RUN=false

#----------Default Variables End---------#

#=================== FUNCTIONS ====================#

#======== KIND INFO =======#
GETINFO() {

    echo "========== CLUSTER NAME =========="
    GetClusterName "$KIND_FILE"

    echo "========== NETWORK =========="
    GetNetworking "$KIND_FILE"

    echo
    echo "========== PORTS =========="
    GetPortBinding "$KIND_FILE"

    echo
    echo "========== NODES =========="

    NODENUMBER=$(GetNodeNumbers "$KIND_FILE")
    echo "Worker Nodes: $NODENUMBER"

    echo
    echo "========== LABELS & TAINTS =========="
    GetLabelsTaints "$KIND_FILE"

    echo
}

RunAll() {

    echo "Creating Kind Cluster..."
    kind create cluster --config "$KIND_FILE"

    echo
    echo "Installing Cilium..."
    CiliumInstall "$CILIUMVERSION" "$KUBEPROXYREPLACEMENT"

    echo
    echo "Waiting for CoreDNS..."
    WaitForCoreDNS

    echo
    echo "Applying Network Policies..."
    SetCiliumNetwork "$NETWORKFILEPATH"

    echo
    echo "Installing MongoDB Operator..."
    InstallMongodb "$MONGODB_NS"

    echo
    echo "Installing Helm Charts..."
    ADDHELMREPO "$HELM_CONFIG_FILE"
    INSTALLHELMCHARTS "$HELM_CONFIG_FILE"

    echo
    echo "Setup Complete."
}

ConfirmProceed() {

    read -rp "Proceed? (y/n): " ANSWER

    case "$ANSWER" in
        y|Y)
            return 0
            ;;
        *)
            echo "Aborted."
            return 1
            ;;
    esac
}

#=================== FUNCTIONS END ====================#

#=================== OPTION PARSING ===================#

PARSED=$(getopt \
    -o hicmlnadp \
    -l kind-file:,mongodb-ns:,cilium-version:,kube-proxy-replacement:,network-file:,helm-config: \
    -- "$@")

echo "RAW ARGS: $@"
echo "PARSED=[$PARSED]"

if [[ $? -ne 0 ]]; then
    echo "Failed to parse arguments"
    exit 1
fi

eval set -- "$PARSED"

while true; do
    case "$1" in

        -h)
            SHOW_HELP=true
            shift
            ;;

        -i)
            INFO_ONLY=true
            shift
            ;;

        -c)
            CREATE_KIND=true
            shift
            ;;

        -m)
            INSTALL_MONGODB=true
            shift
            ;;

        -l)
            INSTALL_HELM_CHART_ONLY=true
            shift
            ;;

        -n)
            INSTALL_CILIUM_ONLY=true
            shift
            ;;
        -p)
            INSTALL_NETWORK_POLICY_ONLY=true
            shift
            ;;

        -a)
            INSTALL_ALL=true
            shift
            ;;

        -d)
            DRY_RUN=true
            shift
            ;;

        --kind-file)
            KIND_FILE="$2"
            shift 2
            ;;
        --kube-proxy-replacement)
            KUBEPROXYREPLACEMENT="$2"
            shift 2
            ;;

        --network-file)
            NETWORKFILEPATH="$2"
            shift 2
            ;;

        --mongodb-ns)
            MONGODB_NS="$2"
            shift 2
            ;;

        --cilium-version)
            CILIUMVERSION="$2"
            shift 2
            ;;

        --helm-config)
            HELM_CONFIG_FILE="$2"
            shift 2
            ;;

        --)
            shift
            break
            ;;

        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

#=================== OPTION PARSING END ===================#

#------------DeBug Option------------#
echo "SHOW_HELP=$SHOW_HELP"
echo "INFO_ONLY=$INFO_ONLY"
echo "CREATE_KIND=$CREATE_KIND"
echo "INSTALL_MONGODB=$INSTALL_MONGODB"
echo "INSTALL_ALL=$INSTALL_ALL"
echo "INSTALL_HELM_CHART_ONLY=$INSTALL_HELM_CHART_ONLY"
echo "INSTALL_CILIUM_ONLY=$INSTALL_CILIUM_ONLY"
echo "INSTALL_NETWORK_POLICY_ONLY=$INSTALL_NETWORK_POLICY_ONLY"
#------------DeBug Option End------------#

#=================== MAIN ===================#
main() {

    if $SHOW_HELP; then
        ShowHelp
        exit 0
    fi

    if $DRY_RUN; then
        GETINFO
        ShowPlan
        exit 0
    fi

    if $INFO_ONLY; then
        GETINFO
        exit 0
    fi

    if $INSTALL_ALL; then
        GETINFO
        echo ""
        ShowPlan
        ConfirmProceed || exit 0
        RunAll
        exit 0
    fi

    if $CREATE_KIND; then
        GETINFO
        ConfirmProceed || exit 0
        kind create cluster --config "$KIND_FILE"
    fi

    if $INSTALL_MONGODB; then
        ShowPlan
        ConfirmProceed || exit 0
        InstallMongodb "$MONGODB_NS"
    fi

    if $INSTALL_CILIUM_ONLY; then
        ShowPlan
        ConfirmProceed || exit 0
        CiliumInstall "$CILIUMVERSION" "$KUBEPROXYREPLACEMENT"
        WaitForCoreDNS
        SetCiliumNetwork "$NETWORKFILEPATH"
    fi

    if $INSTALL_HELM_CHART_ONLY; then
        ShowPlan
        ConfirmProceed || exit 0
        ADDHELMREPO "$HELM_CONFIG_FILE"
        INSTALLHELMCHARTS "$HELM_CONFIG_FILE"
    fi

    if $INSTALL_NETWORK_POLICY_ONLY; then
        ShowPlan
        ConfirmProceed || exit 0
        SetCiliumNetwork "$NETWORKFILEPATH"
    fi

    #-------- No flags provided --------#
    if ! $CREATE_KIND &&
       ! $INSTALL_MONGODB &&
       ! $INSTALL_ALL &&
       ! $INSTALL_HELM_CHART_ONLY &&
       ! $INSTALL_CILIUM_ONLY &&
       ! $INSTALL_NETWORK_POLICY_ONLY &&
       ! $DRY_RUN; then

        GETINFO
        ShowPlan
        ConfirmProceed || exit 0
        RunAll
        exit 0
    fi
}
#=================== MAIN END ===================#

#=================== CALL main() ===================#
main "$@"
