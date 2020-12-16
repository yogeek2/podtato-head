#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "---------------------------------------------------"
echo "Installing addons (Prometheus, Kiali)..."
echo "---------------------------------------------------"
kustomize build ${DIR} | kubectl apply -f -
echo "done"