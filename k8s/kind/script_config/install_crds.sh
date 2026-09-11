#!/usr/bin/env bash

ADDHELMREPO(){
    CONFIG_FILE=$1
    set -euo pipefail

    echo "Adding Helm repositories..."

    for component in $(yq 'keys | .[]' "$CONFIG_FILE"); do
        REPO_NAME=$(yq -r ".\"$component\".name" "$CONFIG_FILE")
        REPO_URL=$(yq -r ".\"$component\".url" "$CONFIG_FILE")

        if ! helm repo list | awk '{print $1}' | grep -qx "$REPO_NAME"; then
            echo "Adding repo: $REPO_NAME"
            helm repo add "$REPO_NAME" "$REPO_URL"
        fi
    done

    helm repo update
}

INSTALLHELMCHARTS() {
    CONFIG_FILE=$1
    set -euo pipefail

    echo "Installing charts..."
    for component in $(yq 'keys | .[]' "$CONFIG_FILE"); do

        RELEASE=$(yq -r ".\"$component\".release" "$CONFIG_FILE")
        CHART=$(yq -r ".\"$component\".chart" "$CONFIG_FILE")
        NAMESPACE=$(yq -r ".\"$component\".namespace" "$CONFIG_FILE")
        VALUES_FILE=$(yq -r ".\"$component\".valuesFile // \"\"" "$CONFIG_FILE")

        echo ""
        echo "Installing $component"

        CMD="helm upgrade --install $RELEASE $CHART"

        CMD="$CMD --namespace $NAMESPACE"

        if [[ -n "$VALUES_FILE" ]]; then
            CMD="$CMD -f $VALUES_FILE"
        fi

        CMD="$CMD --create-namespace"

        echo "$CMD"
        eval "$CMD"

    done

    echo ""
    echo "All charts installed successfully."

}