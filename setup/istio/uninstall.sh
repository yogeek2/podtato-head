#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ISTIO_VERSION="1.8.1"
ISTIO_INSTALL="istio-${ISTIO_VERSION}"

echo "Downloading istioctl..."
[[ ! -d "${ISTIO_INSTALL}" ]] && curl -sSL https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" sh -
cli_version=$(${ISTIO_INSTALL}/bin/istioctl version --remote=false)
echo
echo "istioctl ${cli_version} installed"
echo

echo "--------------------------------------------------------------------------"
echo "You are going to uninstall Istio components on the following cluster :"
kubectl cluster-info | grep master
echo "--------------------------------------------------------------------------"
echo
read -p "Continue (y/n)?" CONT
if [ "$CONT" = "y" ]; then
    kustomize build ${DIR} | kubectl delete -f - --ignore-not-found
    ${ISTIO_INSTALL}/bin/istioctl x uninstall --purge -y
    kubectl delete ns istio-system --ignore-not-found
fi