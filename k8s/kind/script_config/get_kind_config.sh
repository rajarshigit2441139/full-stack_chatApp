#!/usr/bin/env bash

# Provide Kind config file path when calling
# Global Variable

KIND_FILE=$1

# Get Cluster Name
GetClusterName() {
    awk -F ': *' '/^name:/ {print $2}' "$KIND_FILE"
}
# Get Networking from Kind File
GetNetworking() {
    awk '
        /^networking:/ {in_net=1}
        in_net && /^[a-zA-Z]/ && !/^networking:/ {exit}
        in_net {print}
    ' "$KIND_FILE"
}

# Get Total number of node
GetNodeNumbers() {
    grep -c "role: worker" "$KIND_FILE"
}

#=== GET TAINTS ===#

GetLabelsTaints() {
    
    NODE_LABELS=()
    NODE_TAINTS=()

    idx=0

    while IFS= read -r line || [[ -n $line ]]; do

        if [[ $line =~ register-with-taints: ]]; then
            taints=$(echo "$line" | grep -o '"[^"]*"' | tr -d '"' | paste -sd' ' -)
        fi

        if [[ $line =~ node-labels: ]]; then
            labels=$(echo "$line" | grep -o '"[^"]*"' | tr -d '"' | paste -sd' ' -)

            NODE_LABELS[$idx]="$labels"
            NODE_TAINTS[$idx]="$taints"

            ((idx++))
        fi

    done < "$KIND_FILE"

    for ((i=0; i<${#NODE_LABELS[@]}; i++)); do
        echo "Worker Node $i"

        echo "Labels:"
        for label in ${NODE_LABELS[$i]}; do
            echo "  $label"
        done

        echo "Taints:"
        for taint in ${NODE_TAINTS[$i]}; do
            echo "  $taint"
        done

        echo
    done
}

GetPortBinding (){
    declare -A PORTS

    while IFS= read -r line || [[ -n $line ]]; do

        if [[ $line =~ containerPort:[[:space:]]*([0-9]+) ]]; then
            containerPort="${BASH_REMATCH[1]}"
        fi

        if [[ $line =~ hostPort:[[:space:]]*([0-9]+) ]]; then
            hostPort="${BASH_REMATCH[1]}"

            PORTS["$containerPort"]="$hostPort" ### NEED TO EXPLAIN
        fi

    done < "$KIND_FILE"

    for containerPort in "${!PORTS[@]}"; do
        echo "Container Port: $containerPort -> Host Port: ${PORTS[$containerPort]}"
    done

}