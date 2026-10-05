#!/usr/bin/env bash

set -euo pipefail

# ----------Default location---------- #
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTS_FILE="${SCRIPT_DIR}/charts.yaml"


# ------------ Functions ---------- #

# ---------- Script argument ---------- #
ARG="${1:-all}"

# ---------- logging ---------- #
log() {
    echo
    echo "==> $*"
}

# ---------- error ---------- #
error() {
    echo
    echo "ERROR: $*" >&2
    exit 1
}

# ---------- Read charts.yaml ---------- #

ChartValue() {
    local component="$1"
    local path="$2"

    yq -r ".\"${component}\".${path}" "$CHARTS_FILE"
}

# ---------- Validate kubectl and helm ---------- #
CheckPrerequisites() {
    log "Check Prerequisites"

    command -v kubectl > /dev/null 2>&1 || error "kubectl is not present"
    command -v helm > /dev/null 2>&1    || error "helm is not present"
    command -v yq >/dev/null 2>&1      || error "yq is not present"
    [[ -f "$CHARTS_FILE" ]]            || error "Charts file not found: $CHARTS_FILE"
}

# ---------- Verify the current Kubernetes context & Verify EKS connectivity ---------- #
CheckCluster(){
    log "Checking Kubernetes context"
    local context
    context=$(kubectl config current-context 2>/dev/null || true)

    [[ -n "$context" ]] || error "No kubectl context is configured"

    echo "Context: $context"

    log "Checking cluster connectivity"

    kubectl cluster-info >/dev/null 2>&1 || error "Cannot connect to Kubernetes cluster"
}


# ---------- Add/update Helm repositories ---------- #

SetupHelmRepositories() {

    log "Configuring Helm repositories"

    local repositories
    repositories="$(yq -r '
        to_entries[]
        | .value.repo
        | "\(.name)|\(.url)"
    ' "$CHARTS_FILE" | sort -u)"

    while IFS='|' read -r name url; do

        [[ -n "$name" ]] || continue

        helm repo add "$name" "$url" --force-update

    done <<< "$repositories"

    helm repo update
}

# ---------- Install / upgrade Helm chart ---------- #

InstallChart() {

    local component="$1"

    local chart
    local release
    local namespace
    local version
    local values
    local create_namespace

    chart="$(ChartValue "$component" "chart")"
    release="$(ChartValue "$component" "release")"
    namespace="$(ChartValue "$component" "namespace")"
    version="$(ChartValue "$component" "version")"
    values="$(ChartValue "$component" "values")"
    create_namespace="$(ChartValue "$component" "createNamespace")"

    values="${SCRIPT_DIR}/${values}"

    [[ -f "$values" ]]   || error "Values file not found: $values"

    log "Installing ${component}"

    echo "Chart:      $chart"
    echo "Release:    $release"
    echo "Namespace:  $namespace"
    echo "Version:    $version"
    echo "Values:     $values"

    local args=(
        upgrade
        --install
        "$release"
        "$chart"
        --namespace "$namespace"
        --version "$version"
        --values "$values"
        --wait
    )

    if [[ "$create_namespace" == "true" ]]; then
        args+=(--create-namespace)
    fi

    helm "${args[@]}"
}

# ---------- Wait for workloads ---------- #

WaitForComponent() {

    local component="$1"

    log "Waiting for ${component}"

    local count
    count="$(yq ".\"${component}\".wait | length" "$CHARTS_FILE")"

    for ((i = 0; i < count; i++)); do

        local kind
        local name
        local namespace

        kind="$(yq -r ".\"${component}\".wait[$i].kind" "$CHARTS_FILE")"
        name="$(yq -r ".\"${component}\".wait[$i].name" "$CHARTS_FILE")"
        namespace="$(yq -r ".\"${component}\".wait[$i].namespace" "$CHARTS_FILE")"

        kubectl rollout status \
            "${kind}/${name}" \
            --namespace "$namespace" \
            --timeout=10m \
            || error "${component}: ${kind}/${name} did not become ready"

    done

    log "${component} is ready"
}

# ---------- Deploy component ---------- #

DeployComponent() {

    local component="$1"

    InstallChart "$component"
    WaitForComponent "$component"
}

# ---------- Main ---------- #

main() {

    CheckPrerequisites
    CheckCluster
    SetupHelmRepositories

    case "$ARG" in

        cilium)
            DeployComponent cilium
            ;;

        argocd)
            DeployComponent argocd
            ;;

        all)
            DeployComponent cilium
            DeployComponent argocd
            ;;

        *)
            cat <<EOF

Usage:
    $0 [component]

Components:
    cilium
    argocd
    all

Examples:
    $0 cilium
    $0 argocd
    $0 all

EOF
            exit 1
            ;;
    esac

    log "Bootstrap completed successfully"
}

main "$@"